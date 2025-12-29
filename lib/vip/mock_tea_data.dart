
import '../shared/models/product.dart';

final List<Product> mockTeaProducts = [
  // Amchi Mumbai
  Product(
    id: 'a1111111-1111-1111-1111-111111111111',
    name: 'Amchi Mumbai',
    description: 'Premium Black Tea',
    category: 'Tea',
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231844f74?auto=format&fit=crop&w=800&q=80',
    isActive: true,
    variants: [
      ProductVariant(id: 'v1111111', productId: 'a1111111-1111-1111-1111-111111111111', variantName: '250g', price: 350),
      ProductVariant(id: 'v1111112', productId: 'a1111111-1111-1111-1111-111111111111', variantName: '500g', price: 600),
      ProductVariant(id: 'v1111113', productId: 'a1111111-1111-1111-1111-111111111111', variantName: '1Kg (Box)', price: 1100),
      ProductVariant(id: 'v1111114', productId: 'a1111111-1111-1111-1111-111111111111', variantName: '1Kg Pouch', price: 950),
    ],
  ),

  // Rajasthan Royal
  Product(
    id: 'b2222222-2222-2222-2222-222222222222',
    name: 'Rajasthan Royal',
    description: 'Royal Masala Tea',
    category: 'Tea',
    imageUrl: 'https://images.unsplash.com/photo-1563911302283-d2bc129e7c1f?auto=format&fit=crop&w=800&q=80',
    isActive: true,
    variants: [
      ProductVariant(id: 'v2222221', productId: 'b2222222-2222-2222-2222-222222222222', variantName: '250g', price: 320),
      ProductVariant(id: 'v2222222', productId: 'b2222222-2222-2222-2222-222222222222', variantName: '500g', price: 590),
      ProductVariant(id: 'v2222223', productId: 'b2222222-2222-2222-2222-222222222222', variantName: '1Kg (Box)', price: 1050),
      ProductVariant(id: 'v2222224', productId: 'b2222222-2222-2222-2222-222222222222', variantName: '1Kg Pouch', price: 900),
    ],
  ),

  // TeaUP Divine
  Product(
    id: 'c3333333-3333-3333-3333-333333333333',
    name: 'TeaUP Divine',
    description: 'Herbal Wellness Tea',
    category: 'Tea',
    imageUrl: 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=800&q=80',
    isActive: true,
    variants: [
      ProductVariant(id: 'v3333331', productId: 'c3333333-3333-3333-3333-3333333333333', variantName: '250g', price: 400),
      ProductVariant(id: 'v3333332', productId: 'c3333333-3333-3333-3333-3333333333333', variantName: '500g', price: 700),
      ProductVariant(id: 'v3333333', productId: 'c3333333-3333-3333-3333-3333333333333', variantName: '1Kg (Box)', price: 1300),
      ProductVariant(id: 'v3333334', productId: 'c3333333-3333-3333-3333-3333333333333', variantName: '1Kg Pouch', price: 1100),
    ],
  ),

  // Shree Kadak
  Product(
    id: 'd4444444-4444-4444-4444-444444444444',
    name: 'Shree Kadak',
    description: 'Kadak Chai Blend',
    category: 'Tea',
    imageUrl: 'https://images.unsplash.com/photo-1594631252845-d9b50e903388?auto=format&fit=crop&w=800&q=80',
    isActive: true,
    variants: [
      ProductVariant(id: 'v4444441', productId: 'd4444444-4444-4444-4444-444444444444', variantName: '250g', price: 340),
      ProductVariant(id: 'v4444442', productId: 'd4444444-4444-4444-4444-444444444444', variantName: '500g', price: 620),
      ProductVariant(id: 'v4444443', productId: 'd4444444-4444-4444-4444-444444444444', variantName: '1Kg (Box)', price: 1150),
      ProductVariant(id: 'v4444444', productId: 'd4444444-4444-4444-4444-444444444444', variantName: '1Kg Pouch', price: 950),
    ],
  ),
];
