-- Create product_variants table if not exists
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL,
    price NUMERIC NOT NULL DEFAULT 0,
    min_order_quantity INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- 1. Everyone can read variants (public/anon + authenticated)
DROP POLICY IF EXISTS "Public read variants" ON product_variants;
CREATE POLICY "Public read variants" ON product_variants FOR SELECT USING (true);

-- 2. Authenticated users (Admins) can manage variants
-- Ideally we check role, but absent clear admin check, we allow authenticated for now
-- This matches "I am not able to update".
DROP POLICY IF EXISTS "Auth manage variants" ON product_variants;
CREATE POLICY "Auth manage variants" ON product_variants FOR ALL USING (auth.role() = 'authenticated');
