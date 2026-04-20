-- ==========================================
-- FINALIZE EXPANDABLE CLUBS (POST STRICT-SEED OVERRIDE)
-- ==========================================
-- Why this migration exists:
-- A prior strict-seed migration may re-add clubs_name_srs_allowed_check.
-- This migration guarantees final expandable-club behavior.

alter table public.clubs
  drop constraint if exists clubs_name_srs_allowed_check;

-- Keep authenticated read policy naming aligned with behavior.
drop policy if exists "Anyone can read active clubs" on public.clubs;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'clubs'
      and policyname = 'Authenticated users can read active clubs'
  ) then
    create policy "Authenticated users can read active clubs"
    on public.clubs
    for select
    to authenticated
    using (is_active = true);
  end if;
end $$;
