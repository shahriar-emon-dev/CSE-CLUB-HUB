-- Add missing fields for user profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS department TEXT,
ADD COLUMN IF NOT EXISTS semester TEXT,
ADD COLUMN IF NOT EXISTS "group" TEXT;

-- Add avatars storage bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true) 
ON CONFLICT (id) DO NOTHING;

-- Policy to allow users to insert their own avatar
CREATE POLICY "Allow users to upload avatars" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars');

-- Policy to allow users to update their own avatar
CREATE POLICY "Allow users to update avatars" ON storage.objects
FOR UPDATE TO authenticated USING (bucket_id = 'avatars') WITH CHECK (bucket_id = 'avatars');

-- Policy to allow public to view avatars
CREATE POLICY "Allow public to view avatars" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');
