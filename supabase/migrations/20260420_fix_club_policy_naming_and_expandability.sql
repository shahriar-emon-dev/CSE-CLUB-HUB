-- ==========================================
-- FIX #1 + #9: EXPANDABLE CLUBS + POLICY NAMING
-- ==========================================
-- Goals:
-- 1) Allow adding clubs beyond the initial six.
-- 2) Keep reads authenticated and rename policy to match scope.
-- 3) Admin-only create/update/delete for clubs.

-- Remove strict six-club constraint if present.
alter table public.clubs
  drop constraint if exists clubs_name_srs_allowed_check;

alter table public.clubs enable row level security;

-- Rename/replace read policy to accurately reflect actual scope.
drop policy if exists "Anyone can read active clubs" on public.clubs;
drop policy if exists "Authenticated users can read active clubs" on public.clubs;

create policy "Authenticated users can read active clubs"
on public.clubs
for select
to authenticated
using (is_active = true);

-- Admin-only club management (expandable model with governed writes).
drop policy if exists "Admins can create clubs" on public.clubs;
drop policy if exists "Admins can update clubs" on public.clubs;
drop policy if exists "Admins can delete clubs" on public.clubs;

create policy "Admins can create clubs"
on public.clubs
for insert
to authenticated
with check (public.is_admin(auth.uid()));

create policy "Admins can update clubs"
on public.clubs
for update
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

create policy "Admins can delete clubs"
on public.clubs
for delete
to authenticated
using (public.is_admin(auth.uid()));
