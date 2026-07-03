-- ============================================================================
-- Migration: 19_update_event_list_view_avatar.sql
-- Description: Recreates event_list_view to include organizer_avatar
-- ============================================================================

DROP VIEW IF EXISTS public.event_list_view;

CREATE VIEW public.event_list_view AS
SELECT 
  e.*,
  p.full_name AS organizer_name,
  p.avatar_url AS organizer_avatar,
  COUNT(r.id) AS rsvp_count
FROM public.events e
LEFT JOIN public.profiles p ON e.created_by = p.id
LEFT JOIN public.event_rsvps r ON e.id = r.event_id AND r.status = 'confirmed'
GROUP BY e.id, p.id;
