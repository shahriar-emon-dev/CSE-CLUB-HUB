-- ============================================================================
-- Migration: 32_recreate_club_list_view.sql
-- Description: Recreates the club_list_view to include newly added columns 
--              (slug, icon_name, color_hex) which were missing due to SELECT c.* 
--              evaluation at creation time.
-- ============================================================================

-- Drop the view first
DROP VIEW IF EXISTS public.club_list_view;

-- Recreate it to expand c.* with the current columns
CREATE VIEW public.club_list_view AS
SELECT 
    c.*,
    (SELECT count(*) FROM public.club_followers cf WHERE cf.club_id = c.id) +
    (SELECT count(*) FROM public.club_executives ce WHERE ce.club_id = c.id) as member_count
FROM public.clubs c;

-- Restore permissions
GRANT SELECT ON public.club_list_view TO anon, authenticated;

-- Force Supabase's API (PostgREST) to reload the schema cache immediately
NOTIFY pgrst, 'reload schema';
