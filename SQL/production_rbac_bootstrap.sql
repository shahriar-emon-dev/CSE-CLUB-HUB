-- ==============================================================================
-- 🛠️ PRODUCTION FIX: Auto-Bootstrap Super Admin 
-- ==============================================================================
-- This script safely updates your production database trigger.
-- It applies the "First User Wins" logic for RBAC bootstrapping.
-- The VERY FIRST account to ever register in the production system 
-- automatically becomes the 'Super Admin'. All subsequent users default 
-- to 'Regular Student' until manually promoted by the Super Admin.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  is_first_user BOOLEAN;
  assigned_role TEXT;
BEGIN
  -- Check if this is the very first user in the profiles table
  SELECT NOT EXISTS (SELECT 1 FROM public.profiles LIMIT 1) INTO is_first_user;

  IF is_first_user THEN
    assigned_role := 'Super Admin';
  ELSE
    assigned_role := 'Regular Student';
  END IF;

  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    assigned_role
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
