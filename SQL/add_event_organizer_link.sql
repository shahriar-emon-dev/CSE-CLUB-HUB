-- ============================================================================
-- Migration: add_event_organizer_link.sql
-- Description: Adds organizing_club_id to events and creates unified_feed_timeline
-- ============================================================================

-- 1. Add organizing_club_id to events if not exists
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS organizing_club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE;

-- 2. Enable REPLICA IDENTITY FULL for events and posts to ensure real-time triggers are robust
ALTER TABLE public.events REPLICA IDENTITY FULL;
ALTER TABLE public.club_posts REPLICA IDENTITY FULL;
ALTER TABLE public.club_post_reactions REPLICA IDENTITY FULL;
ALTER TABLE public.comments REPLICA IDENTITY FULL;

-- 3. Recreate event_list_view to include club logic and author_name
DROP VIEW IF EXISTS public.event_list_view CASCADE;

CREATE VIEW public.event_list_view AS
SELECT 
  e.*,
  p.full_name AS organizer_name,
  p.avatar_url AS organizer_avatar,
  p.full_name AS author_name,
  COUNT(r.id) AS rsvp_count
FROM public.events e
LEFT JOIN public.profiles p ON e.created_by = p.id
LEFT JOIN public.event_rsvps r ON e.id = r.event_id AND r.status = 'confirmed'
GROUP BY e.id, p.id;

-- 4. Create Unified Feed Timeline
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
    cp.content AS title,
    cp.image_url AS description,
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
    e.rsvp_count
FROM public.event_list_view e
LEFT JOIN public.clubs c ON e.organizing_club_id = c.id
WHERE e.is_published = true;

-- 5. Establish proper RLS logic
-- Event creation is allowed for users if:
-- a) they are super_admin
-- b) they are club_executive / advisor of the organizing_club_id

-- Create a secure definer function for club executive check to avoid recursion
CREATE OR REPLACE FUNCTION public.is_club_executive(club_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE user_id = auth.uid() 
      AND club_id = club_uuid
  );
$$;

-- Ensure is_admin is robust against all role string variations
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
      AND LOWER(role) IN ('advisor/admin', 'super admin', 'super_admin', 'admin')
  );
$$;

-- Drop all previous overlapping INSERT policies on events
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "Users can create events for their club" ON public.events;
DROP POLICY IF EXISTS "events_insert_unified" ON public.events;

-- Create the unified non-recursive INSERT policy
CREATE POLICY "events_insert_unified" ON public.events
FOR INSERT
WITH CHECK (
    auth.uid() = created_by 
    AND (
        public.is_admin()
        OR
        (organizing_club_id IS NOT NULL AND public.is_club_executive(organizing_club_id))
        OR
        organizing_club_id IS NULL
    )
);

-- Grant select to views
GRANT SELECT ON public.unified_feed_timeline TO anon, authenticated;
GRANT SELECT ON public.event_list_view TO anon, authenticated;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
