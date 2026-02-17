-- 1. Create tea_orders table
CREATE TABLE IF NOT EXISTS tea_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'placed',
    total_amount NUMERIC NOT NULL,
    admin_notes TEXT,
    shipping_address JSONB,
    discount_amount NUMERIC DEFAULT 0,
    coupon_code TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT tea_orders_status_check CHECK (status IN ('placed', 'in_progress', 'delivered'))
);

-- 2. Create tea_order_items table
CREATE TABLE IF NOT EXISTS tea_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES tea_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity INT NOT NULL,
    unit_price NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Enable Security (RLS)
ALTER TABLE tea_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE tea_order_items ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ 
BEGIN
    -- Drop existing policies to avoid errors on run
    DROP POLICY IF EXISTS "Users can view own orders" ON tea_orders;
    DROP POLICY IF EXISTS "Users can view own order items" ON tea_order_items;
END $$;

CREATE POLICY "Users can view own orders" ON tea_orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own order items" ON tea_order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM tea_orders 
            WHERE tea_orders.id = tea_order_items.order_id 
            AND tea_orders.user_id = auth.uid()
        )
    );

-- 4. Re-establish the place_order function
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
  -- Insert into tea_orders
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
