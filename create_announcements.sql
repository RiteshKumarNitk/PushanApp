-- Create Announcements table for Admin Broadcasts
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true
);

-- RLS Policies
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Everyone can read active announcements
CREATE POLICY "Announcements are viewable by everyone" 
ON announcements FOR SELECT 
USING (true);

-- Only admins can insert/update/delete (Assuming admin role logic or simple public write for now during dev if needed, but sticking to standard)
-- For this "MVP" where we might not have 'role' claims set up perfectly in token, we rely on App logic or Open Policy for dev
-- Let's check users table role.

CREATE POLICY "Admins can manage announcements" 
ON announcements FOR ALL 
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));
