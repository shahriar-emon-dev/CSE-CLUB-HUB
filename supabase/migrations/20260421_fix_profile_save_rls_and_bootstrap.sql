-- ==========================================
-- FIX PROFILE SAVE: RLS INSERT/UPDATE + PROFILE BOOTSTRAP
-- ==========================================
-- Why this migration exists:
-- 1) Some users can read profiles but fail to save because their row does not exist.
-- 2) Upsert/insert can fail under RLS without an explicit self-insert policy.
-- 3) We keep previous migrations intact and only add safe, idempotent fixes.

alter table public.profiles enable row level security;

-- Ensure helper exists for policy compatibility.
create or replace function public.is_admin(target_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = target_user_id
      and p.role = 'admin'
  );
$$;

revoke all on function public.is_admin(uuid) from public;
grant execute on function public.is_admin(uuid) to authenticated;

-- Keep auto-profile creation healthy for new auth users.
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

-- Backfill missing profile rows for existing users.
insert into public.profiles (id, email, role, role_request)
select
  u.id,
  coalesce(u.email, ''),
  'student',
  false
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- Normalize key profile defaults used by app save flow.
alter table public.profiles
  alter column role_request set default false,
  alter column role set default 'student';

update public.profiles
set role_request = false
where role_request is null;

update public.profiles
set role = 'student'
where role is null;

-- Replace policy set with explicit self insert + self update + admin update.
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can create own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can update own profile safe" on public.profiles;
drop policy if exists "Admins can update profiles" on public.profiles;

create policy "Users can insert own profile"
on public.profiles
for insert
to authenticated
with check (
  auth.uid() = id
  and coalesce(role, 'student') = 'student'
  and coalesce(role_request, false) = false
);

create policy "Users can update own profile safe"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Admins can update profiles"
on public.profiles
for update
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));
