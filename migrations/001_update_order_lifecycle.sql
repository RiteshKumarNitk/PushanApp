-- Migration script to update order lifecycle

-- 1. Migrate Existing Data to new statuses
-- 'requested' -> 'placed'
UPDATE tea_orders 
SET status = 'placed' 
WHERE status = 'requested';

-- 'approved', 'packed', 'shipped' -> 'in_progress'
UPDATE tea_orders 
SET status = 'in_progress' 
WHERE status IN ('approved', 'packed', 'shipped');

-- 'delivered' remains 'delivered'

-- Handle 'rejected' or others -> 'placed' or handle specially? 
-- Assuming remaining are irrelevant or should be 'placed'
UPDATE tea_orders 
SET status = 'placed' 
WHERE status NOT IN ('placed', 'in_progress', 'delivered');

-- 2. Update Constraint
-- Drop old check constraint if it exists (name might vary, assuming tea_orders_status_check)
ALTER TABLE tea_orders DROP CONSTRAINT IF EXISTS tea_orders_status_check;

-- Add new constraint
ALTER TABLE tea_orders ADD CONSTRAINT tea_orders_status_check 
CHECK (status IN ('placed', 'in_progress', 'delivered')); -- 3 allowed statuses
