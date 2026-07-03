-- ============================================================================
-- Migration: 12_fix_club_list_view.sql
-- Description: Ensures the club_list_view exists and forces PostgREST to 
--              reload its schema cache to fix the PGRST205 error.
-- ============================================================================

-- Ensure the view is created in case it was missed earlier
CREATE OR REPLACE VIEW public.club_list_view AS
SELECT 
    c.*,
    (SELECT count(*) FROM public.club_followers cf WHERE cf.club_id = c.id) +
    (SELECT count(*) FROM public.club_executives ce WHERE ce.club_id = c.id) as member_count
FROM public.clubs c;

-- Ensure public access to the view
GRANT SELECT ON public.club_list_view TO anon, authenticated;

-- Force Supabase's API (PostgREST) to reload the schema cache immediately
NOTIFY pgrst, 'reload schema';
