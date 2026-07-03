-- Create a Security Definer function to safely check auth roles.
-- Since this function runs with elevated privileges (SECURITY DEFINER), 
-- it completely bypasses the Row Level Security policies on public.profiles.
-- This prevents the infinite recursion (Code 42P17) when evaluating policies.
CREATE OR REPLACE FUNCTION public.get_auth_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- Drop the old recursive policies
DROP POLICY IF EXISTS "Super Admins possess universal mutation capability" ON public.profiles;
DROP POLICY IF EXISTS "Admins and Advisors can read full user directory listings" ON public.profiles;

-- Recreate the policies using the new non-recursive function
CREATE POLICY "Super Admins possess universal mutation capability"
ON public.profiles FOR ALL TO authenticated
USING ( public.get_auth_user_role() = 'Super Admin' );

CREATE POLICY "Admins and Advisors can read full user directory listings"
ON public.profiles FOR SELECT TO authenticated
USING ( public.get_auth_user_role() IN ('Super Admin', 'Advisor/Admin') );
