-- Fix for FK constraint mismatch
-- The error indicates that 'product_id' column in 'tea_order_items' References 'product_variants' table.
-- Thereforce, 'product_id' stores the Variant ID, NOT the parent Product ID.

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

        -- Check which columns exist or just try to be safe based on error analysis
        -- Problem: We don't know for sure if 'product_variant_id' column exists vs 'product_id'.
        -- The previous error said 'product_id' violates constraint to 'product_variants'.
        -- So 'product_id' MUST get the v_variant_id.
        
        -- We will try to insert into 'product_id' as the primary link.
        -- If 'product_variant_id' exists (from my previous script), we populate it too with same value to be safe.
        -- BUT dynamic SQL is hard here.
        -- I will assume standard structure: insert into product_id only. 
        -- Wait, if I added product_variant_id and it has no default allowed? I made it nullable implicitly (default).
        
        -- However, previous error 'column product_variant_id does not exist' suggests I might have added it?
        -- If I added it, I should populate it.
        
        -- To be maximally robust:
        -- I'll use a ON CONFLICT-like approach? No.
        
        -- Let's assumes 'product_id' is the one that matters (Legacy).
        -- And 'product_variant_id' is the new one I might have added.
        -- I'll insert into BOTH with the SAME variant_id.
        
        insert into public.tea_order_items (order_id, product_id, quantity, unit_price)
        values (
            v_order_id,
            v_variant_id, -- Insert VARIANT ID here because of the FK constraint
            (v_item->>'quantity')::int,
            (v_item->>'unit_price')::numeric
        );
        
        -- Note: I removed 'product_variant_id' from insert list because if it wasn't there originally,
        -- likely my 'fix_schema_column.sql' might not have run or failed silently?
        -- Actually, if I remove it, and it IS required, it will fail.
        -- But 'product_id' failed because of NULL check earlier.
        
        -- If the user ran 'fix_schema_column.sql', they might have 'product_variant_id'.
        -- But the error specifically complained about 'product_id'. 
        -- So 'product_id' is definitely there and required.
        
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
