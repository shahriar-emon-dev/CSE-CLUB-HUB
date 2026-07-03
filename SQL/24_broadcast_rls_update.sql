-- ============================================================================
-- Migration: 24_broadcast_rls_update.sql
-- Description: Updates RLS for club_posts to allow super_admin access
--              and ensures the 'posts' storage bucket exists.
-- ============================================================================

-- 1. Ensure 'posts' storage bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for 'posts' bucket
DROP POLICY IF EXISTS "Public Access for posts bucket" ON storage.objects;
CREATE POLICY "Public Access for posts bucket"
ON storage.objects FOR SELECT
USING ( bucket_id = 'posts' );

DROP POLICY IF EXISTS "Authenticated users can upload to posts bucket" ON storage.objects;
CREATE POLICY "Authenticated users can upload to posts bucket"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'posts' 
  AND auth.role() = 'authenticated'
);

-- 2. Update RLS policies on club_posts table
DROP POLICY IF EXISTS "Executives can insert club posts" ON public.club_posts;
DROP POLICY IF EXISTS "Executives can update their club posts" ON public.club_posts;
DROP POLICY IF EXISTS "Executives can delete their club posts" ON public.club_posts;

-- Insert policy
CREATE POLICY "Executives and Super Admins can insert club posts" 
ON public.club_posts FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = club_posts.club_id 
    AND club_executives.user_id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);

-- Update policy
CREATE POLICY "Executives and Super Admins can update club posts" 
ON public.club_posts FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = club_posts.club_id 
    AND club_executives.user_id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);

-- Delete policy
CREATE POLICY "Executives and Super Admins can delete club posts" 
ON public.club_posts FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.club_executives 
    WHERE club_executives.club_id = club_posts.club_id 
    AND club_executives.user_id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);
