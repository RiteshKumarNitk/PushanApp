-- Create Product Variants Table and Clean up
-- Note: We are not deleting 'price_per_unit' etc from products immediately to prevent data loss, 
-- but we will stop using them in the new app code.

create table if not exists public.product_variants (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references public.products(id) on delete cascade not null,
  variant_name text not null, -- e.g. "250g", "500g"
  price numeric not null,
  min_order_quantity int default 1
);

-- Enable RLS (optional, matching existing style if any)
-- alter table public.product_variants enable row level security;
-- create policy "Public read" on public.product_variants for select using (true);
