-- ==========================================
-- POST-AUDIT MIGRATION FIX
-- ==========================================
-- Fixes found during Dart ↔ SQL cross-reference audit:
-- 1) Post insert policy blocks NULL club_id (executives posting without club).
-- 2) club_with_followers view missing GRANT.
-- 3) events insert trigger needs created_by auto-fill.
-- 4) feed_posts_v1 view grant to anon (already done but reinforced).

-- ==========================================
-- FIX 1: ALLOW POSTS WITH NULL club_id
-- ==========================================
-- The current policy calls can_insert_post_for_club(auth.uid(), club_id).
-- When club_id IS NULL, the function returns false and blocks the insert.
-- We need to allow executives/admins to create posts without a club.

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
  -- Admins can post anywhere, including without a club.
  if public.is_admin(target_user_id) then
    return true;
  end if;

  -- Non-executive/non-admin users cannot post at all.
  if not public.is_executive_or_admin(target_user_id) then
    return false;
  end if;

  -- Executives can create posts without a specific club (general posts).
  if target_club_id is null then
    return true;
  end if;

  -- If club_executives table exists, check membership. Otherwise allow.
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

-- ==========================================
-- FIX 2: GRANT SELECT ON club_with_followers VIEW
-- ==========================================
-- clubs_screen.dart queries .from('club_with_followers') but the view
-- was never granted to authenticated users.

grant select on public.club_with_followers to authenticated;

-- ==========================================
-- FIX 3: AUTO-FILL created_by ON EVENT INSERT
-- ==========================================
-- The executive dashboard inserts events without `created_by`.
-- The column is NOT NULL, so the insert fails.
-- This trigger auto-fills created_by with auth.uid() if not provided.

create or replace function public.auto_fill_event_created_by()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.created_by is null then
    new.created_by := auth.uid();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_auto_fill_event_created_by on public.events;

create trigger trg_auto_fill_event_created_by
before insert on public.events
for each row
execute function public.auto_fill_event_created_by();

-- ==========================================
-- FIX 4: ENSURE feed_posts_v1 IS ACCESSIBLE
-- ==========================================
-- Reinforce view access for authenticated and anon roles.

grant select on public.feed_posts_v1 to authenticated, anon;

-- ==========================================
-- FIX 5: ENSURE event_rsvp_counts IS ACCESSIBLE
-- ==========================================
-- Already granted in migration 6, but reinforced here.

grant select on public.event_rsvp_counts to authenticated;

-- ==========================================
-- FIX 6: ENSURE notifications GRANT
-- ==========================================
-- The notifications table has RLS but no explicit grants beyond policy.
-- This ensures the select policies can actually be evaluated.

grant select, update on public.notifications to authenticated;
