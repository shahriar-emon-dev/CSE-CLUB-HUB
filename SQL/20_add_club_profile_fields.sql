-- ============================================================================
-- Migration: 20_add_club_profile_fields.sql
-- Description: Adds categories, meeting_schedule, and location to clubs table.
-- ============================================================================

ALTER TABLE public.clubs
ADD COLUMN IF NOT EXISTS categories TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS meeting_schedule TEXT,
ADD COLUMN IF NOT EXISTS location TEXT;

-- Drop the view first to avoid the 'cannot change name of view column' error
-- caused by expanding c.* with new columns
DROP VIEW IF EXISTS public.club_list_view;

CREATE VIEW public.club_list_view AS
SELECT 
    c.*,
    (SELECT count(*) FROM public.club_followers cf WHERE cf.club_id = c.id) +
    (SELECT count(*) FROM public.club_executives ce WHERE ce.club_id = c.id) as member_count
FROM public.clubs c;

-- Restore permissions
GRANT SELECT ON public.club_list_view TO anon, authenticated;
