-- ============================================================================
-- Migration: 03_rbac_fixes.sql
-- Description: Audit and fix role-based access control. Replaces raw 
--              subqueries with SECURITY DEFINER functions to prevent recursion
--              and wires up the 'executive' role correctly across the board.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Helper Functions (SECURITY DEFINER)
-- ----------------------------------------------------------------------------

-- Ensure is_member recognizes the 'executive' role
CREATE OR REPLACE FUNCTION public.is_member()
RETURNS BOOLEAN AS $$
  SELECT get_my_role() IN ('member', 'admin', 'super_admin', 'executive')
    AND (SELECT is_approved FROM public.profiles WHERE id = auth.uid()) = TRUE;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Add helper to securely check if the current user is an executive of a specific club
CREATE OR REPLACE FUNCTION public.is_club_executive(club_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.club_executives
    WHERE club_id = club_uuid
      AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- 2. Drop Previously Defined Subquery Policies
-- ----------------------------------------------------------------------------
-- From clubs
DROP POLICY IF EXISTS "Executives can update their club profile" ON public.clubs;
-- From club_executives
DROP POLICY IF EXISTS "Admins can manage executives" ON public.club_executives;
-- From events
DROP POLICY IF EXISTS "Executives can insert events for their club" ON public.events;
DROP POLICY IF EXISTS "Executives can update their club events" ON public.events;
DROP POLICY IF EXISTS "Executives can delete their club events" ON public.events;

-- ----------------------------------------------------------------------------
-- 3. Recreate Policies Using SECURITY DEFINER Functions
-- ----------------------------------------------------------------------------

-- CLUBS: Admin OR Club Executive can update
DROP POLICY IF EXISTS "Executives and Admins can update their club profile" ON public.clubs;
CREATE POLICY "Executives and Admins can update their club profile" ON public.clubs FOR UPDATE
USING (
  is_admin() OR is_club_executive(id)
) WITH CHECK (
  is_admin() OR is_club_executive(id)
);

-- CLUB EXECUTIVES: Only Admin can manage executives
DROP POLICY IF EXISTS "Admins can manage executives" ON public.club_executives;
CREATE POLICY "Admins can manage executives" ON public.club_executives FOR ALL
USING (
  is_admin()
) WITH CHECK (
  is_admin()
);

-- EVENTS: Admin OR Club Executive can manage events
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;

CREATE POLICY "events_insert" ON public.events FOR INSERT 
WITH CHECK (
  is_admin() OR is_club_executive(club_id)
);

CREATE POLICY "events_update" ON public.events FOR UPDATE
USING (
  is_admin() OR is_club_executive(club_id)
) WITH CHECK (
  is_admin() OR is_club_executive(club_id)
);

CREATE POLICY "events_delete" ON public.events FOR DELETE
USING (
  is_admin() OR is_club_executive(club_id)
);

-- NOTICES: Admin OR Club Executive can manage notices (assuming similar structure)
-- Dropping existing if any
DROP POLICY IF EXISTS "notices_insert" ON public.notices;
DROP POLICY IF EXISTS "notices_update" ON public.notices;
DROP POLICY IF EXISTS "notices_delete" ON public.notices;

CREATE POLICY "notices_insert" ON public.notices FOR INSERT 
WITH CHECK (
  is_admin() OR is_club_executive(club_id)
);

CREATE POLICY "notices_update" ON public.notices FOR UPDATE
USING (
  is_admin() OR is_club_executive(club_id)
) WITH CHECK (
  is_admin() OR is_club_executive(club_id)
);

CREATE POLICY "notices_delete" ON public.notices FOR DELETE
USING (
  is_admin() OR is_club_executive(club_id)
);

-- BLOGS: Admin OR Club Executive can manage blogs associated with their club
DROP POLICY IF EXISTS "blogs_insert" ON public.blogs;
DROP POLICY IF EXISTS "blogs_update" ON public.blogs;
DROP POLICY IF EXISTS "blogs_delete" ON public.blogs;

CREATE POLICY "blogs_insert" ON public.blogs FOR INSERT 
WITH CHECK (
  is_admin() OR is_club_executive(club_id)
);

CREATE POLICY "blogs_update" ON public.blogs FOR UPDATE
USING (
  is_admin() OR is_club_executive(club_id)
) WITH CHECK (
  is_admin() OR is_club_executive(club_id)
);

CREATE POLICY "blogs_delete" ON public.blogs FOR DELETE
USING (
  is_admin() OR is_club_executive(club_id)
);
