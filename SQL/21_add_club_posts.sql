-- ============================================================================
-- Migration: 21_add_club_posts.sql
-- Description: Adds a club_posts table for executive broadcasts.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.club_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.club_posts ENABLE ROW LEVEL SECURITY;

-- Select policy: viewable by everyone
CREATE POLICY "Club posts are viewable by everyone" 
ON public.club_posts FOR SELECT USING (true);

-- Insert policy: executives of the club can insert
CREATE POLICY "Executives can insert club posts" 
ON public.club_posts FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = club_posts.club_id 
    AND club_executives.user_id = auth.uid()
  )
);

-- Update policy: executives of the club can update
CREATE POLICY "Executives can update their club posts" 
ON public.club_posts FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = club_posts.club_id 
    AND club_executives.user_id = auth.uid()
  )
);

-- Delete policy: executives of the club can delete
CREATE POLICY "Executives can delete their club posts" 
ON public.club_posts FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = club_posts.club_id 
    AND club_executives.user_id = auth.uid()
  )
);
