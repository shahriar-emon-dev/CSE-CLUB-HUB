-- ============================================================================
-- Migration: 26_rls_reset_and_3_tier_alignment.sql
-- Description: Resets recursive loops on profiles and sets clean policies
-- ============================================================================

-- 1. Clear out all problematic recursive or outdated policies completely
DROP POLICY IF EXISTS "Super Admin total write enforcement override" ON public.profiles;
DROP POLICY IF EXISTS "Super Admins possess universal mutation capability" ON public.profiles;
DROP POLICY IF EXISTS "Admins and Advisors can read full user directory listings" ON public.profiles;
DROP POLICY IF EXISTS "Allow public read access to basic profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own individual profile row" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for users based on device uid match" ON public.profiles;
DROP POLICY IF EXISTS "Enable full access for system super admins" ON public.profiles;

-- 2. Implement a non-recursive public read policy for authenticated users
CREATE POLICY "Enable authenticated read access to profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- 3. Implement a clean self-update policy restricted strictly by auth UID matching
CREATE POLICY "Enable self update for matching user row" 
ON public.profiles 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Enable administrative mutation capabilities checking the target row fields directly
CREATE POLICY "Enable write operations for administrative profiles"
ON public.profiles
FOR ALL
TO authenticated
USING (role = 'Super Admin');
