-- ============================================================================
-- Migration: 15_add_executive_role.sql
-- Description: Adds 'executive' as a recognized role alongside 'admin' and 
--              'super_admin', granting them privileges to create events, 
--              posts, and manage club content.
-- ============================================================================

-- 1. Dynamically drop the existing role check constraint on the profiles table
DO $$ 
DECLARE 
  const_name TEXT;
BEGIN
  SELECT conname INTO const_name
  FROM pg_constraint 
  WHERE conrelid = 'public.profiles'::regclass 
    AND pg_get_constraintdef(oid) LIKE '%role%';
    
  IF const_name IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.profiles DROP CONSTRAINT ' || const_name;
  END IF;
END $$;

-- 2. Add the new check constraint including 'executive'
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('super_admin', 'admin', 'executive', 'member', 'pending', 'banned', 'alumni'));

-- 3. Update the is_admin() helper function so executives get administrative capabilities
--    This automatically grants 'executive' the ability to insert/update events, notices, etc.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT get_my_role() IN ('executive', 'admin', 'super_admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 4. Set the current user as an executive or super_admin as requested
UPDATE public.profiles
SET 
  role = 'super_admin',
  is_approved = true,
  status = 'active'
WHERE email = 'shad.123@smuct.ac.bd';
