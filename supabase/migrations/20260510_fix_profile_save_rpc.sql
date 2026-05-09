-- ==========================================
-- SAFE PROFILE SAVE RPC
-- ==========================================
-- Why this migration exists:
-- The client was writing directly to public.profiles and could still hit
-- recursive RLS evaluation through existing helper policies.
-- This RPC performs the profile save with SECURITY DEFINER privileges so
-- the app can deterministically create or update the current user's row.

create or replace function public.save_my_profile(
  full_name text,
  student_id text,
  batch text,
  section text,
  department text default null,
  bio text default null,
  avatar_url text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_row public.profiles;
  current_email text;
begin
  if auth.uid() is null then
    raise exception 'No active session found.' using errcode = '28000';
  end if;

  select coalesce(u.email, '')
  into current_email
  from auth.users u
  where u.id = auth.uid();

  insert into public.profiles (
    id,
    email,
    full_name,
    student_id,
    batch,
    section,
    department,
    bio,
    avatar_url,
    role,
    role_request
  )
  values (
    auth.uid(),
    coalesce(current_email, ''),
    nullif(trim(full_name), ''),
    nullif(trim(student_id), ''),
    nullif(trim(batch), ''),
    nullif(trim(section), ''),
    coalesce(nullif(trim(department), ''), 'CSE'),
    nullif(trim(bio), ''),
    nullif(trim(avatar_url), ''),
    'student',
    false
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        student_id = excluded.student_id,
        batch = excluded.batch,
        section = excluded.section,
        department = excluded.department,
        bio = excluded.bio,
        avatar_url = excluded.avatar_url
  returning * into profile_row;

  return profile_row;
end;
$$;

revoke all on function public.save_my_profile(text, text, text, text, text, text, text) from public;
grant execute on function public.save_my_profile(text, text, text, text, text, text, text) to authenticated;