-- ============================================================================
-- Migration: 27_assign_final_roles.sql
-- Description: Updates the constraints for legacy role strings and assigns
--              the specific user accounts to their required tiers.
-- ============================================================================

-- Step 1: Drop old strict rules (dropping both known names to prevent conflicts)
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS check_valid_role;

-- Step 2: Add the new rule that includes 'executive' and legacy strings
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_role_check 
CHECK ((role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'executive'::text, 'member'::text, 'pending'::text, 'banned'::text, 'alumni'::text])));

-- Step 3: Assign Nokib as Admin/Super Admin
UPDATE public.profiles 
SET role = 'super_admin', is_approved = true, status = 'active' 
WHERE id = 'c91b0578-ab81-4eb3-8b1b-e1b5d2a03657';

-- Step 4: Assign Emon as Executive
UPDATE public.profiles 
SET role = 'executive', is_approved = true, status = 'active' 
WHERE id = '01cbb268-b936-45c3-ac12-3e57ecfcd093';
