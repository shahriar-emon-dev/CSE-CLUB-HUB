-- ============================================================================
-- Migration: dynamic_feed_sync.sql
-- Description: Creates unified feed view and enables replica identity
-- ============================================================================

-- 1. Enable REPLICA IDENTITY FULL for Realtime on relevant tables
ALTER TABLE public.events REPLICA IDENTITY FULL;
ALTER TABLE public.club_posts REPLICA IDENTITY FULL;
ALTER TABLE public.club_post_reactions REPLICA IDENTITY FULL;
ALTER TABLE public.comments REPLICA IDENTITY FULL;

-- 2. Create Unified Feed View
-- We use a union of club_post_view and event_list_view
DROP VIEW IF EXISTS public.unified_feed_view;

CREATE VIEW public.unified_feed_view AS
SELECT 
    'post' AS item_type,
    cp.id AS id,
    cp.club_id,
    cp.club_name,
    cp.club_logo_url,
    cp.author_id,
    cp.author_name,
    cp.author_avatar_url,
    cp.content AS title,
    cp.image_url AS description, -- Map image_url to description for posts if needed
    cp.is_pinned,
    cp.created_at,
    cp.updated_at,
    cp.comment_count,
    cp.favorite_count,
    cp.fire_count,
    cp.hand_count,
    NULL::TIMESTAMP WITH TIME ZONE AS event_date,
    NULL::TIMESTAMP WITH TIME ZONE AS end_date,
    NULL AS venue,
    NULL AS category,
    NULL::INT AS capacity,
    NULL::BIGINT AS rsvp_count
FROM public.club_post_view cp

UNION ALL

SELECT
    'event' AS item_type,
    e.id AS id,
    NULL AS club_id, -- Events might not be tied to clubs in the same way
    'Event' AS club_name, 
    NULL AS club_logo_url,
    e.created_by AS author_id,
    e.organizer_name AS author_name,
    e.organizer_avatar AS author_avatar_url,
    e.title AS title,
    e.description AS description,
    false AS is_pinned,
    e.created_at,
    e.updated_at,
    0 AS comment_count,
    0 AS favorite_count,
    0 AS fire_count,
    0 AS hand_count,
    e.event_date,
    e.end_date,
    e.venue,
    e.category,
    e.capacity,
    e.rsvp_count
FROM public.event_list_view e
WHERE e.is_published = true;

GRANT SELECT ON public.unified_feed_view TO anon, authenticated;
