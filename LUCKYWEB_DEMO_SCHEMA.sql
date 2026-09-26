-- Lucky Web SaaS Demo — Supabase schema
-- Run this once in Supabase SQL Editor.
-- Auth passwords are handled only by Supabase Auth; this schema never stores passwords.

create extension if not exists pgcrypto;

create table if not exists public.lw_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  preferred_theme text not null default 'dark' check (preferred_theme in ('dark','light')),
  layout_preference text not null default 'classic' check (layout_preference in ('classic','header','compact','minimal','detailed','futuristic')),
  sidebar_preference text not null default 'expanded' check (sidebar_preference in ('expanded','collapsed','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lw_demo_properties (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  area text not null,
  price text not null,
  status text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.lw_demo_activity (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  subtitle text not null,
  relative_time text not null,
  created_at timestamptz not null default now()
);

create index if not exists lw_demo_properties_user_idx on public.lw_demo_properties(user_id, created_at desc);
create index if not exists lw_demo_activity_user_idx on public.lw_demo_activity(user_id, created_at desc);

alter table public.lw_profiles enable row level security;
alter table public.lw_demo_properties enable row level security;
alter table public.lw_demo_activity enable row level security;

drop policy if exists "profile own row" on public.lw_profiles;
create policy "profile own row" on public.lw_profiles for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "properties own rows" on public.lw_demo_properties;
create policy "properties own rows" on public.lw_demo_properties for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "activity own rows" on public.lw_demo_activity;
create policy "activity own rows" on public.lw_demo_activity for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.lw_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists lw_profiles_updated_at on public.lw_profiles;
create trigger lw_profiles_updated_at before update on public.lw_profiles for each row execute function public.lw_set_updated_at();

create or replace function public.lw_bootstrap_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.lw_profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;

  insert into public.lw_demo_properties(user_id,title,area,price,status)
  values
    (new.id,'آپارتمان مدرن — معالی‌آباد','۱۶۵ متر','۱۲.۸ میلیارد','فعال'),
    (new.id,'ویلای نوساز — قصرالدشت','۳۲۰ متر','۲۸ میلیارد','تور ۳۶۰'),
    (new.id,'دفتر اداری — فرهنگ‌شهر','۱۴۰ متر','۹.۶ میلیارد','در مذاکره'),
    (new.id,'پنت‌هاوس — عفیف‌آباد','۲۴۰ متر','۲۲.۵ میلیارد','جدید');

  insert into public.lw_demo_activity(user_id,title,subtitle,relative_time)
  values
    (new.id,'رزرو بازدید جدید','آپارتمان معالی‌آباد','۵ دقیقه قبل'),
    (new.id,'فایل جدید دریافت شد','ویلای قصرالدشت','۲۲ دقیقه قبل'),
    (new.id,'گزارش مذاکره مالک','دفتر فرهنگ‌شهر','۴۳ دقیقه قبل'),
    (new.id,'محتوای جدید آماده شد','کمپین شبکه اجتماعی','۱ ساعت قبل');

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_lw on auth.users;
create trigger on_auth_user_created_lw
after insert on auth.users
for each row execute function public.lw_bootstrap_user();

-- Optional: remove these grants if your project uses a stricter default role setup.
grant select, insert, update, delete on public.lw_profiles to authenticated;
grant select, insert, update, delete on public.lw_demo_properties to authenticated;
grant select, insert, update, delete on public.lw_demo_activity to authenticated;
