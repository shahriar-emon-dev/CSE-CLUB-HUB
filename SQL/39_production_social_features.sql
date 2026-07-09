-- ============================================================================
-- Migration: 39_production_social_features.sql
-- Description: Hardens the social interaction features (Likes, Comments)
--              and sets up dynamic Postgres triggers to automatically fire
--              push notifications via the existing Edge Function.
-- ============================================================================

-- 1. HARDEN REACTIONS CONSTRAINT
-- The previous constraint allowed a user to have multiple different reactions on the same post.
-- We want exactly ONE reaction per user per post.
ALTER TABLE public.club_post_reactions DROP CONSTRAINT IF EXISTS club_post_reactions_post_id_user_id_reaction_type_key;
ALTER TABLE public.club_post_reactions DROP CONSTRAINT IF EXISTS club_post_reactions_post_id_user_id_key;

-- We also need to clean up any duplicates before applying the new constraint.
-- Keep the most recent reaction for any given (post_id, user_id) combination.
DELETE FROM public.club_post_reactions a USING (
  SELECT MIN(ctid) as ctid, post_id, user_id
  FROM public.club_post_reactions 
  GROUP BY post_id, user_id HAVING COUNT(*) > 1
) b
WHERE a.post_id = b.post_id 
AND a.user_id = b.user_id 
AND a.ctid <> b.ctid;

-- Now apply the strict constraint
ALTER TABLE public.club_post_reactions ADD CONSTRAINT club_post_reactions_post_id_user_id_key UNIQUE (post_id, user_id);


-- 2. EXTEND NOTIFICATIONS TYPE CONSTRAINT
-- We need to add types for new_post, new_reaction, mention, and new_announcement.
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check CHECK (
    type IN (
        'new_event','event_reminder','rsvp_confirmed','rsvp_waitlisted',
        'blog_approved','blog_rejected','new_notice','new_comment',
        'new_reply','role_changed','member_approved','forum_reply',
        'new_post', 'new_reaction', 'mention', 'new_announcement'
    )
);

-- 3. CREATE AUTOMATED POSTGRES TRIGGERS FOR NOTIFICATIONS

-- A. Trigger for New Club Post
CREATE OR REPLACE FUNCTION public.handle_new_club_post_notification()
RETURNS trigger AS $$
DECLARE
    club_member RECORD;
    v_club_name TEXT;
    v_author_name TEXT;
BEGIN
    -- Fetch the club name
    SELECT name INTO v_club_name FROM public.clubs WHERE id = NEW.club_id;
    -- Fetch the author name
    SELECT full_name INTO v_author_name FROM public.profiles WHERE id = NEW.author_id;

    -- Insert a notification for every member of the club, EXCEPT the author
    FOR club_member IN 
        SELECT user_id FROM public.club_members 
        WHERE club_id = NEW.club_id AND status = 'approved' AND user_id != NEW.author_id
    LOOP
        INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
        VALUES (
            club_member.user_id,
            'new_post',
            v_club_name,
            v_author_name || ' published a new post.',
            'club_post',
            NEW.id
        );
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_club_post ON public.club_posts;
CREATE TRIGGER on_new_club_post
    AFTER INSERT ON public.club_posts
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_club_post_notification();


-- B. Trigger for New Comment on Club Post
CREATE OR REPLACE FUNCTION public.handle_new_club_post_comment_notification()
RETURNS trigger AS $$
DECLARE
    v_post_author_id UUID;
    v_commenter_name TEXT;
BEGIN
    -- Only handle club_post comments
    IF NEW.entity_type = 'club_post' THEN
        -- Get the author of the post
        SELECT author_id INTO v_post_author_id FROM public.club_posts WHERE id = NEW.entity_id;
        
        -- Get the name of the commenter
        SELECT full_name INTO v_commenter_name FROM public.profiles WHERE id = NEW.author_id;

        -- Don't notify the user if they commented on their own post
        IF v_post_author_id != NEW.author_id THEN
            INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
            VALUES (
                v_post_author_id,
                'new_comment',
                'New Comment',
                v_commenter_name || ' commented on your post.',
                'club_post',
                NEW.entity_id
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_comment ON public.comments;
CREATE TRIGGER on_new_comment
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_club_post_comment_notification();


-- C. Trigger for New Reaction on Club Post
CREATE OR REPLACE FUNCTION public.handle_new_club_post_reaction_notification()
RETURNS trigger AS $$
DECLARE
    v_post_author_id UUID;
    v_reactor_name TEXT;
    v_reaction_emoji TEXT;
BEGIN
    -- Get the author of the post
    SELECT author_id INTO v_post_author_id FROM public.club_posts WHERE id = NEW.post_id;
    
    -- Get the name of the reactor
    SELECT full_name INTO v_reactor_name FROM public.profiles WHERE id = NEW.user_id;

    -- Map reaction type to emoji text
    IF NEW.reaction_type = 'favorite' THEN
        v_reaction_emoji := '❤️';
    ELSIF NEW.reaction_type = 'fire' THEN
        v_reaction_emoji := '🔥';
    ELSE
        v_reaction_emoji := '👏';
    END IF;

    -- Don't notify the user if they reacted to their own post
    IF v_post_author_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, type, title, body, entity_type, entity_id)
        VALUES (
            v_post_author_id,
            'new_reaction',
            'New Reaction',
            v_reactor_name || ' reacted ' || v_reaction_emoji || ' to your post.',
            'club_post',
            NEW.post_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_club_post_reaction ON public.club_post_reactions;
CREATE TRIGGER on_new_club_post_reaction
    AFTER INSERT ON public.club_post_reactions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_club_post_reaction_notification();


-- 4. FIX PREVIOUS PUSH NOTIFICATION TRIGGER TYPO
-- The previous trigger used NEW.reference_id instead of NEW.entity_id
CREATE OR REPLACE FUNCTION public.handle_push_notification()
RETURNS trigger AS $$
BEGIN
  -- We use pg_net to make an asynchronous HTTP POST to our Edge Function.
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
        'entity_type', NEW.entity_type,
        'entity_id', NEW.entity_id
      )::jsonb
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
