-- ============================================================================
-- Migration: 09_add_super_admin.sql
-- Description: Adds the initial super admin user (Emon Hossain) to auth.users 
--              and public.profiles so they can log in via the app.
-- ============================================================================

DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
BEGIN
  -- Enable pgcrypto for crypt() function
  CREATE EXTENSION IF NOT EXISTS pgcrypto;

  -- Check if the user already exists in auth.users
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'emon.223071044@smuct.ac.db') THEN
    
    -- 1. Insert into Supabase auth.users
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      new_user_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'emon.223071044@smuct.ac.db',
      crypt('emon.223071044', gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name": "Emon Hossain", "student_id": "223071044"}',
      NOW(),
      NOW()
    );

    -- 2. Insert into public.profiles
    -- Note: If a trigger already inserted a profile when auth.users was inserted, 
    -- this will just update it to ensure the role is 'super_admin' and it is approved.
    INSERT INTO public.profiles (
      id,
      full_name,
      student_id,
      email,
      role,
      status,
      is_approved,
      joined_at,
      updated_at
    ) VALUES (
      new_user_id,
      'Emon Hossain',
      '223071044',
      'emon.223071044@smuct.ac.db',
      'super_admin',
      'active',
      TRUE,
      NOW(),
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET 
      role = 'super_admin',
      is_approved = TRUE,
      status = 'active';

    RAISE NOTICE 'Super admin user created successfully.';
  ELSE
    -- If user exists, just ensure they have super_admin rights
    UPDATE public.profiles 
    SET role = 'super_admin', is_approved = TRUE, status = 'active'
    WHERE email = 'emon.223071044@smuct.ac.db';

    RAISE NOTICE 'Super admin user already exists, updated permissions.';
  END IF;
END $$;
