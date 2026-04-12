-- ==========================================
-- PROFILES RLS RECURSION FIX
-- ==========================================
-- Why this migration exists:
-- Previous policies queried public.profiles inside public.profiles policy checks,
-- which can trigger PostgreSQL error 42P17 (infinite recursion detected in policy).
-- This migration replaces recursive checks with a SECURITY DEFINER helper.

-- ==========================================
-- ADMIN HELPER FUNCTION (NON-RECURSIVE)
-- ==========================================
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

-- ==========================================
-- DROP RECURSIVE/LEGACY POLICIES
-- ==========================================
drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Admins can read all profiles" on public.profiles;
drop policy if exists "Admins can update role" on public.profiles;
drop policy if exists "Admins can update profiles" on public.profiles;

-- ==========================================
-- RECREATE SAFE POLICIES
-- ==========================================
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "Admins can read all profiles"
on public.profiles
for select
to authenticated
using (public.is_admin(auth.uid()));

create policy "Users can update own profile"
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
with check (role in ('student', 'executive', 'admin'));

-- ==========================================
-- TRIGGER GUARD FOR ROLE SAFETY
-- ==========================================
-- Why this trigger exists:
-- A plain "users can update own profile" policy would allow users to change role/role_request.
-- This trigger prevents non-admin users from mutating privileged fields.
create or replace function public.guard_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Self updates are allowed, but role fields are admin-only.
  if auth.uid() = old.id then
    if new.role is distinct from old.role
       or new.role_request is distinct from old.role_request then
      raise exception 'Only admins can update role fields.' using errcode = '42501';
    end if;
    return new;
  end if;

  -- Non-self updates require admin privileges.
  if not public.is_admin(auth.uid()) then
    raise exception 'Only admins can update other user profiles.' using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_profile_privileged_fields on public.profiles;

create trigger trg_guard_profile_privileged_fields
before update on public.profiles
for each row
execute function public.guard_profile_privileged_fields();
