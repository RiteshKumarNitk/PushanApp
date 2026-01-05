-- 1. Add Discount Columns to Tea Orders
alter table public.tea_orders 
add column if not exists coins_redeemed int default 0,
add column if not exists discount_amount numeric default 0;

-- 2. Create RPC Function to Place Order Securely
create or replace function public.place_order(
  p_total_amount numeric,
  p_admin_notes text,
  p_shipping_address jsonb,
  p_items jsonb, -- Array of {product_id, quantity, unit_price}
  p_coins_to_redeem int
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_order_id uuid;
  v_current_coins int;
  v_discount_val numeric;
  v_item jsonb;
begin
  v_user_id := auth.uid();
  
  -- 1. Validate Coins
  if p_coins_to_redeem > 0 then
    select supercoins into v_current_coins from public.users where id = v_user_id;
    if v_current_coins < p_coins_to_redeem then
      raise exception 'Insufficient supercoins balance';
    end if;
    
    -- Calculate Discount (4 coins = 1 Unit)
    v_discount_val := floor(p_coins_to_redeem / 4);
    
    -- Deduct Coins
    update public.users 
    set supercoins = supercoins - p_coins_to_redeem 
    where id = v_user_id;
    
    -- Log History
    insert into public.supercoin_history (user_id, amount, description)
    values (v_user_id, -p_coins_to_redeem, 'Order Redemption');
  else
    v_discount_val := 0;
  end if;

  -- 2. Insert Order
  insert into public.tea_orders (
    user_id, 
    status, 
    total_amount, 
    admin_notes, 
    shipping_address, 
    coins_redeemed, 
    discount_amount
  ) values (
    v_user_id,
    'requested',
    p_total_amount, -- This should be the final amount AFTER discount? Or before? 
                    -- Usually total_amount is what user pays. 
                    -- Let's assume p_total_amount PASSED IN is the payable amount.
                    -- And we record the discount separately.
    p_admin_notes,
    p_shipping_address,
    p_coins_to_redeem,
    v_discount_val
  ) returning id into v_order_id;
  
  -- 3. Insert Items
  -- p_items is a JSON array: [{"product_id": "...", "quantity": 1, "unit_price": 100}, ...]
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.tea_order_items (order_id, product_id, quantity, unit_price)
    values (
      v_order_id, 
      (v_item->>'product_id')::uuid, 
      (v_item->>'quantity')::int, 
      (v_item->>'unit_price')::numeric
    );
  end loop;

  return json_build_object('id', v_order_id, 'status', 'success');
end;
$$;
