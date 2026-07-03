-- Append the missing timestamp column tracking metadata cleanly to the target entity
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Create an explicit performance index to optimize reverse-chronological sorting
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);
