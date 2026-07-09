-- ============================================================================
-- CRITICAL ARCHITECTURAL SAFE-MIGRATION RULE:
-- This script appends new definitions inside a separate, versioned migration file.
-- Historical tables and queries are preserved intact without destructive edits.
-- ============================================================================

-- 1. Create Audit Logs Table for tracking administrative actions
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    actor_name TEXT NOT NULL,
    action_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'audit_logs' AND policyname = 'Super admins can read audit logs'
    ) THEN
        CREATE POLICY "Super admins can read audit logs"
        ON public.audit_logs FOR SELECT
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
            )
        );
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'audit_logs' AND policyname = 'Authenticated users can insert audit logs'
    ) THEN
        CREATE POLICY "Authenticated users can insert audit logs"
        ON public.audit_logs FOR INSERT
        TO authenticated
        WITH CHECK (true);
    END IF;
END $$;

-- 2. Create Financial Transactions Table
CREATE TABLE IF NOT EXISTS public.financial_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    transaction_type TEXT CHECK (transaction_type IN ('credit', 'debit')) NOT NULL,
    purpose TEXT NOT NULL,
    processed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'financial_transactions' AND policyname = 'Super admins can manage financial transactions'
    ) THEN
        CREATE POLICY "Super admins can manage financial transactions"
        ON public.financial_transactions FOR ALL
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
            )
        );
    END IF;
END $$;

-- 3. Create Admin Broadcast Notifications Table
CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    target_audience TEXT NOT NULL DEFAULT 'All',
    notification_type TEXT CHECK (notification_type IN ('Announcement', 'Reminder', 'Warning', 'Information')) DEFAULT 'Announcement',
    sent_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'admin_notifications' AND policyname = 'Anyone can read notifications'
    ) THEN
        CREATE POLICY "Anyone can read notifications"
        ON public.admin_notifications FOR SELECT
        TO authenticated
        USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'admin_notifications' AND policyname = 'Super admins can insert notifications'
    ) THEN
        CREATE POLICY "Super admins can insert notifications"
        ON public.admin_notifications FOR INSERT
        TO authenticated
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
            )
        );
    END IF;
END $$;

-- 4. RPC Stored Procedure for Aggregated Dashboard Statistics
CREATE OR REPLACE FUNCTION public.get_admin_analytics_v4()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    total_students_count INT;
    active_clubs_count INT;
    total_events_count INT;
    pending_reports_count INT;
    active_members_count INT;
    total_executives_count INT;
    total_posts_count INT;
BEGIN
    SELECT COUNT(*) INTO total_students_count FROM public.profiles;
    SELECT COUNT(*) INTO active_clubs_count FROM public.clubs;
    SELECT COUNT(*) INTO total_events_count FROM public.events;
    SELECT COUNT(*) INTO pending_reports_count FROM public.content_reports WHERE status = 'pending';
    SELECT COUNT(*) INTO active_members_count FROM public.profiles WHERE updated_at >= (NOW() - INTERVAL '30 minutes');
    SELECT COUNT(*) INTO total_executives_count FROM public.profiles WHERE role IN ('Executive', 'super_admin');
    SELECT COUNT(*) INTO total_posts_count FROM public.club_posts;

    RETURN jsonb_build_object(
        'total_students', COALESCE(total_students_count, 0),
        'active_clubs', COALESCE(active_clubs_count, 0),
        'total_events', COALESCE(total_events_count, 0),
        'pending_reports', COALESCE(pending_reports_count, 0),
        'active_members', COALESCE(active_members_count, 0),
        'total_executives', COALESCE(total_executives_count, 0),
        'total_posts', COALESCE(total_posts_count, 0)
    );
END;
$$;
