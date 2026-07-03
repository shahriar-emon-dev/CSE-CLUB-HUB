-- Run this to fix the missing is_club_executive function
CREATE OR REPLACE FUNCTION public.is_club_executive(club_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.club_executives
    WHERE club_id = club_uuid
      AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;
