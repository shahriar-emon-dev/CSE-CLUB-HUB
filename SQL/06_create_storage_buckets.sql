-- ============================================================================
-- Migration: 06_create_storage_buckets.sql
-- Description: Creates the necessary storage buckets for the application.
-- ============================================================================

-- Create the buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('avatars', 'avatars', false),
  ('event-covers', 'event-covers', true),
  ('blog-images', 'blog-images', true),
  ('gallery', 'gallery', true)
ON CONFLICT (id) DO NOTHING;

-- Set up policies for event-covers bucket
-- Allow public read access
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'event-covers');

-- Allow authenticated users to upload/update/delete
CREATE POLICY "Authenticated users can upload" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'event-covers' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'event-covers' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'event-covers' AND auth.role() = 'authenticated');
