-- Drop ALL existing versions of place_order to avoid signature mismatches
DO $$ 
DECLARE 
    r RECORD; 
BEGIN 
    FOR r IN SELECT oid::regprocedure AS func_signature FROM pg_proc WHERE proname = 'place_order' 
    LOOP 
        EXECUTE 'DROP FUNCTION ' || r.func_signature || ' CASCADE'; 
    END LOOP; 
END $$;

-- Re-create the function with 'placed' status
CREATE OR REPLACE FUNCTION place_order(
  p_total_amount FLOAT,
  p_admin_notes TEXT,
  p_shipping_address JSONB,
  p_items JSONB,
  p_coins_to_redeem INT,
  p_coupon_code TEXT DEFAULT NULL,
  p_discount_amount FLOAT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order_id UUID;
  v_item_record RECORD;
BEGIN
  -- Insert into tea_orders with 'placed' status (Enforcing correct status)
  INSERT INTO tea_orders (user_id, total_amount, status, admin_notes, shipping_address, discount_amount, coupon_code)
  VALUES (auth.uid(), p_total_amount, 'placed', p_admin_notes, p_shipping_address, p_discount_amount, p_coupon_code)
  RETURNING id INTO v_order_id;

  -- Items Loop
  FOR v_item_record IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO tea_order_items (order_id, product_id, quantity, unit_price)
    VALUES (
      v_order_id,
      (v_item_record.value->>'product_id')::UUID,
      (v_item_record.value->>'quantity')::INT,
      (v_item_record.value->>'unit_price')::FLOAT
    );
  END LOOP;

  -- Deduct Supercoins if used
  IF p_coins_to_redeem > 0 THEN
      UPDATE users 
      SET supercoins = supercoins - p_coins_to_redeem 
      WHERE id = auth.uid();
      
      INSERT INTO supercoin_history (user_id, amount, description)
      VALUES (auth.uid(), -p_coins_to_redeem, 'Used for Order #' || substring(v_order_id::text, 1, 8)); 
  END IF;
  
  -- Add Notification
  INSERT INTO notifications (user_id, title, message, type, related_id)
  VALUES (auth.uid(), 'Order Placed', 'Your order #' || substring(v_order_id::text, 1, 8) || ' has been placed successfully.', 'order_placed', v_order_id);

  RETURN json_build_object('id', v_order_id, 'status', 'success');
END;
$$;
