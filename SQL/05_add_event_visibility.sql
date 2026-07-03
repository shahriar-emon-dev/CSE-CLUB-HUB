-- ============================================================================
-- Migration: 05_add_event_visibility.sql
-- Description: Adds a visibility column to the events table to support Public vs Internal events.
-- ============================================================================

ALTER TABLE public.events 
ADD COLUMN visibility TEXT NOT NULL DEFAULT 'public' 
CHECK (visibility IN ('public', 'internal'));

-- We must drop and recreate the view so that `SELECT e.*` picks up the new visibility column.
DROP VIEW IF EXISTS public.event_list_view;

CREATE VIEW public.event_list_view AS
SELECT 
  e.*,
  p.full_name AS organizer_name,
  COUNT(r.id) AS rsvp_count
FROM public.events e
LEFT JOIN public.profiles p ON e.created_by = p.id
LEFT JOIN public.event_rsvps r ON e.id = r.event_id AND r.status = 'confirmed'
GROUP BY e.id, p.full_name;
