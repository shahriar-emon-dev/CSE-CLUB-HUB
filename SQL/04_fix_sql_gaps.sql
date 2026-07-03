-- ============================================================================
-- Migration: 04_fix_sql_gaps.sql
-- Description: Fills missing SQL gaps discovered by analyzing the Dart codebase.
--              Adds missing RPC functions and updated_at triggers.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Missing RPC Functions for View Counts
-- ----------------------------------------------------------------------------

-- Called by lib/features/blogs/providers/blogs_provider.dart
CREATE OR REPLACE FUNCTION public.increment_blog_views(blog_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.blogs
  SET view_count = view_count + 1
  WHERE id = blog_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Called by lib/features/forum/screens/thread_detail_screen.dart
CREATE OR REPLACE FUNCTION public.increment_thread_views(thread_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.forum_threads
  SET view_count = view_count + 1
  WHERE id = thread_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- 2. Missing Triggers for updated_at Columns
-- ----------------------------------------------------------------------------

-- Add trigger for clubs table
DROP TRIGGER IF EXISTS clubs_updated_at ON public.clubs;
CREATE TRIGGER clubs_updated_at
  BEFORE UPDATE ON public.clubs
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Add trigger for notification_preferences table
DROP TRIGGER IF EXISTS notification_preferences_updated_at ON public.notification_preferences;
CREATE TRIGGER notification_preferences_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
