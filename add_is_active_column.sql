-- Add is_active column to users table if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Update existing users to be active by default
UPDATE public.users 
SET is_active = true 
WHERE is_active IS NULL;

-- Create policy to potentially restrict disabled users (Optional, but good practice)
-- For now, we just want the admin to be able to TOGGLE it.
-- The Auth logic needs to check this on login, but that might be a trigger or app-side check.
-- Let's just add the column for now.
