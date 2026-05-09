-- ==========================================
-- FIX PROFILES ADMIN HELPER RECURSION
-- ==========================================
-- Why this migration exists:
-- The previous public.is_admin() helper queried public.profiles, which can
-- recurse when a profiles policy also calls public.is_admin(). This version
-- reads admin state from auth.users metadata instead, so profile policies
-- can evaluate without touching public.profiles again.

create or replace function public.is_admin(target_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public, auth
stable
as $$
  select exists (
    select 1
    from auth.users u
    where u.id = target_user_id
      and coalesce(u.raw_app_meta_data ->> 'role', '') = 'admin'
  );
$$;

revoke all on function public.is_admin(uuid) from public;
grant execute on function public.is_admin(uuid) to authenticated;
