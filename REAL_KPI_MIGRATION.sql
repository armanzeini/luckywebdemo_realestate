-- Lucky Web — real operational data layer + KPI engine
-- Run once AFTER LUCKYWEB_DEMO_SCHEMA.sql and migration 003.
-- No fake/seed customer data is inserted.

create extension if not exists pgcrypto;

create table if not exists public.lw_leads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  source text,
  status text not null default 'new' check (status in ('new','contacted','qualified','negotiation','won','lost')),
  estimated_value numeric(15,2) not null default 0,
  assigned_to uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lw_visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid references public.lw_demo_properties(id) on delete set null,
  lead_id uuid references public.lw_leads(id) on delete set null,
  consultant_id uuid references auth.users(id) on delete set null,
  scheduled_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled','confirmed','completed','cancelled','no_show')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lw_deals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid references public.lw_demo_properties(id) on delete set null,
  lead_id uuid references public.lw_leads(id) on delete set null,
  consultant_id uuid references auth.users(id) on delete set null,
  amount numeric(15,2) not null default 0,
  status text not null default 'open' check (status in ('open','won','lost','cancelled')),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lw_team_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  auth_user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  role text not null default 'consultant',
  active boolean not null default true,
  target_monthly numeric(15,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lw_content_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  channel text,
  status text not null default 'draft' check (status in ('draft','scheduled','published','failed')),
  scheduled_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lw_leads_user_status_idx on public.lw_leads(user_id,status,created_at desc);
create index if not exists lw_visits_user_schedule_idx on public.lw_visits(user_id,scheduled_at desc);
create index if not exists lw_deals_user_status_idx on public.lw_deals(user_id,status,created_at desc);
create index if not exists lw_team_user_active_idx on public.lw_team_members(user_id,active);
create index if not exists lw_content_user_status_idx on public.lw_content_posts(user_id,status,created_at desc);

alter table public.lw_leads enable row level security;
alter table public.lw_visits enable row level security;
alter table public.lw_deals enable row level security;
alter table public.lw_team_members enable row level security;
alter table public.lw_content_posts enable row level security;

drop policy if exists "leads own rows" on public.lw_leads;
create policy "leads own rows" on public.lw_leads for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "visits own rows" on public.lw_visits;
create policy "visits own rows" on public.lw_visits for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "deals own rows" on public.lw_deals;
create policy "deals own rows" on public.lw_deals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "team own rows" on public.lw_team_members;
create policy "team own rows" on public.lw_team_members for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "content own rows" on public.lw_content_posts;
create policy "content own rows" on public.lw_content_posts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Reuse the existing updated_at trigger function.
drop trigger if exists lw_leads_updated_at on public.lw_leads;
create trigger lw_leads_updated_at before update on public.lw_leads for each row execute function public.lw_set_updated_at();
drop trigger if exists lw_visits_updated_at on public.lw_visits;
create trigger lw_visits_updated_at before update on public.lw_visits for each row execute function public.lw_set_updated_at();
drop trigger if exists lw_deals_updated_at on public.lw_deals;
create trigger lw_deals_updated_at before update on public.lw_deals for each row execute function public.lw_set_updated_at();
drop trigger if exists lw_team_updated_at on public.lw_team_members;
create trigger lw_team_updated_at before update on public.lw_team_members for each row execute function public.lw_set_updated_at();
drop trigger if exists lw_content_updated_at on public.lw_content_posts;
create trigger lw_content_updated_at before update on public.lw_content_posts for each row execute function public.lw_set_updated_at();

-- One row per authenticated workspace. The frontend reads this view for the main KPI cards.
create or replace view public.lw_dashboard_kpis
with (security_invoker = true)
as
select
  u.id as user_id,
  (select count(*) from public.lw_demo_properties p where p.user_id=u.id) as active_properties,
  (select count(*) from public.lw_visits v where v.user_id=u.id and v.scheduled_at >= now() and v.status in ('scheduled','confirmed')) as upcoming_visits,
  (select count(*) from public.lw_leads l where l.user_id=u.id and l.status not in ('won','lost')) as active_leads,
  (select count(*) from public.lw_deals d where d.user_id=u.id and d.status='won') as closed_deals,
  coalesce((select sum(d.amount) from public.lw_deals d where d.user_id=u.id and d.status='open'),0) as pipeline_value,
  round(coalesce((select count(*)::numeric from public.lw_deals d where d.user_id=u.id and d.status='won') / nullif((select count(*)::numeric from public.lw_leads l where l.user_id=u.id),0) * 100,0),1) as conversion_rate,
  (select count(*) from public.lw_content_posts c where c.user_id=u.id and c.status='published' and c.published_at >= date_trunc('month',now())) as published_content_this_month
from auth.users u
where u.id = auth.uid();

grant select on public.lw_dashboard_kpis to authenticated;
grant select, insert, update, delete on public.lw_leads to authenticated;
grant select, insert, update, delete on public.lw_visits to authenticated;
grant select, insert, update, delete on public.lw_deals to authenticated;
grant select, insert, update, delete on public.lw_team_members to authenticated;
grant select, insert, update, delete on public.lw_content_posts to authenticated;

comment on view public.lw_dashboard_kpis is 'Real per-workspace KPIs for Lucky Web. No demo/seed data is inserted.';
