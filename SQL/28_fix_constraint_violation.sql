-- ============================================================================
-- Migration: 28_fix_constraint_violation.sql
-- Description: Standardizes all existing roles to legacy string format before
--              applying the new check constraint to avoid ERROR: 23514.
-- ============================================================================

-- Step 1: Drop old strict rules
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS check_valid_role;

-- Step 2: Convert any existing 4-Tier string formats back to the legacy string format
-- so that they do not violate the new constraint.
UPDATE public.profiles SET role = 'super_admin' WHERE role = 'Super Admin';
UPDATE public.profiles SET role = 'admin'       WHERE role = 'Advisor/Admin';
UPDATE public.profiles SET role = 'executive'   WHERE role = 'Club Executive';
UPDATE public.profiles SET role = 'member'      WHERE role = 'Regular Student';

-- Step 3: Now it is safe to add the new rule
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_role_check 
CHECK ((role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'executive'::text, 'member'::text, 'pending'::text, 'banned'::text, 'alumni'::text])));

-- Step 4: Assign Nokib as Super Admin
UPDATE public.profiles 
SET role = 'super_admin', is_approved = true, status = 'active' 
WHERE id = 'c91b0578-ab81-4eb3-8b1b-e1b5d2a03657';

-- Step 5: Assign Emon as Executive
UPDATE public.profiles 
SET role = 'executive', is_approved = true, status = 'active' 
WHERE id = '01cbb268-b936-45c3-ac12-3e57ecfcd093';
