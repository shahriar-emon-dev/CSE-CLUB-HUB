-- ============================================================================
-- Migration: 25_fix_rbac_strings_and_recursion.sql
-- Description: Updates core RBAC helper functions to strictly match the new
--              4-Tier string system (Super Admin, Advisor/Admin, Club Executive,
--              Regular Student) and enforces SECURITY DEFINER with specific
--              search paths to prevent infinite recursion in RLS policies.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Redefine get_my_role to be completely recursion-safe
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- ----------------------------------------------------------------------------
-- 2. Update is_admin to use the new 4-Tier string roles
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
      AND role IN ('Advisor/Admin', 'Super Admin')
  );
$$;

-- ----------------------------------------------------------------------------
-- 3. Update is_member to use new roles and prevent nested RLS recursion
-- ----------------------------------------------------------------------------
-- We perform a direct lookup here instead of relying on other helper functions
-- or triggering additional RLS checks to completely avoid Code 42P17.
CREATE OR REPLACE FUNCTION public.is_member()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
      AND role IN ('Regular Student', 'Club Executive', 'Advisor/Admin', 'Super Admin')
      AND is_approved = TRUE
  );
$$;

-- ----------------------------------------------------------------------------
-- 4. Re-verify is_club_executive for safety
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_club_executive(club_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.club_executives
    WHERE club_id = club_uuid
      AND user_id = auth.uid()
  );
$$;
