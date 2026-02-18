-- Allow ALL Inserts for Authenticated Users (Fixes 42501 RLS Error)
DROP POLICY IF EXISTS "Auth insert variants" ON product_variants;
CREATE POLICY "Auth insert variants" ON product_variants FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow ALL Updates for Authenticated Users
DROP POLICY IF EXISTS "Auth update variants" ON product_variants;
CREATE POLICY "Auth update variants" ON product_variants FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow ALL Deletes for Authenticated Users
DROP POLICY IF EXISTS "Auth delete variants" ON product_variants;
CREATE POLICY "Auth delete variants" ON product_variants FOR DELETE USING (auth.role() = 'authenticated');

-- Also check PRODUCTS table policies (in case you are updating product too)
DROP POLICY IF EXISTS "Auth manage products" ON products;
CREATE POLICY "Auth manage products" ON products FOR ALL USING (auth.role() = 'authenticated');
