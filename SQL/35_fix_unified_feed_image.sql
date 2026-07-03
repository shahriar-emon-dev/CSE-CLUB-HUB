-- ============================================================================
-- Migration: 35_fix_unified_feed_image.sql
-- Description: Fixes the unified_feed_timeline view so image_url maps to media_asset_url
-- ============================================================================

DROP VIEW IF EXISTS public.unified_feed_timeline;

CREATE VIEW public.unified_feed_timeline AS
SELECT 
    'post' AS item_type,
    cp.id AS id,
    cp.club_id,
    cp.club_name,
    cp.club_logo_url,
    cp.author_id,
    cp.author_name,
    cp.author_avatar_url,
    NULL AS title,
    cp.content AS description,
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
    NULL::BIGINT AS rsvp_count,
    cp.image_url AS media_asset_url
FROM public.club_post_view cp

UNION ALL

SELECT
    'event' AS item_type,
    e.id AS id,
    e.organizing_club_id AS club_id,
    COALESCE(c.name, 'Event') AS club_name, 
    c.logo_url AS club_logo_url,
    e.created_by AS author_id,
    e.author_name AS author_name,
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
    e.rsvp_count,
    e.cover_image_url AS media_asset_url
FROM public.event_list_view e
LEFT JOIN public.clubs c ON e.organizing_club_id = c.id
WHERE e.is_published = true;

GRANT SELECT ON public.unified_feed_timeline TO anon, authenticated;
