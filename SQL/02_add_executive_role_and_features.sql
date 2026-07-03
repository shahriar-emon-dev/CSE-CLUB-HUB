-- ============================================================================
-- Migration: 02_executive_role_updates.sql
-- Description: Adds core tables and relationships for Clubs, Followers, 
--              Executives, and updates Posts/Events to support club scoping.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create Clubs Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.clubs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    focus_area TEXT,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert the 6 default clubs from the SRS
INSERT INTO public.clubs (name, focus_area) VALUES 
  ('Machine Learning Club', 'AI, Data Science, Deep Learning'),
  ('Competitive Programming Club', 'Algorithms, Contests, Problem Solving'),
  ('IoT & Robotics Club', 'Hardware, Embedded Systems, Automation'),
  ('Web Development Club', 'Frontend, Backend, Full Stack Web'),
  ('Software Development Club', 'App Dev, System Design, Software Engineering'),
  ('Cyber Security Club', 'Network Security, Ethical Hacking, Cryptography')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. Create Club Executives Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.club_executives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_title TEXT NOT NULL, -- e.g., 'President', 'VP'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(club_id, user_id)
);

-- ----------------------------------------------------------------------------
-- 3. Create Club Followers Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.club_followers (
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (club_id, user_id)
);

-- ----------------------------------------------------------------------------
-- 4. Add Missing Columns to Existing Tables
-- ----------------------------------------------------------------------------
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE;

ALTER TABLE public.notices 
ADD COLUMN IF NOT EXISTS club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE;

ALTER TABLE public.blogs 
ADD COLUMN IF NOT EXISTS club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE;

-- ----------------------------------------------------------------------------
-- 5. Row Level Security (RLS) Policies
-- ----------------------------------------------------------------------------
-- Enable RLS
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_executives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_followers ENABLE ROW LEVEL SECURITY;

-- Clubs: Everyone can read
CREATE POLICY "Clubs are viewable by everyone" ON public.clubs FOR SELECT USING (true);

-- Clubs: Only executives of the club can update the club profile
CREATE POLICY "Executives can update their club profile" ON public.clubs FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = clubs.id AND club_executives.user_id = auth.uid()
  )
);

-- Club Followers: Users can follow/unfollow and see who follows what
CREATE POLICY "Anyone can view followers" ON public.club_followers FOR SELECT USING (true);
CREATE POLICY "Users can manage their own followerships" ON public.club_followers 
FOR ALL USING (auth.uid() = user_id);

-- Club Executives: Viewable by everyone, managed by super_admin/admin
CREATE POLICY "Executives viewable by everyone" ON public.club_executives FOR SELECT USING (true);
CREATE POLICY "Admins can manage executives" ON public.club_executives 
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() AND (profiles.role = 'super_admin' OR profiles.role = 'admin')
  )
);

-- Events & Notices: Executives can manage content for their club
CREATE POLICY "Executives can insert events for their club" ON public.events FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = events.club_id AND club_executives.user_id = auth.uid()
  )
);

CREATE POLICY "Executives can update their club events" ON public.events FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = events.club_id AND club_executives.user_id = auth.uid()
  )
);

CREATE POLICY "Executives can delete their club events" ON public.events FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = events.club_id AND club_executives.user_id = auth.uid()
  )
);
