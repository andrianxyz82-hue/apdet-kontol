-- ============================================
-- SUPABASE SQL SCRIPT: CBT URL STORAGE
-- ============================================
-- This script creates a table to store system settings
-- including the CBT URL that teachers can configure
-- ============================================

-- Create system_settings table
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on key for faster lookups
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);

-- Insert default CBT URL (optional)
INSERT INTO system_settings (key, value, description)
VALUES (
    'cbt_url',
    'https://google.com',
    'URL for Computer Based Test (CBT) system'
)
ON CONFLICT (key) DO NOTHING;

-- Enable Row Level Security (RLS)
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Allow teachers to read and update settings
CREATE POLICY "Teachers can read system settings"
    ON system_settings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.uid() = id
            AND raw_user_meta_data->>'role' = 'teacher'
        )
    );

CREATE POLICY "Teachers can update system settings"
    ON system_settings
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.uid() = id
            AND raw_user_meta_data->>'role' = 'teacher'
        )
    );

-- Policy: Allow students to read CBT URL only
CREATE POLICY "Students can read CBT URL"
    ON system_settings
    FOR SELECT
    USING (
        key = 'cbt_url' AND
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.uid() = id
            AND raw_user_meta_data->>'role' = 'student'
        )
    );

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_system_settings_updated_at ON system_settings;
CREATE TRIGGER update_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- USAGE INSTRUCTIONS:
-- ============================================
-- 1. Copy this entire script
-- 2. Go to Supabase Dashboard > SQL Editor
-- 3. Paste and run the script
-- 4. Verify the table was created in Table Editor
-- ============================================
