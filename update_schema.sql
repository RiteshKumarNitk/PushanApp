-- 1. Create Announcements Table
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Announcements are viewable by everyone" 
ON announcements FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage announcements" 
ON announcements FOR ALL 
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));

-- 2. Ensure Users Table has necessary columns for Address/Profile
-- We use DO block to add columns safely only if they don't exist

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'address') THEN
        ALTER TABLE users ADD COLUMN address TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'gst_number') THEN
        ALTER TABLE users ADD COLUMN gst_number TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'phone_number') THEN
        ALTER TABLE users ADD COLUMN phone_number TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'business_name') THEN
        ALTER TABLE users ADD COLUMN business_name TEXT;
    END IF;
END $$;
