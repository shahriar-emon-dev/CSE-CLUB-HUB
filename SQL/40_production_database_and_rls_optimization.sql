-- ====================================================================
-- Migration: 40_production_database_and_rls_optimization.sql
-- Description: Productionizes Supabase queries, creates single-pass
-- dashboard metrics RPC, atomic constraints, high-speed indexes, and
-- server-side search RPC.
-- ====================================================================

BEGIN;

-- 1. Hardening Atomic Constraints (One reaction per user, one RSVP per user)
-- Remove duplicate reactions if any exist before enforcing unique constraint
DELETE FROM public.club_post_reactions a USING (
  SELECT MIN(ctid) as ctid, post_id, user_id
  FROM public.club_post_reactions 
  GROUP BY post_id, user_id HAVING COUNT(*) > 1
) b
WHERE a.post_id = b.post_id AND a.user_id = b.user_id AND a.ctid <> b.ctid;

ALTER TABLE public.club_post_reactions DROP CONSTRAINT IF EXISTS club_post_reactions_post_id_user_id_key;
ALTER TABLE public.club_post_reactions ADD CONSTRAINT club_post_reactions_post_id_user_id_key UNIQUE (post_id, user_id);

ALTER TABLE public.event_rsvps DROP CONSTRAINT IF EXISTS event_rsvps_event_id_user_id_key;
ALTER TABLE public.event_rsvps ADD CONSTRAINT event_rsvps_event_id_user_id_key UNIQUE (event_id, user_id);

-- 2. Performance Indexes for Fast Filtering, Ordering, and Joins
CREATE INDEX IF NOT EXISTS idx_profiles_role_status_dept ON public.profiles(role, status, department);
CREATE INDEX IF NOT EXISTS idx_clubs_focus_area ON public.clubs(focus_area);
CREATE INDEX IF NOT EXISTS idx_club_posts_feed_order ON public.club_posts(club_id, is_pinned, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_club_reactions_post_user ON public.club_post_reactions(post_id, user_id, reaction_type);
CREATE INDEX IF NOT EXISTS idx_events_date_status ON public.events(event_date, is_cancelled, is_published);
CREATE INDEX IF NOT EXISTS idx_comments_entity_tree ON public.comments(entity_type, entity_id, parent_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_content_reports_queue ON public.content_reports(status, severity, created_at DESC);

-- 3. Single-Pass Admin Dashboard Metrics RPC
-- Eliminates N+1 / 9 parallel HTTP requests by returning all live counts in 1 call
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_metrics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_students INT;
  v_active_members INT;
  v_total_executives INT;
  v_active_clubs INT;
  v_total_events INT;
  v_total_posts INT;
  v_total_comments INT;
  v_total_reactions INT;
  v_total_rsvps INT;
  v_pending_reports INT;
  v_high_risk_reports INT;
  v_resolved_today_reports INT;
BEGIN
  SELECT COUNT(*) INTO v_total_students FROM profiles;
  SELECT COUNT(*) INTO v_active_members FROM profiles WHERE status = 'active' OR status IS NULL;
  SELECT COUNT(*) INTO v_total_executives FROM profiles WHERE role IN ('super_admin', 'admin', 'executive');
  SELECT COUNT(*) INTO v_active_clubs FROM clubs;
  SELECT COUNT(*) INTO v_total_events FROM events WHERE is_cancelled = false OR is_cancelled IS NULL;
  SELECT COUNT(*) INTO v_total_posts FROM club_posts;
  SELECT COUNT(*) INTO v_total_comments FROM comments WHERE is_deleted = false OR is_deleted IS NULL;
  SELECT COUNT(*) INTO v_total_reactions FROM club_post_reactions;
  SELECT COUNT(*) INTO v_total_rsvps FROM event_rsvps;
  SELECT COUNT(*) INTO v_pending_reports FROM content_reports WHERE status = 'pending';
  SELECT COUNT(*) INTO v_high_risk_reports FROM content_reports WHERE status = 'pending' AND severity IN ('high', 'urgent');
  SELECT COUNT(*) INTO v_resolved_today_reports FROM content_reports WHERE status = 'resolved' AND resolved_at >= current_date;

  RETURN json_build_object(
    'total_students', v_total_students,
    'active_members', v_active_members,
    'total_executives', v_total_executives,
    'active_clubs', v_active_clubs,
    'total_events', v_total_events,
    'total_posts', v_total_posts,
    'total_comments', v_total_comments,
    'total_reactions', v_total_reactions,
    'total_rsvps', v_total_rsvps,
    'pending_reports', v_pending_reports,
    'high_risk_reports', v_high_risk_reports,
    'resolved_today_reports', v_resolved_today_reports
  );
END;
$$;

-- 4. Server-Side Search RPC
-- Provides centralized, fast server-side searching across profiles, clubs, events, and posts
CREATE OR REPLACE FUNCTION public.search_platform_entities(
  p_query TEXT,
  p_limit INT DEFAULT 10,
  p_offset INT DEFAULT 0
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_results JSON;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO v_results
  FROM (
    (
      SELECT 
        'user' as type,
        id::text as id,
        full_name as title,
        COALESCE(department || ' - ' || student_id, role) as subtitle,
        avatar_url as avatar_url,
        created_at
      FROM profiles
      WHERE full_name ILIKE '%' || p_query || '%' OR student_id ILIKE '%' || p_query || '%' OR email ILIKE '%' || p_query || '%'
      LIMIT p_limit
    )
    UNION ALL
    (
      SELECT 
        'club' as type,
        id::text as id,
        name as title,
        COALESCE(focus_area, description) as subtitle,
        logo_url as avatar_url,
        created_at
      FROM clubs
      WHERE name ILIKE '%' || p_query || '%' OR COALESCE(description, '') ILIKE '%' || p_query || '%' OR COALESCE(focus_area, '') ILIKE '%' || p_query || '%'
      LIMIT p_limit
    )
    UNION ALL
    (
      SELECT 
        'event' as type,
        id::text as id,
        title as title,
        COALESCE(venue, description) as subtitle,
        cover_image_url as avatar_url,
        created_at
      FROM events
      WHERE title ILIKE '%' || p_query || '%' OR COALESCE(description, '') ILIKE '%' || p_query || '%' OR COALESCE(venue, '') ILIKE '%' || p_query || '%'
      LIMIT p_limit
    )
    UNION ALL
    (
      SELECT 
        'post' as type,
        id::text as id,
        substring(content from 1 for 50) as title,
        content as subtitle,
        image_url as avatar_url,
        created_at
      FROM club_posts
      WHERE content ILIKE '%' || p_query || '%'
      LIMIT p_limit
    )
    ORDER BY created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN COALESCE(v_results, '[]'::json);
END;
$$;

-- 5. Realtime Publication Check
-- Guarantee REPLICA IDENTITY FULL and publication inclusion for real-time reactivity
ALTER TABLE public.profiles REPLICA IDENTITY FULL;
ALTER TABLE public.clubs REPLICA IDENTITY FULL;
ALTER TABLE public.club_posts REPLICA IDENTITY FULL;
ALTER TABLE public.events REPLICA IDENTITY FULL;
ALTER TABLE public.comments REPLICA IDENTITY FULL;
ALTER TABLE public.club_post_reactions REPLICA IDENTITY FULL;
ALTER TABLE public.content_reports REPLICA IDENTITY FULL;
ALTER TABLE public.system_activities REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'clubs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.clubs;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'club_posts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.club_posts;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'comments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'club_post_reactions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.club_post_reactions;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'content_reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.content_reports;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_publication p ON pr.prpubid = p.oid
    JOIN pg_class c ON pr.prrelid = c.oid
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'system_activities'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.system_activities;
  END IF;
END $$;

COMMIT;
