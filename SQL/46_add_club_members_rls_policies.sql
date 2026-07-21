-- ============================================================================
-- Migration: 46_add_club_members_rls_policies.sql
-- Description: club_members has ENABLE ROW LEVEL SECURITY (set in
--              44_complete_production_database_ecosystem.sql, Section 5) but
--              no CREATE POLICY was ever added for it anywhere in this SQL
--              folder — confirmed by grepping every file. With RLS enabled
--              and zero permissive policies, the table is completely
--              inaccessible to the anon/authenticated roles the Flutter app
--              uses (SELECT returns empty, INSERT/UPDATE/DELETE are denied),
--              regardless of who's asking.
--
-- This hasn't broken any live feature yet because no Dart code currently
-- queries club_members directly (the app uses club_followers for following
-- and club_executives for exec roles instead). But club_members' schema
-- (status IN ('pending','approved','rejected','banned')) is clearly the
-- intended backing table for a real member-approval workflow — this
-- migration makes it actually usable for that, following the same
-- self-row / club-executive / super-admin pattern already established for
-- every other table in Section 5 of 44_.
--
-- Purely additive: only adds policies, touches no data, no constraints.
-- Safe to run whether or not any club_members rows exist yet.
-- ============================================================================

BEGIN;

ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;

-- A user can see their own membership row in any club.
DROP POLICY IF EXISTS "club_members_self_select" ON public.club_members;
CREATE POLICY "club_members_self_select" ON public.club_members
FOR SELECT USING (user_id = auth.uid());

-- Executives of a club (and super admins) can see every membership row for
-- that club — needed to review/approve join requests.
DROP POLICY IF EXISTS "club_members_exec_select" ON public.club_members;
CREATE POLICY "club_members_exec_select" ON public.club_members
FOR SELECT USING (public.is_club_executive(club_id) OR public.is_super_admin());

-- Any authenticated user can request to join a club (their own row only,
-- starting at whatever default status the table applies).
DROP POLICY IF EXISTS "club_members_self_insert" ON public.club_members;
CREATE POLICY "club_members_self_insert" ON public.club_members
FOR INSERT WITH CHECK (user_id = auth.uid());

-- Only that club's executives (or a super admin) can change a membership's
-- status — i.e. approve/reject/ban. Members cannot self-approve.
DROP POLICY IF EXISTS "club_members_exec_update" ON public.club_members;
CREATE POLICY "club_members_exec_update" ON public.club_members
FOR UPDATE USING (public.is_club_executive(club_id) OR public.is_super_admin());

-- A user can remove their own membership (leave the club); executives or a
-- super admin can remove any member of a club they run.
DROP POLICY IF EXISTS "club_members_delete" ON public.club_members;
CREATE POLICY "club_members_delete" ON public.club_members
FOR DELETE USING (user_id = auth.uid() OR public.is_club_executive(club_id) OR public.is_super_admin());

COMMIT;
