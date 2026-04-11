-- Week 1 auth + profile system for CSE Club Hub
-- Safe to run in Supabase SQL editor or migration pipeline.

-- 1) Schema -----------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text,
  student_id text,
  batch text,
  section text,
  department text not null default 'CSE',
  avatar_url text,
  role text not null default 'student',
  role_request boolean not null default false,
  created_at timestamptz not null default now(),
  constraint profiles_role_check check (role in ('student', 'executive', 'admin'))
);

-- Ensure critical columns/defaults exist for already-created tables.
alter table public.profiles
  alter column email set not null,
  alter column department set default 'CSE',
  alter column department set not null,
  alter column role set default 'student',
  alter column role set not null,
  alter column role_request set default false,
  alter column role_request set not null,
  alter column created_at set default now(),
  alter column created_at set not null;

-- Backfill null-safe values in existing rows before constraints/checks.
update public.profiles set department = 'CSE' where department is null;
update public.profiles set role = 'student' where role is null;
update public.profiles set role_request = false where role_request is null;
update public.profiles set created_at = now() where created_at is null;

-- Keep role check in sync for older tables.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_check check (role in ('student', 'executive', 'admin'));
  end if;
end $$;

-- 2) Trigger: auto profile creation from auth.users -------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role, role_request)
  values (new.id, coalesce(new.email, ''), 'student', false)
  on conflict (id) do update
    set email = excluded.email;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- 3) RLS --------------------------------------------------------------------
alter table public.profiles enable row level security;

-- Remove old policy versions if rerunning migration.
drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Admins can read all profiles" on public.profiles;
drop policy if exists "Admins can update role" on public.profiles;

-- 3.1 Users can read their own profile
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

-- 3.2 Users can update only their own profile (not role)
create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (
  auth.uid() = id
  and role = (select p.role from public.profiles p where p.id = auth.uid())
  and role_request = (select p.role_request from public.profiles p where p.id = auth.uid())
);

-- 3.3 Admins can read all profiles
create policy "Admins can read all profiles"
on public.profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.profiles admin_profile
    where admin_profile.id = auth.uid()
      and admin_profile.role = 'admin'
  )
);

-- 3.4 Admins can update role
create policy "Admins can update role"
on public.profiles
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles admin_profile
    where admin_profile.id = auth.uid()
      and admin_profile.role = 'admin'
  )
)
with check (
  role in ('student', 'executive', 'admin')
);

-- 4) Indexing ---------------------------------------------------------------
create index if not exists idx_profiles_email on public.profiles (email);
create index if not exists idx_profiles_role on public.profiles (role);



-- 5) Query snippets ----------------------------------------------------------
-- Insert manual fallback profile
-- insert into public.profiles (id, email, role, role_request)
-- values (auth.uid(), 'user@smuct.ac.bd', 'student', false)
-- on conflict (id) do update set email = excluded.email;

-- Select current user profile
-- select * from public.profiles where id = auth.uid();

-- Select all users (admin only by RLS)
-- select * from public.profiles order by created_at desc;

-- Update profile fields (self)
-- update public.profiles
-- set full_name = 'Name', student_id = '2024-123', batch = '58', section = 'A', avatar_url = 'https://...'
-- where id = auth.uid();

-- Update role (admin only by RLS)
-- update public.profiles set role = 'executive' where id = '<target-user-uuid>';

-- Admin review queue: users requesting executive access
-- select id, email, role_request, created_at
-- from public.profiles
-- where role_request = true
-- order by created_at asc;

-- Approve executive request (admin only)
-- update public.profiles
-- set role = 'executive', role_request = false
-- where id = '<target-user-uuid>';

-- Reject executive request (admin only)
-- update public.profiles
-- set role = 'student', role_request = false
-- where id = '<target-user-uuid>';

-- Delete own profile (auth.users deletion cascades automatically)
-- delete from public.profiles where id = auth.uid();
