-- Fix for PGRST201: Ambiguous relationship
-- We accidentally created a second FK to product_variants.
-- Since 'product_id' is the canonical column (legacy), we should drop the 'product_variant_id' column we added.

alter table public.tea_order_items 
drop column if exists product_variant_id;

-- Also verify if there are other ambiguous columns and clean up
-- Ensure 'product_id' is the only one pointing to product_variants
