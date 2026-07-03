-- ============================================================================
-- Migration: 33_club_executives_view.sql
-- Description: Creates a view for club_executives joined with profiles
-- ============================================================================

CREATE OR REPLACE VIEW public.club_executives_view AS
SELECT 
    ce.id,
    ce.club_id,
    ce.user_id,
    ce.role_title,
    ce.created_at,
    p.full_name,
    p.avatar_url,
    p.role AS user_role
FROM public.club_executives ce
JOIN public.profiles p ON ce.user_id = p.id;

-- Ensure RLS policies apply to the underlying tables when accessed via view
-- Views bypass RLS by default unless created with security barrier, or accessed 
-- by users who have access to the underlying tables.
-- Here we'll just let the view inherit the access of the underlying tables.
