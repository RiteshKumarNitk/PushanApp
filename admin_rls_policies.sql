-- Enable RLS on key tables if not already enabled
alter table public.tea_orders enable row level security;
alter table public.products enable row level security;
alter table public.users enable row level security;

-- USERS Table
-- Admin can view all users
drop policy if exists "Admins can view all users" on public.users;
create policy "Admins can view all users"
  on public.users for select
  using (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );

-- Admin can update all users (e.g. disable account)
drop policy if exists "Admins can update all users" on public.users;
create policy "Admins can update all users"
  on public.users for update
  using (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );

-- TEA ORDERS Table
-- Admin can view all orders
drop policy if exists "Admins can view all orders" on public.tea_orders;
create policy "Admins can view all orders"
  on public.tea_orders for select
  using (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );

-- Admin can update orders
drop policy if exists "Admins can update all orders" on public.tea_orders;
create policy "Admins can update all orders"
  on public.tea_orders for update
  using (
      exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );


-- PRODUCTS Table
-- Everyone can view products
drop policy if exists "Everyone can view products" on public.products;
create policy "Everyone can view products"
  on public.products for select
  using (true);

-- Only Admin can insert/update/delete products
drop policy if exists "Admins can manage products" on public.products;
create policy "Admins can manage products"
  on public.products for all
  using (
      exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );
