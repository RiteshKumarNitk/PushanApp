-- Create Coupons table
create table if not exists public.coupons (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  discount_percent integer not null, -- e.g., 20
  description text,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.coupons enable row level security;

-- Policies
drop policy if exists "Admin manages coupons" on public.coupons;
create policy "Admin manages coupons" on public.coupons
  for all using (
    exists (select 1 from public.users where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Users read active coupons" on public.coupons;
create policy "Users read active coupons" on public.coupons
  for select using ( is_active = true );

-- Insert default coupons
insert into public.coupons (code, discount_percent, description)
values 
  ('TEA20', 20, '20% Off Standard Coupon'),
  ('WELCOME20', 20, 'Welcome Offer')
on conflict (code) do nothing;
