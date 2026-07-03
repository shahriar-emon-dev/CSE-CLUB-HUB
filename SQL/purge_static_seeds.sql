BEGIN;

-- 1. Wipe everything to provide a completely blank slate
-- Safely remove ALL dependent records first to avoid foreign key violation errors
DELETE FROM public.club_posts;
DELETE FROM public.events;
DELETE FROM public.club_executives;

-- Finally, delete ALL clubs from the database
DELETE FROM public.clubs;

COMMIT;

-- Invalidate PostgREST cache so the frontend reacts instantly
NOTIFY pgrst, 'reload schema';
