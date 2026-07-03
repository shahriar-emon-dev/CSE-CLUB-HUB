-- ============================================================================
-- Migration: 07_add_clubs.sql (Revised)
-- Description: Alters existing clubs table to add new UI fields and creates views.
-- ============================================================================

-- Add new columns if they don't exist
ALTER TABLE public.clubs 
ADD COLUMN IF NOT EXISTS slug TEXT,
ADD COLUMN IF NOT EXISTS icon_name TEXT,
ADD COLUMN IF NOT EXISTS color_hex TEXT;

-- Safely populate the slug for existing clubs
UPDATE public.clubs 
SET slug = lower(regexp_replace(name, '[^a-zA-Z0-9]+', '_', 'g')) 
WHERE slug IS NULL;

-- Make slug unique and NOT NULL (do this in a separate block to avoid errors if already done)
DO $$
BEGIN
    BEGIN
        ALTER TABLE public.clubs ALTER COLUMN slug SET NOT NULL;
        ALTER TABLE public.clubs ADD CONSTRAINT clubs_slug_key UNIQUE (slug);
    EXCEPTION
        WHEN others THEN NULL;
    END;
END $$;

-- Update existing clubs with icons/colors so UI looks good
UPDATE public.clubs SET icon_name = 'psychology', color_hex = '#FFC107' WHERE name LIKE '%Machine%';
UPDATE public.clubs SET icon_name = 'terminal', color_hex = '#E040FB' WHERE name LIKE '%Programming%';
UPDATE public.clubs SET icon_name = 'memory', color_hex = '#2196F3' WHERE name LIKE '%Robotics%';
UPDATE public.clubs SET icon_name = 'brush', color_hex = '#18FFFF' WHERE name LIKE '%Web%';
UPDATE public.clubs SET icon_name = 'developer_board', color_hex = '#69F0AE' WHERE name LIKE '%Software%';
UPDATE public.clubs SET icon_name = 'admin_panel_settings', color_hex = '#448AFF' WHERE name LIKE '%Security%';

-- ==========================================
-- VIEWS
-- ==========================================
CREATE OR REPLACE VIEW public.club_list_view AS
SELECT 
    c.*,
    (SELECT count(*) FROM public.club_followers cf WHERE cf.club_id = c.id) +
    (SELECT count(*) FROM public.club_executives ce WHERE ce.club_id = c.id) as member_count
FROM public.clubs c;

-- View is accessible publicly
GRANT SELECT ON public.club_list_view TO anon, authenticated;
