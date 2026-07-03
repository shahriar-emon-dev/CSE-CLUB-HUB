-- 1. Get the first club ID and the executive user ID
WITH target_club AS (
  SELECT id FROM public.clubs LIMIT 1
),
target_user AS (
  SELECT id FROM public.profiles WHERE role = 'executive' LIMIT 1
)
-- 2. Insert the test user into club_executives for that club
INSERT INTO public.club_executives (club_id, user_id, role_title)
SELECT target_club.id, target_user.id, 'president'
FROM target_club, target_user
ON CONFLICT (club_id, user_id) DO NOTHING;

-- 3. Also update their profile to cache this mapping
WITH target_club AS (
  SELECT id FROM public.clubs LIMIT 1
),
target_user AS (
  SELECT id FROM public.profiles WHERE role = 'executive' LIMIT 1
)
UPDATE public.profiles
SET managed_club_id = (SELECT id FROM target_club)
WHERE id = (SELECT id FROM target_user);
