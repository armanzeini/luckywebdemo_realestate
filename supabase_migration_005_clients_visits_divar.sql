-- Lucky Web — clients, Jalali-facing visits, property status & Divar connection state
-- Run once AFTER migration 004.
create extension if not exists pgcrypto;

create table if not exists public.lw_clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  budget text,
  requirements text,
  status text not null default 'active' check (status in ('active','inactive','converted','lost')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.lw_visits add column if not exists client_id uuid references public.lw_clients(id) on delete set null;
alter table public.lw_demo_properties add column if not exists client_id uuid references public.lw_clients(id) on delete set null;

-- Normalize old/demo status values without touching ownership/data.
update public.lw_demo_properties set status='active' where status is null or status not in ('active','negotiation','sold');

do $$
begin
  alter table public.lw_demo_properties drop constraint if exists lw_demo_properties_status_check;
  alter table public.lw_demo_properties add constraint lw_demo_properties_status_check check (status in ('active','negotiation','sold'));
exception when duplicate_object then null;
end $$;

-- A property in negotiation must point to a real client.
create or replace function public.lw_validate_property_negotiation()
returns trigger language plpgsql as $$
begin
  if new.status='negotiation' and new.client_id is null then
    raise exception 'A property in negotiation must have a client_id';
  end if;
  return new;
end; $$;

drop trigger if exists lw_property_negotiation on public.lw_demo_properties;
create trigger lw_property_negotiation before insert or update on public.lw_demo_properties for each row execute function public.lw_validate_property_negotiation();

create index if not exists lw_clients_user_idx on public.lw_clients(user_id,created_at desc);
create index if not exists lw_visits_client_idx on public.lw_visits(user_id,client_id,scheduled_at desc);
create index if not exists lw_properties_client_idx on public.lw_demo_properties(user_id,client_id,status);

alter table public.lw_clients enable row level security;
drop policy if exists "clients own rows" on public.lw_clients;
create policy "clients own rows" on public.lw_clients for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

drop trigger if exists lw_clients_updated_at on public.lw_clients;
create trigger lw_clients_updated_at before update on public.lw_clients for each row execute function public.lw_set_updated_at();

grant select, insert, update, delete on public.lw_clients to authenticated;

-- Optional connection state for a future approved Divar/API integration.
create table if not exists public.lw_divar_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'disconnected' check (status in ('disconnected','pending','connected','error')),
  external_account text,
  last_sync_at timestamptz,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

alter table public.lw_divar_connections enable row level security;
drop policy if exists "divar connection own rows" on public.lw_divar_connections;
create policy "divar connection own rows" on public.lw_divar_connections for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
drop trigger if exists lw_divar_updated_at on public.lw_divar_connections;
create trigger lw_divar_updated_at before update on public.lw_divar_connections for each row execute function public.lw_set_updated_at();
grant select, insert, update, delete on public.lw_divar_connections to authenticated;

comment on table public.lw_divar_connections is 'Connection state only; real Divar automation requires an approved/API-supported integration and credentials.';
comment on column public.lw_visits.scheduled_at is 'Stored as UTC/timestamptz; UI accepts and displays Jalali/Persian dates.';

create or replace view public.lw_dashboard_kpis with (security_invoker=true) as select u.id as user_id, (select count(*) from public.lw_demo_properties p where p.user_id=u.id and p.status='active') as active_properties, (select count(*) from public.lw_visits v where v.user_id=u.id and v.scheduled_at>=now() and v.status in ('scheduled','confirmed')) as upcoming_visits, (select count(*) from public.lw_leads l where l.user_id=u.id and l.status not in ('won','lost')) as active_leads, (select count(*) from public.lw_deals d where d.user_id=u.id and d.status='won') as closed_deals, coalesce((select sum(d.amount) from public.lw_deals d where d.user_id=u.id and d.status='open'),0) as pipeline_value, round(coalesce((select count(*)::numeric from public.lw_deals d where d.user_id=u.id and d.status='won') / nullif((select count(*)::numeric from public.lw_leads l where l.user_id=u.id),0) * 100,0),1) as conversion_rate, (select count(*) from public.lw_content_posts c where c.user_id=u.id and c.status='published' and c.published_at>=date_trunc('month',now())) as published_content_this_month from auth.users u where u.id=auth.uid();
