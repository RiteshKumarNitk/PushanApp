-- Add coupon columns to tea_orders if not exists
alter table public.tea_orders 
add column if not exists coupon_code text,
add column if not exists discount_amount numeric default 0;

-- Drop old function signatures to prevent ambiguity
drop function if exists public.place_order(numeric, text, jsonb, jsonb, integer);
-- Drop the new one too just to be sure we are replacing it cleanly
drop function if exists public.place_order(numeric, text, jsonb, jsonb, integer, text, numeric);

-- Create the robust function
create or replace function public.place_order(
    p_total_amount numeric,
    p_admin_notes text,
    p_shipping_address jsonb,
    p_items jsonb,
    p_coins_to_redeem integer,
    p_coupon_code text default null,
    p_discount_amount numeric default 0
)
returns uuid
language plpgsql
security definer
as $$
declare
    v_order_id uuid;
    v_item jsonb;
    v_user_id uuid;
begin
    v_user_id := auth.uid();

    -- Insert Order with coupon details
    insert into public.tea_orders (
        user_id, 
        total_amount, 
        status, 
        admin_notes, 
        shipping_address,
        coupon_code,
        discount_amount
    )
    values (
        v_user_id, 
        p_total_amount, 
        'requested', 
        p_admin_notes, 
        p_shipping_address,
        p_coupon_code,
        p_discount_amount
    )
    returning id into v_order_id;

    -- Insert Order Items
    for v_item in select * from jsonb_array_elements(p_items)
    loop
        insert into public.tea_order_items (order_id, product_variant_id, quantity, unit_price)
        values (
            v_order_id,
            (v_item->>'product_id')::uuid,
            (v_item->>'quantity')::int,
            (v_item->>'unit_price')::numeric
        );
    end loop;

    -- Handle Supercoins
    if p_coins_to_redeem > 0 then
        -- Deduct coins
        update public.users_profile
        set supercoins = supercoins - p_coins_to_redeem
        where id = v_user_id;
    end if;

    return v_order_id;
end;
$$;
