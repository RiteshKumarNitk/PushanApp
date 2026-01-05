-- 1. Add Supercoins to Users Table
alter table public.users add column if not exists supercoins int default 0;

-- 2. Supercoin Transaction History
create table if not exists public.supercoin_history (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) not null,
  amount int not null, -- positive for earning, negative for spending
  description text,
  order_id uuid references public.tea_orders(id), -- optional link to order
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for supercoin_history
alter table public.supercoin_history enable row level security;

drop policy if exists "Users can view their own supercoin history" on public.supercoin_history;
create policy "Users can view their own supercoin history"
  on public.supercoin_history for select
  using (auth.uid() = user_id);

-- 3. Trigger to Earn Supercoins on Order Delivery
-- Rule: Earn 2% of order total (4 coins = 1 Rs redemption, maybe earning is different? Let's assume 1 coin per 1 Rs spent for now unless specified otherwise, actually 4 coins = 1 rs means coins are worth 0.25. If user wants flipkart style, usually you earn less. Let's make it simple: Earn 1 coin for every 10 Rs spent? Or just manually added?
-- User said: "4 supercoin will be 1 rs based". That is redemption value.
-- I'll assume standard earning: 4 coins per 100rs? (4% back). 
-- Let's stick to a safe default: 4 coins per 100 Rs spent. (1 Re cashback).
-- Actually, let's just create the potential function but maybe handle logic in Edge Function or App for flexibility.
-- But a trigger is more robust.
create or replace function public.earn_supercoins_on_delivery()
returns trigger as $$
begin
  if new.status = 'delivered' and old.status != 'delivered' then
    -- basic logic: 4 coins per 100 units of currency.
    -- (new.total_amount / 100) * 4 => 4% cashback effectively in "coin value"?
    -- Wait, if 4 coins = 1 Rs. Then 4 coins is 0.25 Rs.
    -- If I spend 100 Rs, and I get 4 coins. value is 1 Rs. That is 1% Cashback. Reliable.
    insert into public.users (id, supercoins)
    values (new.user_id, floor(new.total_amount / 25)) -- 4 coins per 100 = 1/25
    on conflict (id) do update
    set supercoins = users.supercoins + floor(new.total_amount / 25);
    
    insert into public.supercoin_history (user_id, amount, description, order_id)
    values (new.user_id, floor(new.total_amount / 25), 'Order Reward', new.id);
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_delivered_reward on public.tea_orders;
create trigger on_order_delivered_reward
  after update on public.tea_orders
  for each row execute function public.earn_supercoins_on_delivery();

-- 4. Verify User Addresses Table (Already exists from previous steps, just in case)
create table if not exists public.user_addresses (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  label text not null, -- e.g. "Home", "Office"
  address_line text not null,
  city text not null,
  state text not null,
  zip_code text,
  is_default boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
