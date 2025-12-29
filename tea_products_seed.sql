-- Seed Products and Variants
-- Updated to use UPSERT (ON CONFLICT DO UPDATE) to avoid duplicate key errors.

-- 1. Amchi Mumbai
INSERT INTO products (id, name, description, category, image_url, is_active, price_per_unit, unit_type, min_order_quantity) VALUES
('a1111111-1111-1111-1111-111111111111', 'Amchi Mumbai', 'Premium Black Tea', 'Tea', 'https://images.unsplash.com/photo-1576092768241-dec231844f74?auto=format&fit=crop&w=800&q=80', true, 0, 'varies', 1)
ON CONFLICT (id) DO UPDATE SET
name = EXCLUDED.name, description = EXCLUDED.description, image_url = EXCLUDED.image_url;

-- Variants for Amchi Mumbai (Delete old variants for this product first to be safe, or upsert them too)
-- Simpler to just UPSERT variants as well.
INSERT INTO product_variants (product_id, variant_name, price) VALUES
('a1111111-1111-1111-1111-111111111111', '250g', 350),
('a1111111-1111-1111-1111-111111111111', '500g', 600),
('a1111111-1111-1111-1111-111111111111', '1Kg (Box)', 1100),
('a1111111-1111-1111-1111-111111111111', '1Kg Pouch', 950)
ON CONFLICT DO NOTHING; -- Assuming no ID collision on variants yet, or we'd need valid IDs for variants to upsert.


-- 2. Rajasthan Royal
INSERT INTO products (id, name, description, category, image_url, is_active, price_per_unit, unit_type, min_order_quantity) VALUES
('b2222222-2222-2222-2222-222222222222', 'Rajasthan Royal', 'Royal Masala Tea', 'Tea', 'https://images.unsplash.com/photo-1563911302283-d2bc129e7c1f?auto=format&fit=crop&w=800&q=80', true, 0, 'varies', 1)
ON CONFLICT (id) DO UPDATE SET
name = EXCLUDED.name, description = EXCLUDED.description, image_url = EXCLUDED.image_url;

INSERT INTO product_variants (product_id, variant_name, price) VALUES
('b2222222-2222-2222-2222-222222222222', '250g', 320),
('b2222222-2222-2222-2222-222222222222', '500g', 590),
('b2222222-2222-2222-2222-222222222222', '1Kg (Box)', 1050),
('b2222222-2222-2222-2222-222222222222', '1Kg Pouch', 900)
ON CONFLICT DO NOTHING;


-- 3. TeaUP Divine
INSERT INTO products (id, name, description, category, image_url, is_active, price_per_unit, unit_type, min_order_quantity) VALUES
('c3333333-3333-3333-3333-333333333333', 'TeaUP Divine', 'Herbal Wellness Tea', 'Tea', 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=800&q=80', true, 0, 'varies', 1)
ON CONFLICT (id) DO UPDATE SET
name = EXCLUDED.name, description = EXCLUDED.description, image_url = EXCLUDED.image_url;

INSERT INTO product_variants (product_id, variant_name, price) VALUES
('c3333333-3333-3333-3333-333333333333', '250g', 400),
('c3333333-3333-3333-3333-333333333333', '500g', 700),
('c3333333-3333-3333-3333-333333333333', '1Kg (Box)', 1300),
('c3333333-3333-3333-3333-333333333333', '1Kg Pouch', 1100)
ON CONFLICT DO NOTHING;


-- 4. Shree Kadak
INSERT INTO products (id, name, description, category, image_url, is_active, price_per_unit, unit_type, min_order_quantity) VALUES
('d4444444-4444-4444-4444-444444444444', 'Shree Kadak', 'Kadak Chai Blend', 'Tea', 'https://images.unsplash.com/photo-1594631252845-d9b50e903388?auto=format&fit=crop&w=800&q=80', true, 0, 'varies', 1)
ON CONFLICT (id) DO UPDATE SET
name = EXCLUDED.name, description = EXCLUDED.description, image_url = EXCLUDED.image_url;

INSERT INTO product_variants (product_id, variant_name, price) VALUES
('d4444444-4444-4444-4444-444444444444', '250g', 340),
('d4444444-4444-4444-4444-444444444444', '500g', 620),
('d4444444-4444-4444-4444-444444444444', '1Kg (Box)', 1150),
('d4444444-4444-4444-4444-444444444444', '1Kg Pouch', 950)
ON CONFLICT DO NOTHING;
