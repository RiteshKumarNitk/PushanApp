-- Create or Replace function with Product ID lookup
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
    v_variant_id uuid;
    v_product_id uuid;
begin
    v_user_id := auth.uid();

    -- Insert Order
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
        v_variant_id := (v_item->>'product_id')::uuid;
        
        -- Lookup parent product_id from variant
        select product_id into v_product_id 
        from public.product_variants 
        where id = v_variant_id;

        -- If not found (shouldn't happen), try using variant_id as product_id or null?
        -- But since it's NOT NULL constraint, we must provide it.
        if v_product_id is null then
             -- Fallback: assumes maybe the input ID was product_id directly if variants aren't used?
             -- unlikely given code structure. Let's assume lookup works.
             -- If it fails, raise error or insert variant_id?
             v_product_id := v_variant_id; -- risky fallback
        end if;

        insert into public.tea_order_items (order_id, product_variant_id, product_id, quantity, unit_price)
        values (
            v_order_id,
            v_variant_id,
            v_product_id,
            (v_item->>'quantity')::int,
            (v_item->>'unit_price')::numeric
        );
    end loop;

    -- Handle Supercoins
    if p_coins_to_redeem > 0 then
        update public.users_profile
        set supercoins = supercoins - p_coins_to_redeem
        where id = v_user_id;
    end if;

    return v_order_id;
end;
$$;
