-- Migration: 17_content_moderation_view
-- Description: Creates a unified view for the content moderation admin portal

CREATE OR REPLACE VIEW public.admin_content_reports_view AS
SELECT 
    cr.id as report_id,
    cr.content_type,
    cr.status,
    cr.severity,
    cr.reason,
    cr.created_at,
    cr.post_id,
    cr.event_id,
    cr.comment_id,
    cr.blog_id,
    
    -- Target entity ID (unified)
    COALESCE(cr.post_id, cr.event_id, cr.comment_id, cr.blog_id) as entity_id,

    -- Unified Title
    COALESCE(
        e.title, 
        b.title, 
        substring(p.content from 1 for 50), 
        substring(c.content from 1 for 50)
    ) as content_title,
    
    -- Unified Text
    COALESCE(
        e.description, 
        b.excerpt, 
        p.content, 
        c.content
    ) as content_text,
    
    -- Author info
    COALESCE(pa.id, ea.id, ca.id, ba.id) as author_id,
    COALESCE(pa.full_name, ea.full_name, ca.full_name, ba.full_name) as author_name,
    COALESCE(pa.avatar_url, ea.avatar_url, ca.avatar_url, ba.avatar_url) as author_avatar,
    
    -- Reporter Info
    rep.full_name as reporter_name
    
FROM public.content_reports cr
LEFT JOIN public.profiles rep ON cr.reporter_id = rep.id

LEFT JOIN public.forum_posts p ON cr.post_id = p.id
LEFT JOIN public.profiles pa ON p.author_id = pa.id

LEFT JOIN public.events e ON cr.event_id = e.id
LEFT JOIN public.profiles ea ON e.created_by = ea.id

LEFT JOIN public.comments c ON cr.comment_id = c.id
LEFT JOIN public.profiles ca ON c.author_id = ca.id

LEFT JOIN public.blogs b ON cr.blog_id = b.id
LEFT JOIN public.profiles ba ON b.author_id = ba.id;

-- Enable Realtime for content_reports if not already enabled
BEGIN;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND tablename = 'content_reports'
        AND schemaname = 'public'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.content_reports;
    END IF;
END $$;
COMMIT;
