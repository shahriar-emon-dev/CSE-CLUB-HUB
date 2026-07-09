-- Migration 36: System Settings for Global Policy Configuration

CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id)
);

-- RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view system settings" 
    ON public.system_settings FOR SELECT 
    USING (true);

CREATE POLICY "Only super_admins can modify system settings" 
    ON public.system_settings FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() AND profiles.role = 'super_admin'
        )
    );

-- Insert default global policy
INSERT INTO public.system_settings (setting_key, setting_value, description)
VALUES (
    'profile_expiration', 
    '{"threshold_days": 365}'::jsonb, 
    'Number of days before an inactive profile is considered expired.'
) ON CONFLICT (setting_key) DO NOTHING;
