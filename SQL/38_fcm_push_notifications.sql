-- SQL Migration: 38_fcm_push_notifications.sql
-- Enables FCM token tracking and dynamic triggers for Push Notifications via Edge Functions

-- 1. Enable pg_net extension for HTTP calls if not exists
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- 2. Create the fcm_tokens table to support multiple devices per user
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create an index for faster lookups by user
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON public.fcm_tokens(user_id);

-- 3. RLS for fcm_tokens
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own tokens"
    ON public.fcm_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own tokens"
    ON public.fcm_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own tokens"
    ON public.fcm_tokens FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tokens"
    ON public.fcm_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- 4. Function to automatically trigger FCM via Supabase Edge Function
CREATE OR REPLACE FUNCTION public.handle_push_notification()
RETURNS trigger AS $$
BEGIN
  -- We use pg_net to make an asynchronous HTTP POST to our Edge Function.
  -- The Edge Function will handle looking up the FCM tokens and interacting with Firebase.
  PERFORM net.http_post(
      -- Note: In a real environment, replace 'http://host.docker.internal' with your project's URL
      url:='https://your-project.supabase.co/functions/v1/push-notification',
      headers:=jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer YOUR_ANON_KEY' -- Replace in production or use vault
      ),
      body:=json_build_object(
        'notification_id', NEW.id,
        'user_id', NEW.user_id,
        'title', NEW.title,
        'body', NEW.body,
        'type', NEW.type,
        'reference_id', NEW.reference_id
      )::jsonb
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Attach trigger to the notifications table
DROP TRIGGER IF EXISTS on_notification_created ON public.notifications;
CREATE TRIGGER on_notification_created
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.handle_push_notification();
