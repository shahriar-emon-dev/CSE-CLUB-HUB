-- ============================================================================
-- Migration: 43_add_comment_replies.sql
-- Description: Adds parent_id to comments table for single-level reply support
-- ============================================================================

ALTER TABLE public.comments
ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_entity_id ON public.comments(entity_id);
