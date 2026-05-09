-- ==========================================
-- SAFE PROFILE READ RPC
-- ==========================================
-- Why this migration exists:
-- The app should not depend on profiles SELECT RLS during setup because the
-- live database may still have recursive policies. This RPC reads the current
-- user's profile with SECURITY DEFINER privileges and returns the row directly.

create or replace function public.get_my_profile()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_row public.profiles;
begin
  if auth.uid() is null then
    return null;
  end if;

  select *
  into profile_row
  from public.profiles
  where id = auth.uid();

  return profile_row;
end;
$$;

revoke all on function public.get_my_profile() from public;
grant execute on function public.get_my_profile() to authenticated;
