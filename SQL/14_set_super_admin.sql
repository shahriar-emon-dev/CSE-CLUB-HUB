-- ============================================================================
-- Migration: 14_set_super_admin.sql
-- Description: Sets the designated user as a super_admin to grant them
--              the necessary privileges to publish events and bypass RLS.
-- ============================================================================

UPDATE public.profiles
SET 
  role = 'super_admin',
  is_approved = true,
  status = 'active'
WHERE email = 'shad.123@smuct.ac.bd';
