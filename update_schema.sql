-- 1. Create User Addresses Table
create table if not exists public.user_addresses (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  label text not null, -- e.g., "Home", "Office"
  address_line text not null,
  city text not null,
  state text not null,
  zip_code text,
  is_default boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for user_addresses
alter table public.user_addresses enable row level security;

drop policy if exists "Users can view their own addresses" on public.user_addresses;
create policy "Users can view their own addresses"
  on public.user_addresses for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own addresses" on public.user_addresses;
create policy "Users can insert their own addresses"
  on public.user_addresses for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own addresses" on public.user_addresses;
create policy "Users can update their own addresses"
  on public.user_addresses for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete their own addresses" on public.user_addresses;
create policy "Users can delete their own addresses"
  on public.user_addresses for delete
  using (auth.uid() = user_id);


-- 2. Modify Tea Orders Table
-- Add shipping_address column to store a snapshot of the address at the time of order
alter table public.tea_orders 
add column if not exists shipping_address jsonb;


-- 3. Create Notifications Table
create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  title text not null,
  message text not null,
  type text default 'info', -- 'order_update', 'promo', etc.
  related_id text, -- e.g., Order ID
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for notifications
alter table public.notifications enable row level security;

drop policy if exists "Users can view their own notifications" on public.notifications;
create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

-- Only service role or admin functions should probably insert, but for now allow users (if triggered by client logic secured by RLS) 
-- OR better: generic insert policy if the user_id matches.
drop policy if exists "Users can insert notifications (for testing/admin client)" on public.notifications;
create policy "Users can insert notifications (for testing/admin client)" 
  on public.notifications for insert
  with check (auth.uid() = user_id or exists (
    select 1 from public.users 
    where id = auth.uid() and role = 'admin'
  ));

drop policy if exists "Admins can insert notifications for others" on public.notifications;
create policy "Admins can insert notifications for others"
  on public.notifications for insert
  with check ( exists (
    select 1 from public.users 
    where id = auth.uid() and role = 'admin'
  ));

drop policy if exists "Users can update their own notifications (mark as read)" on public.notifications;
create policy "Users can update their own notifications (mark as read)"
  on public.notifications for update
  using (auth.uid() = user_id);
