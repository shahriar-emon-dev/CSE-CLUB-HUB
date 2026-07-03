-- Drop legacy constraints before updating the data to prevent validation errors
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS check_valid_role;

-- First, safely map all existing legacy roles to the new 4-tier string standard.
UPDATE public.profiles SET role = 'Super Admin' WHERE role = 'super_admin';
UPDATE public.profiles SET role = 'Advisor/Admin' WHERE role = 'admin';
UPDATE public.profiles SET role = 'Club Executive' WHERE role = 'executive';
UPDATE public.profiles SET role = 'Regular Student' WHERE role IN ('member', 'pending', 'banned', 'alumni');
UPDATE public.profiles SET role = 'Regular Student' WHERE role IS NULL OR role NOT IN ('Super Admin', 'Advisor/Admin', 'Club Executive', 'Regular Student');

-- Create custom check constraint type for validation parity
ALTER TABLE public.profiles 
DROP CONSTRAINT IF EXISTS check_valid_role;

ALTER TABLE public.profiles
ADD CONSTRAINT check_valid_role 
CHECK (role IN ('Super Admin', 'Advisor/Admin', 'Club Executive', 'Regular Student'));

-- Ensure clean schema columns for mapping permissions
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS managed_club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL;

-- Enable Realtime replication over database targets
ALTER TABLE public.profiles REPLICA IDENTITY FULL;
-- Note: if `supabase_realtime` publication already contains `public.profiles`, adding it again might error, so we can ignore it or use a safer approach if doing it via script.
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- Row Level Security (RLS) Policy Blocks
DROP POLICY IF EXISTS "Super Admins possess universal mutation capability" ON public.profiles;
CREATE POLICY "Super Admins possess universal mutation capability"
ON public.profiles FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'Super Admin'));

DROP POLICY IF EXISTS "Admins and Advisors can read full user directory listings" ON public.profiles;
CREATE POLICY "Admins and Advisors can read full user directory listings"
ON public.profiles FOR SELECT TO authenticated
USING (role IN ('Super Admin', 'Advisor/Admin'));
