-- ============================================================================
-- Migration: 11_add_shad_super_admin.sql
-- Description: Adds a new super admin user (Shad) to auth.users, auth.identities, 
--              and public.profiles.
-- ============================================================================

DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
  v_email text := 'shad.123@smuct.ac.bd';
  v_password text := 'shad.123';
  v_name text := 'Shad';
  v_student_id text := '123'; -- Placeholder based on email handle
BEGIN
  -- Enable pgcrypto for crypt() function
  CREATE EXTENSION IF NOT EXISTS pgcrypto;

  -- Check if the user already exists in auth.users
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
    
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
      v_email,
      crypt(v_password, gen_salt('bf')),
      NOW(),
      '{"provider":"email","providers":["email"]}',
      format('{"full_name": "%s", "student_id": "%s"}', v_name, v_student_id)::jsonb,
      NOW(),
      NOW()
    );

    -- 2. Insert into auth.identities (Required for GoTrue to authenticate properly)
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      new_user_id,
      format('{"sub":"%s","email":"%s"}', new_user_id::text, v_email)::jsonb,
      'email',
      v_email,
      NOW(),
      NOW(),
      NOW()
    );

    -- 3. Insert into public.profiles
    -- (ON CONFLICT ensures it plays nicely with the `on_auth_user_created` trigger)
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
      v_name,
      v_student_id,
      v_email,
      'super_admin',
      'active',
      TRUE,
      NOW(),
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET 
      role = 'super_admin',
      is_approved = TRUE,
      status = 'active';

    RAISE NOTICE 'Super admin user % created successfully.', v_email;
  ELSE
    -- If user already exists, upgrade their role to super_admin
    UPDATE public.profiles 
    SET role = 'super_admin', is_approved = TRUE, status = 'active'
    WHERE email = v_email;

    RAISE NOTICE 'Super admin user % already exists, updated permissions.', v_email;
  END IF;
END $$;
