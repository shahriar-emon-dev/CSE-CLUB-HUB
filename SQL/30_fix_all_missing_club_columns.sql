-- ============================================================================
-- Migration: 30_fix_all_missing_club_columns.sql
-- Description: Ensures all appearance columns (icon_name, color_hex, slug)
--              exist on the clubs table and forcefully reloads PostgREST.
-- ============================================================================

-- Step 1: Ensure all required columns exist on the table
ALTER TABLE public.clubs 
ADD COLUMN IF NOT EXISTS slug TEXT,
ADD COLUMN IF NOT EXISTS icon_name TEXT,
ADD COLUMN IF NOT EXISTS color_hex TEXT;

-- Step 2: Force Supabase (PostgREST) to reload its schema cache
NOTIFY pgrst, 'reload schema';
