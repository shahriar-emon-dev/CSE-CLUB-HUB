-- ============================================================================
-- Migration: 24_admin_club_management.sql
-- Description: Creates club-logos storage bucket and atomic RPC functions
--              for executive role assignments and revocations.
-- ============================================================================

-- 1. Create the club-logos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('club-logos', 'club-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for club-logos bucket
-- Allow public read access
CREATE POLICY "Public Access Club Logos" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'club-logos');

-- Allow authenticated users to upload/update/delete
CREATE POLICY "Authenticated users can upload club logos" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'club-logos' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update club logos" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'club-logos' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete club logos" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'club-logos' AND auth.role() = 'authenticated');

-- 2. Atomic RPC for Assigning an Executive Role
CREATE OR REPLACE FUNCTION public.assign_executive_role(
    p_user_id UUID, 
    p_club_id UUID, 
    p_role_title TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Only super_admins or admins should theoretically call this, 
    -- but RLS covers the profiles table update. We can add a check here to be safe.
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only administrators can assign executive roles';
    END IF;

    -- Update the user's role to 'executive'
    UPDATE public.profiles
    SET role = 'executive',
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Insert or update the club_executives record
    INSERT INTO public.club_executives (club_id, user_id, role_title, created_at)
    VALUES (p_club_id, p_user_id, p_role_title, NOW())
    ON CONFLICT (club_id, user_id) 
    DO UPDATE SET role_title = EXCLUDED.role_title;

    -- Add an audit log entry
    INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, metadata, created_at)
    VALUES (
        auth.uid(), 
        'assign_executive', 
        'profile', 
        p_user_id, 
        jsonb_build_object('club_id', p_club_id, 'role_title', p_role_title), 
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Atomic RPC for Revoking an Executive Role
CREATE OR REPLACE FUNCTION public.revoke_executive_role(
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only administrators can revoke executive roles';
    END IF;

    -- Update the user's role to 'member'
    UPDATE public.profiles
    SET role = 'member',
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Delete from club_executives
    DELETE FROM public.club_executives
    WHERE user_id = p_user_id;

    -- Add an audit log entry
    INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, created_at)
    VALUES (
        auth.uid(), 
        'revoke_executive', 
        'profile', 
        p_user_id, 
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
