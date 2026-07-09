-- ==============================================================================
-- 41_search_platform_entities.sql
-- Production Server-Side Search RPC for CSE ClubHub
-- ==============================================================================

CREATE OR REPLACE FUNCTION get_search_results(p_query text, p_limit int DEFAULT 10)
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
    -- Users / Profiles
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

    -- Clubs
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

    -- Events
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

    -- Blogs / Posts
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
