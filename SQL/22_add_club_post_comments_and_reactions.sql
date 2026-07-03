-- ============================================================================
-- Migration: 22_add_club_post_comments_and_reactions.sql
-- Description: Adds reactions table for club posts, updates comments constraints,
--              and creates comprehensive views for the UI.
-- ============================================================================

-- 1. Update Comments Table to allow 'club_post'
ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_entity_type_check;
ALTER TABLE public.comments ADD CONSTRAINT comments_entity_type_check 
    CHECK (entity_type IN ('blog', 'forum_post', 'event', 'club_post'));

-- 2. Create Reactions Table
CREATE TABLE IF NOT EXISTS public.club_post_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.club_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('favorite', 'fire', 'pan_tool')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id, reaction_type)
);

-- Enable RLS on reactions
ALTER TABLE public.club_post_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reactions are viewable by everyone" ON public.club_post_reactions FOR SELECT USING (true);
CREATE POLICY "Users can insert their own reactions" ON public.club_post_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reactions" ON public.club_post_reactions FOR DELETE USING (auth.uid() = user_id);

-- 3. Create view for post details (includes club logo, name, and aggregated counts)
DROP VIEW IF EXISTS public.club_post_view;
CREATE VIEW public.club_post_view AS
SELECT 
    cp.*,
    c.name as club_name,
    c.logo_url as club_logo_url,
    p.full_name as author_name,
    p.avatar_url as author_avatar_url,
    (SELECT count(*) FROM public.comments cmt WHERE cmt.entity_id = cp.id AND cmt.entity_type = 'club_post' AND cmt.is_deleted = false) as comment_count,
    (SELECT count(*) FROM public.club_post_reactions r WHERE r.post_id = cp.id AND r.reaction_type = 'favorite') as favorite_count,
    (SELECT count(*) FROM public.club_post_reactions r WHERE r.post_id = cp.id AND r.reaction_type = 'fire') as fire_count,
    (SELECT count(*) FROM public.club_post_reactions r WHERE r.post_id = cp.id AND r.reaction_type = 'pan_tool') as hand_count
FROM public.club_posts cp
JOIN public.clubs c ON c.id = cp.club_id
JOIN public.profiles p ON p.id = cp.author_id;

GRANT SELECT ON public.club_post_view TO anon, authenticated;

-- 4. Create view for comments with author details and executive badge
DROP VIEW IF EXISTS public.club_post_comments_view;
CREATE VIEW public.club_post_comments_view AS
SELECT 
    cmt.id,
    cmt.entity_id as post_id,
    cmt.author_id,
    cmt.content,
    cmt.created_at,
    p.full_name as author_name,
    p.avatar_url as author_avatar_url,
    -- Check if author is an executive of the club that owns the post
    (EXISTS (
        SELECT 1 FROM public.club_executives ce 
        JOIN public.club_posts cp ON cp.club_id = ce.club_id
        WHERE cp.id = cmt.entity_id AND ce.user_id = cmt.author_id
    )) as is_executive
FROM public.comments cmt
JOIN public.profiles p ON p.id = cmt.author_id
WHERE cmt.entity_type = 'club_post' AND cmt.is_deleted = false;

GRANT SELECT ON public.club_post_comments_view TO anon, authenticated;
