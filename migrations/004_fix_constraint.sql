-- Attempt to fix the constraint on tea_orders
-- This confirms if the table exists and resets the constraint to be sure
ALTER TABLE tea_orders DROP CONSTRAINT IF EXISTS tea_orders_status_check;

ALTER TABLE tea_orders ADD CONSTRAINT tea_orders_status_check 
CHECK (status IN ('placed', 'in_progress', 'delivered'));
