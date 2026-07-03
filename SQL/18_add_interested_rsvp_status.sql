-- ============================================================================
-- Migration: 18_add_interested_rsvp_status.sql
-- Description: Adds 'interested' to the allowed event RSVP statuses and 
--              updates the RLS policy to allow users to change their own RSVPs.
-- ============================================================================

-- 1. Drop the existing CHECK constraint on the status column
ALTER TABLE public.event_rsvps DROP CONSTRAINT IF EXISTS event_rsvps_status_check;

-- 2. Add the new CHECK constraint including 'interested'
ALTER TABLE public.event_rsvps ADD CONSTRAINT event_rsvps_status_check 
  CHECK (status IN ('confirmed', 'interested', 'waitlisted', 'cancelled'));

-- 3. Update the RLS Policy so users can update their own RSVPs (e.g., from interested to confirmed)
DROP POLICY IF EXISTS "rsvps_update" ON public.event_rsvps;
CREATE POLICY "rsvps_update" ON public.event_rsvps FOR UPDATE USING (
  user_id = auth.uid() OR is_admin()
);
