-- Fix Infinite Recursion in RLS

-- 1. Create a secure function to check admin status
-- SECURITY DEFINER forces this function to run with the privileges of the creator 
-- (superuser/admin), effectively bypassing RLS on the 'public.users' table
-- preventing the infinite loop.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update Policies for USERS table
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (
    public.is_admin() OR auth.uid() = id -- User can see themselves, OR admin can see all
  );

DROP POLICY IF EXISTS "Admins can update all users" ON public.users;
CREATE POLICY "Admins can update all users"
  ON public.users FOR UPDATE
  USING (
    public.is_admin()
  );

-- 3. Update Policies for TEA ORDERS table (Good practice to use the function)
DROP POLICY IF EXISTS "Admins can view all orders" ON public.tea_orders;
CREATE POLICY "Admins can view all orders"
  ON public.tea_orders FOR SELECT
  USING (
    public.is_admin() OR auth.uid() = user_id -- Users see own orders, Admin sees all
  );

DROP POLICY IF EXISTS "Admins can update all orders" ON public.tea_orders;
CREATE POLICY "Admins can update all orders"
  ON public.tea_orders FOR UPDATE
  USING (
    public.is_admin()
  );

-- 4. Update Policies for PRODUCTS table
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
CREATE POLICY "Admins can manage products"
  ON public.products FOR ALL
  USING (
    public.is_admin()
  );
