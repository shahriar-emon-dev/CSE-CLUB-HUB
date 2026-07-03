-- ============================================================================
-- Migration: 31_add_clubs_admin_policy.sql
-- Description: Grants absolute write permissions (INSERT, UPDATE, DELETE) to 
--              Super Admins for the public.clubs table to prevent 42501 errors.
-- ============================================================================

-- Drop if it already exists to keep it idempotent
DROP POLICY IF EXISTS "Super Admins have full access to clubs" ON public.clubs;

-- Create an absolute policy utilizing a direct subquery against the profiles table
CREATE POLICY "Super Admins have full access to clubs"
ON public.clubs
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'super_admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);
