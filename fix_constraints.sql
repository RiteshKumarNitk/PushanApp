-- Fix Constraints
-- 1. Drop the existing strict Foreign Key constraint
ALTER TABLE tea_order_items 
DROP CONSTRAINT IF EXISTS tea_order_items_product_id_fkey;

-- 2. Re-add the constraint with ON DELETE CASCADE
-- This allows you to delete a Product, and all its Order Items will be automatically deleted.
ALTER TABLE tea_order_items 
ADD CONSTRAINT tea_order_items_product_id_fkey 
FOREIGN KEY (product_id) 
REFERENCES products(id) 
ON DELETE CASCADE;
