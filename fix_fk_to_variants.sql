-- Fix Foreign Key to point to product_variants
-- This is required because we are ordering specific variants (by ID), not generic products.

-- 1. Truncate tea_order_items to remove invalid references (Clean slate)
TRUNCATE TABLE tea_order_items CASCADE;
TRUNCATE TABLE tea_orders CASCADE;

-- 2. Drop old constraint referencing 'products'
ALTER TABLE tea_order_items 
DROP CONSTRAINT IF EXISTS tea_order_items_product_id_fkey;

-- 3. Add new constraint referencing 'product_variants'
ALTER TABLE tea_order_items 
ADD CONSTRAINT tea_order_items_variant_id_fkey 
FOREIGN KEY (product_id) 
REFERENCES product_variants(id) 
ON DELETE CASCADE;
