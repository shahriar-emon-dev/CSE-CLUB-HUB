-- ==========================================
-- FIX: ROLE HELPER DEPENDENCY ORDER
-- ==========================================
-- Why this migration exists:
-- Some migrations reference public.is_executive_or_admin(auth.uid())
-- before the helper function has been created.
-- This idempotent migration guarantees helper availability.

-- ==========================================
-- SECTION 1: ADMIN HELPER
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
-- SECTION 2: EXECUTIVE OR ADMIN HELPER
-- ==========================================

create or replace function public.is_executive_or_admin(target_user_id uuid default auth.uid())
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
      and p.role in ('executive', 'admin')
  );
$$;

revoke all on function public.is_executive_or_admin(uuid) from public;
grant execute on function public.is_executive_or_admin(uuid) to authenticated;
