-- ==========================================
-- FIX #5: EXECUTIVE-ONLY POST CREATION POLICY
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

create or replace function public.can_insert_post_for_club(
  target_user_id uuid,
  target_club_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
stable
as $$
begin
  if public.is_admin(target_user_id) then
    return true;
  end if;

  if not public.is_executive_or_admin(target_user_id) then
    return false;
  end if;

  if to_regclass('public.club_executives') is null then
    return true;
  end if;

  return exists (
    select 1
    from public.club_executives ce
    where ce.user_id = target_user_id
      and ce.club_id = target_club_id
      and coalesce(ce.is_active, true) = true
  );
end;
$$;

revoke all on function public.can_insert_post_for_club(uuid, uuid) from public;
grant execute on function public.can_insert_post_for_club(uuid, uuid) to authenticated;

alter table public.posts enable row level security;

drop policy if exists "Authors or admins can insert posts" on public.posts;
drop policy if exists "Executives or admins can insert posts" on public.posts;
drop policy if exists "Authenticated users can insert posts" on public.posts;

create policy "Executives and admins can insert posts"
on public.posts
for insert
to authenticated
with check (
  author_id = auth.uid()
  and public.can_insert_post_for_club(auth.uid(), club_id)
);
