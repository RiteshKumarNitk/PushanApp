-- Fix for "column product_variant_id does not exist"

-- 1. Check if 'variant_id' exists and rename it to 'product_variant_id'
do $$
begin
  if exists(select 1 from information_schema.columns where table_name = 'tea_order_items' and column_name = 'variant_id') then
    alter table public.tea_order_items rename column variant_id to product_variant_id;
  elsif not exists(select 1 from information_schema.columns where table_name = 'tea_order_items' and column_name = 'product_variant_id') then
    -- If neither exists, add product_variant_id
    alter table public.tea_order_items add column product_variant_id uuid references public.product_variants(id);
  end if;
end $$;

-- 2. Validate proper Foreign Key constraints (optional but good)
-- alter table public.tea_order_items drop constraint if exists tea_order_items_product_variant_id_fkey;
-- alter table public.tea_order_items add constraint tea_order_items_product_variant_id_fkey foreign key (product_variant_id) references public.product_variants(id);
