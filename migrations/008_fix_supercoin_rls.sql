-- Fix RLS for supercoin_history to allow Admins to manage it

-- 1. Enable RLS
DO $$ 
BEGIN
  ALTER TABLE supercoin_history ENABLE ROW LEVEL SECURITY;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- 2. Allow Admins to INSERT
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Admins can insert supercoin_history" ON supercoin_history;
    CREATE POLICY "Admins can insert supercoin_history"
    ON supercoin_history FOR INSERT
    TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'admin'
      )
    );
END $$;

-- 3. Allow Admins to SELECT
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Admins can select supercoin_history" ON supercoin_history;
    CREATE POLICY "Admins can select supercoin_history"
    ON supercoin_history FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'admin'
      )
    );
END $$;

-- 4. Allow Admins to UPDATE
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Admins can update supercoin_history" ON supercoin_history;
    CREATE POLICY "Admins can update supercoin_history"
    ON supercoin_history FOR UPDATE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'admin'
      )
    );
END $$;

-- 5. Default user visibility
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can see own history" ON supercoin_history;
    CREATE POLICY "Users can see own history"
    ON supercoin_history FOR SELECT
    TO authenticated
    USING (
      user_id = auth.uid()
    );
END $$;
