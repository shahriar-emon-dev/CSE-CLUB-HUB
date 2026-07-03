-- ============================================================================
-- Migration: 29_fix_clubs_schema_cache.sql
-- Description: Ensures the color_hex column exists and forces PostgREST to 
--              reload the schema cache to prevent PGRST204 errors.
-- ============================================================================

-- Step 1: Ensure the column actually exists on the table
ALTER TABLE public.clubs ADD COLUMN IF NOT EXISTS color_hex TEXT;

-- Step 2: Force Supabase (PostgREST) to reload its schema cache
-- This is critical when columns are added but the API fails to recognize them
NOTIFY pgrst, 'reload schema';
