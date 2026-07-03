-- ============================================================================
-- Migration: 13_fullstack_sql_wiring.sql
-- Description: Enables Supabase Realtime for required tables and creates
--              triggers to automate notification generation for new events,
--              notices, comments, and replies.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ENABLE SUPABASE REALTIME
-- ----------------------------------------------------------------------------
-- By default, Supabase does not broadcast table changes. We must explicitly add
-- our dynamic tables to the `supabase_realtime` publication so the Flutter app
-- can listen to them.

DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY['events', 'blogs', 'notifications', 'forum_threads', 'forum_posts', 'notices', 'event_rsvps', 'comments', 'profiles'];
BEGIN
    -- Check if publication exists. If not, we can't reliably do this programmatically 
    -- without knowing the user's setup, but Supabase always has it.
    FOREACH tbl IN ARRAY tables
    LOOP
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' AND tablename = tbl
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        END IF;
    END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- 2. AUTOMATED NOTIFICATION TRIGGERS
-- ----------------------------------------------------------------------------

-- A. Notify all members on new PUBLISHED event
CREATE OR REPLACE FUNCTION public.handle_new_event_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- If inserted as published, or updated from unpublished to published
  IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE) OR 
     (TG_OP = 'UPDATE' AND OLD.is_published = FALSE AND NEW.is_published = TRUE) THEN
     
     -- Insert a notification for every approved member
     INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
     SELECT 
        p.id, 
        'new_event', 
        'New Event: ' || NEW.title, 
        NEW.category,
        'event', 
        NEW.id
     FROM public.profiles p
     WHERE p.is_approved = TRUE 
       AND p.status = 'active';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_event_published ON public.events;
CREATE TRIGGER on_event_published
  AFTER INSERT OR UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_event_notification();

-- B. Notify all members on new notice
CREATE OR REPLACE FUNCTION public.handle_new_notice_notification()
RETURNS TRIGGER AS $$
BEGIN
   -- Insert a notification for every approved member
   INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
   SELECT 
      p.id, 
      'new_notice', 
      'Notice: ' || NEW.title, 
      NEW.category,
      'notice', 
      NEW.id
   FROM public.profiles p
   WHERE p.is_approved = TRUE 
     AND p.status = 'active';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_notice_created ON public.notices;
CREATE TRIGGER on_notice_created
  AFTER INSERT ON public.notices
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_notice_notification();

-- C. Notify thread author on new forum reply (forum_posts)
CREATE OR REPLACE FUNCTION public.handle_forum_reply_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_thread_author UUID;
  v_thread_title TEXT;
BEGIN
  -- Get the thread's author and title
  SELECT author_id, title INTO v_thread_author, v_thread_title
  FROM public.forum_threads
  WHERE id = NEW.thread_id;

  -- Don't notify if the replier is the author
  IF v_thread_author != NEW.author_id THEN
     INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
     VALUES (
        v_thread_author,
        'forum_reply',
        'New reply on your thread',
        'Someone replied to "' || v_thread_title || '"',
        'forum_thread',
        NEW.thread_id
     );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_forum_reply_notification ON public.forum_posts;
CREATE TRIGGER on_forum_reply_notification
  AFTER INSERT ON public.forum_posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_forum_reply_notification();

-- D. Notify RSVP when confirmed (optional, currently RSVP inserts default to confirmed)
CREATE OR REPLACE FUNCTION public.handle_rsvp_confirmed_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_event_title TEXT;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'confirmed' THEN
    SELECT title INTO v_event_title FROM public.events WHERE id = NEW.event_id;
    INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
    VALUES (
      NEW.user_id,
      'rsvp_confirmed',
      'RSVP Confirmed',
      'You are confirmed for "' || v_event_title || '"',
      'event',
      NEW.event_id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_rsvp_confirmed_notification ON public.event_rsvps;
CREATE TRIGGER on_rsvp_confirmed_notification
  AFTER INSERT ON public.event_rsvps
  FOR EACH ROW EXECUTE FUNCTION public.handle_rsvp_confirmed_notification();
