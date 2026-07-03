-- Migration: 16_system_activities_and_realtime
-- Description: Create system_activities table and enable realtime replication

-- 1. Create system_activities table
CREATE TABLE IF NOT EXISTS public.system_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    actor_name TEXT NOT NULL,
    actor_role TEXT NOT NULL,
    action_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Set up RLS for system_activities
ALTER TABLE public.system_activities ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert (so any user action can be logged, e.g., a member creating a post)
CREATE POLICY "Anyone can insert system activities" 
ON public.system_activities 
FOR INSERT 
WITH CHECK (true);

-- Only admins and super admins can view system activities
CREATE POLICY "Only admins can view system activities"
ON public.system_activities
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('admin', 'super_admin')
    )
);

-- 3. Enable real-time replication for system_activities and profiles
-- Check if the publication 'supabase_realtime' exists, and add tables
BEGIN;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication
        WHERE pubname = 'supabase_realtime'
    ) THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;
COMMIT;

ALTER PUBLICATION supabase_realtime ADD TABLE public.system_activities;
-- Ensure profiles is also in the publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND tablename = 'profiles'
        AND schemaname = 'public'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
    END IF;
END $$;
