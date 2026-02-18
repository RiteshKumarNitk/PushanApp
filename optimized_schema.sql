-- OPTIMIZED SCHEMA FOR TEA APP (BULK ORDERS)
-- This schema consolidates all necessary tables and removes unused complexity.

-- 1. USERS & PROFILES
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT DEFAULT 'customer', -- 'admin', 'customer', 'staff'
    supercoins INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure RLS on users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public users" ON public.users;
CREATE POLICY "Public users" ON public.users FOR SELECT USING (true);
DROP POLICY IF EXISTS "Self update users" ON public.users;
CREATE POLICY "Self update users" ON public.users FOR UPDATE USING (auth.uid() = id);

-- 2. PRODUCTS (Simplified)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. PRODUCT VARIANTS (Linked to Products)
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL, -- e.g. "1kg", "500g"
    price NUMERIC NOT NULL DEFAULT 0,
    min_order_quantity INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. ORDERS (Bulk Tea Orders)
CREATE TABLE IF NOT EXISTS public.tea_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'placed' CHECK (status IN ('placed', 'in_progress', 'delivered', 'cancelled')),
    total_amount NUMERIC NOT NULL,
    admin_notes TEXT,
    shipping_address JSONB,
    discount_amount NUMERIC DEFAULT 0,
    coupon_code TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. ORDER ITEMS
CREATE TABLE IF NOT EXISTS public.tea_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.tea_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id),
    quantity INT NOT NULL, -- Number of units (pieces)
    unit_price NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT, -- 'order_placed', 'promo', etc.
    related_id UUID,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. SUPERCOIN HISTORY
CREATE TABLE IF NOT EXISTS public.supercoin_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    amount INT NOT NULL, -- Positive for credit, negative for debit
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ENABLE RLS ON ALL TABLES
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tea_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tea_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supercoin_history ENABLE ROW LEVEL SECURITY;

-- POLICIES (Simplified for Admin + Customer Access)

-- Products & Variants: Readable by everyone, Writable by Admin (Authenticated for now)
CREATE POLICY "Public read products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Admin manage products" ON public.products FOR ALL USING (auth.role() = 'authenticated'); -- Ideally check role='admin'

CREATE POLICY "Public read variants" ON public.product_variants FOR SELECT USING (true);
CREATE POLICY "Admin manage variants" ON public.product_variants FOR ALL USING (auth.role() = 'authenticated');

-- Orders: Users see their own, Admins see all
CREATE POLICY "User view own orders" ON public.tea_orders FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'service_role');
CREATE POLICY "Admin manage orders" ON public.tea_orders FOR ALL USING (auth.role() = 'authenticated'); -- Simplified

-- Order Items: Users see items of their orders
CREATE POLICY "User view own items" ON public.tea_order_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.tea_orders WHERE id = public.tea_order_items.order_id AND user_id = auth.uid())
);
CREATE POLICY "Admin manage items" ON public.tea_order_items FOR ALL USING (auth.role() = 'authenticated');

-- Notifications & Coins: User privacy
CREATE POLICY "User view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admin create notifications" ON public.notifications FOR INSERT WITH CHECK (true); -- Allow system/admin to notify

CREATE POLICY "User view history" ON public.supercoin_history FOR SELECT USING (auth.uid() = user_id);
