-- ============================================================================
-- Migration: 45_align_role_convention_and_storage_with_flutter_app.sql
-- Description: Corrects two live contract mismatches found while cross-checking
--              the SQL layer against the actual Flutter client code:
--
-- BUG 1 — profiles.role convention mismatch (security-relevant):
--   44_complete_production_database_ecosystem.sql reverted profiles.role,
--   the RLS helper functions (is_admin/is_super_admin/is_executive_or_admin/
--   is_member), and every role-assigning RPC to snake_case values
--   ('super_admin', 'executive', 'member', ...). But the Flutter app writes
--   and reads Title-Case values everywhere (auth_provider.dart signUp() sets
--   'role': 'Regular Student'; UserProfile.toJson()/UserRole.value produce
--   'Super Admin' / 'Club Executive' / 'Regular Student'). An earlier
--   migration (25_fix_rbac_strings_and_recursion.sql, four_tier_rbac_system.sql)
--   had already fixed this once; 44_ silently regressed it. Net effect:
--     - New registrations writing 'Regular Student' directly violate 44_'s
--       snake_case-only CHECK constraint (hard failure on signup), and
--     - Any profile whose role is stored as 'Super Admin'/'Club Executive'
--       (from before 44_ ran) is invisible to is_super_admin()/
--       is_executive_or_admin(), silently failing every RLS policy gated on
--       those functions even though the Flutter UI still shows them as admin.
--   Fix: standardize the DB side on the same Title-Case convention the
--   Flutter app already uses everywhere, matching UserRole.value in
--   lib/models/user_profile.dart exactly. club_members.role and
--   club_executives.role/role_title/position are untouched — Dart never
--   reads those through UserRole, they're internal-only columns.
--
-- BUG 2 — storage bucket name/visibility mismatch:
--   lib/core/constants/supabase_config.dart defines the buckets the app
--   actually uploads to: avatars, event-covers, blog-images, gallery — all
--   fetched back via getPublicUrl() (see profile_repository.dart:61,
--   create_event_screen.dart, edit_event_screen.dart). 44_'s Section 8
--   instead created differently-named buckets (club-logos, post-images,
--   event-banners, gallery-images) and never created blog-images at all.
--   Any upload to event-covers/blog-images/gallery would fail with
--   "bucket not found" if 06_create_storage_buckets.sql's original bucket
--   set was never applied (or was superseded). This migration ensures the
--   exact bucket ids the app references exist, are public (required for
--   getPublicUrl() to serve a working URL), and have matching policies. It
--   does not touch/drop the extra buckets 44_ created — harmless if unused.
--
-- Idempotent: safe to run multiple times and safe to run whether or not
-- 44_complete_production_database_ecosystem.sql has already been applied.
-- ============================================================================

BEGIN;

-- ============================================================================
-- SECTION A: Drop every prior CHECK constraint on profiles.role FIRST.
--
-- This must happen before any data normalization. The original version of
-- this migration normalized data first and dropped/re-added the constraint
-- second — but if 44_'s snake_case-only constraint (or any earlier variant)
-- was still live at that point, the normalization UPDATEs themselves (which
-- write Title-Case values) would violate it immediately. Explicitly named
-- constraints from the migration history are dropped by name in addition to
-- the dynamic sweep, in case the sweep's text match ever misses one.
-- ============================================================================

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS check_valid_role;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'public.profiles'::regclass
          AND contype = 'c'
          AND pg_get_constraintdef(oid) ILIKE '%role%'
    ) LOOP
        EXECUTE 'ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname) || ';';
    END LOOP;
END
$$;

-- ============================================================================
-- SECTION B: Now that no CHECK constraint is active, normalize existing
-- profiles.role data to Title-Case.
-- ============================================================================

UPDATE public.profiles SET role = 'Super Admin'     WHERE role IN ('super_admin', 'Super Admin');
UPDATE public.profiles SET role = 'Advisor/Admin'    WHERE role IN ('admin', 'Advisor/Admin');
UPDATE public.profiles SET role = 'Club Executive'   WHERE role IN ('executive', 'Club Executive');
UPDATE public.profiles SET role = 'Regular Student'  WHERE role IS NULL
    OR role NOT IN ('Super Admin', 'Advisor/Admin', 'Club Executive', 'Regular Student');

-- Data is now guaranteed clean — safe to add the tightened constraint.
ALTER TABLE public.profiles
ADD CONSTRAINT profiles_role_check
CHECK (role IN ('Super Admin', 'Advisor/Admin', 'Club Executive', 'Regular Student'));

ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'Regular Student';

-- ============================================================================
-- SECTION C: Redefine the RLS helper functions on the Title-Case convention.
-- Redefining these in place automatically fixes every RLS policy that
-- already calls them (Section 5 of 44_) without needing to touch the
-- policies themselves.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('Super Admin', 'Advisor/Admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'Super Admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_executive_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('Super Admin', 'Advisor/Admin', 'Club Executive')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_member()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('Regular Student', 'Club Executive', 'Advisor/Admin', 'Super Admin')
      AND is_approved = TRUE
  );
$$;

-- ============================================================================
-- SECTION D: Redefine role-assigning RPCs to write Title-Case values.
-- Only the profiles.role literals change; club_members/club_executives
-- columns keep their existing internal-only convention untouched.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.remove_user_role(
    p_target_user_id UUID,
    p_admin_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_admin_id AND role IN ('Super Admin', 'Advisor/Admin')) THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can revoke roles.';
    END IF;

    UPDATE public.profiles SET role = 'Regular Student', updated_at = NOW() WHERE id = p_target_user_id;

    INSERT INTO public.moderation_logs (moderator_id, action, notes)
    VALUES (p_admin_id, 'role_revoked', 'Revoked elevated role for user ' || p_target_user_id);

    RETURN json_build_object('success', true, 'role', 'Regular Student');
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_executive(
    p_user_id UUID,
    p_club_id UUID,
    p_admin_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_admin_id AND role IN ('Super Admin', 'Advisor/Admin', 'Club Executive')) THEN
        RAISE EXCEPTION 'Unauthorized: Only club executives or admins can approve executives.';
    END IF;

    INSERT INTO public.club_members (club_id, user_id, role, status)
    VALUES (p_club_id, p_user_id, 'executive', 'approved')
    ON CONFLICT (club_id, user_id)
    DO UPDATE SET role = 'executive', status = 'approved', updated_at = NOW();

    UPDATE public.profiles SET role = 'Club Executive' WHERE id = p_user_id AND role = 'Regular Student';

    RETURN json_build_object('success', true, 'status', 'approved');
END;
$$;

CREATE OR REPLACE FUNCTION public.assign_executive_role(
    p_user_id UUID,
    p_club_id UUID,
    p_role_title TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles
    SET role = 'Club Executive',
        updated_at = NOW()
    WHERE id = p_user_id;

    INSERT INTO public.club_executives (club_id, user_id, role_title, position, role, is_active, created_at, updated_at)
    VALUES (p_club_id, p_user_id, p_role_title, p_role_title, 'executive', TRUE, NOW(), NOW())
    ON CONFLICT (club_id, user_id)
    DO UPDATE SET
        role_title = EXCLUDED.role_title,
        position = EXCLUDED.position,
        role = 'executive',
        is_active = TRUE,
        updated_at = NOW();

    INSERT INTO public.club_followers (club_id, user_id, created_at)
    VALUES (p_club_id, p_user_id, NOW())
    ON CONFLICT DO NOTHING;

    INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    VALUES (
        auth.uid(),
        'promoted_executive',
        'profile',
        p_user_id,
        jsonb_build_object('club_id', p_club_id, 'role_title', p_role_title)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.revoke_executive_role(
    p_user_id UUID,
    p_club_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    IF p_club_id IS NOT NULL THEN
        UPDATE public.club_executives
        SET is_active = FALSE,
            updated_at = NOW()
        WHERE user_id = p_user_id AND club_id = p_club_id;
    ELSE
        UPDATE public.club_executives
        SET is_active = FALSE,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.club_executives
        WHERE user_id = p_user_id AND is_active = TRUE
    ) THEN
        UPDATE public.profiles
        SET role = 'Regular Student',
            updated_at = NOW()
        WHERE id = p_user_id AND role = 'Club Executive';
    END IF;

    INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, metadata)
    VALUES (
        auth.uid(),
        'revoked_executive',
        'profile',
        p_user_id,
        jsonb_build_object('revoked_at', NOW(), 'club_id', p_club_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
    SELECT COUNT(*) INTO v_total_executives FROM profiles WHERE role IN ('Super Admin', 'Advisor/Admin', 'Club Executive');
    SELECT COUNT(*) INTO v_active_clubs FROM clubs WHERE status = 'active';
    SELECT COUNT(*) INTO v_total_events FROM events WHERE is_cancelled = false OR is_cancelled IS NULL;
    SELECT COUNT(*) INTO v_total_posts FROM club_posts;
    SELECT COUNT(*) INTO v_total_comments FROM comments WHERE is_deleted = false OR is_deleted IS NULL;
    SELECT COUNT(*) INTO v_total_reactions FROM club_post_reactions;
    SELECT COUNT(*) INTO v_total_rsvps FROM event_rsvps WHERE status IN ('confirmed', 'going');
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

-- assign_user_role is a generic passthrough (caller supplies p_new_role), so
-- only its authorization check needs the Title-Case convention — the role
-- value itself is whatever the caller passes.
CREATE OR REPLACE FUNCTION public.assign_user_role(
    p_target_user_id UUID,
    p_new_role TEXT,
    p_admin_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_admin_id AND role IN ('Super Admin', 'Advisor/Admin')) THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can assign roles.';
    END IF;

    UPDATE public.profiles SET role = p_new_role, updated_at = NOW() WHERE id = p_target_user_id;

    INSERT INTO public.moderation_logs (moderator_id, action, notes)
    VALUES (p_admin_id, 'role_assigned', 'Assigned role ' || p_new_role || ' to user ' || p_target_user_id);

    RETURN json_build_object('success', true, 'role', p_new_role);
END;
$$;

-- ============================================================================
-- SECTION E: Storage buckets — ensure the exact ids SupabaseConfig references
-- exist and are public (required for the getPublicUrl() calls the app makes).
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES
    ('avatars', 'avatars', true),
    ('event-covers', 'event-covers', true),
    ('blog-images', 'blog-images', true),
    ('gallery', 'gallery', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "App buckets public read" ON storage.objects;
CREATE POLICY "App buckets public read"
ON storage.objects FOR SELECT
USING (bucket_id IN ('avatars', 'event-covers', 'blog-images', 'gallery'));

DROP POLICY IF EXISTS "App buckets authenticated upload" ON storage.objects;
CREATE POLICY "App buckets authenticated upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id IN ('avatars', 'event-covers', 'blog-images', 'gallery') AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "App buckets authenticated update" ON storage.objects;
CREATE POLICY "App buckets authenticated update"
ON storage.objects FOR UPDATE
USING (bucket_id IN ('avatars', 'event-covers', 'blog-images', 'gallery') AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "App buckets authenticated delete" ON storage.objects;
CREATE POLICY "App buckets authenticated delete"
ON storage.objects FOR DELETE
USING (bucket_id IN ('avatars', 'event-covers', 'blog-images', 'gallery') AND auth.role() = 'authenticated');

-- ============================================================================
-- SECTION F: Ensure get_search_results exists — this is the exact RPC name
-- search_repository.dart calls (`.rpc('get_search_results', ...)`). 44_ only
-- defined a differently-named search_everything(), so if
-- 41_search_platform_entities.sql was never applied on this project,
-- get_search_results would not exist and every search would silently fall
-- back to the client's parallel-query path. Re-asserting it here removes
-- that ambiguity regardless of prior migration history.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_search_results(p_query text, p_limit int DEFAULT 10)
RETURNS TABLE (
    entity_type text,
    id uuid,
    title text,
    subtitle text,
    image_url text,
    extra_data jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_search_pattern text := '%' || trim(p_query) || '%';
BEGIN
    RETURN QUERY
    (
        SELECT
            'user'::text AS entity_type,
            p.id,
            p.full_name AS title,
            COALESCE(p.department || ' • ' || COALESCE(p.role, 'Student'), p.role, 'Student') AS subtitle,
            p.avatar_url AS image_url,
            jsonb_build_object(
                'student_id', p.student_id,
                'batch', p.batch,
                'role', p.role
            ) AS extra_data
        FROM public.profiles p
        WHERE p.is_approved = true
          AND (p.full_name ILIKE v_search_pattern OR COALESCE(p.student_id, '') ILIKE v_search_pattern OR COALESCE(p.department, '') ILIKE v_search_pattern)
        LIMIT p_limit
    )
    UNION ALL
    (
        SELECT
            'club'::text AS entity_type,
            c.id,
            c.name AS title,
            COALESCE(c.focus_area, 'Student Club') AS subtitle,
            c.logo_url AS image_url,
            jsonb_build_object(
                'focus_area', c.focus_area,
                'description', c.description,
                'member_count', c.member_count
            ) AS extra_data
        FROM public.club_list_view c
        WHERE c.name ILIKE v_search_pattern OR COALESCE(c.description, '') ILIKE v_search_pattern OR COALESCE(c.focus_area, '') ILIKE v_search_pattern
        LIMIT p_limit
    )
    UNION ALL
    (
        SELECT
            'event'::text AS entity_type,
            e.id,
            e.title,
            COALESCE(e.organizer_name || ' • ' || to_char(e.event_date, 'Mon DD, YYYY'), to_char(e.event_date, 'Mon DD, YYYY')) AS subtitle,
            e.cover_image_url AS image_url,
            jsonb_build_object(
                'event_date', e.event_date,
                'venue', e.venue,
                'category', e.category,
                'created_by', e.created_by
            ) AS extra_data
        FROM public.event_list_view e
        WHERE e.is_published = true
          AND (e.title ILIKE v_search_pattern OR COALESCE(e.description, '') ILIKE v_search_pattern OR COALESCE(e.venue, '') ILIKE v_search_pattern)
        LIMIT p_limit
    )
    UNION ALL
    (
        SELECT
            'post'::text AS entity_type,
            b.id,
            b.title,
            COALESCE('By ' || COALESCE(p.full_name, 'Unknown'), 'Post') AS subtitle,
            b.cover_image_url AS image_url,
            jsonb_build_object(
                'created_at', b.created_at,
                'author_id', b.author_id,
                'category', b.category
            ) AS extra_data
        FROM public.blogs b
        LEFT JOIN public.profiles p ON b.author_id = p.id
        WHERE b.status = 'published'
          AND (b.title ILIKE v_search_pattern OR COALESCE(b.content, '') ILIKE v_search_pattern)
        LIMIT p_limit
    );
END;
$$;

COMMIT;
