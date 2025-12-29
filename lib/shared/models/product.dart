class ProductVariant {
  final String id;
  final String productId;
  final String variantName;
  final double price;
  final int minOrderQuantity;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.variantName,
    required this.price,
    this.minOrderQuantity = 1,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      variantName: json['variant_name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      minOrderQuantity: json['min_order_quantity'] ?? 1,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final bool isActive;
  final List<ProductVariant> variants;

  // Legacy fields for backward compatibility or direct access
  final double pricePerUnit; 
  final String unitType; 
  final int minOrderQuantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.isActive = true,
    this.variants = const [],
    this.pricePerUnit = 0.0,
    this.unitType = '',
    this.minOrderQuantity = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var variantsList = <ProductVariant>[];
    if (json['product_variants'] != null) {
      variantsList = (json['product_variants'] as List)
          .map((v) => ProductVariant.fromJson(v))
          .toList();
    }

    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] ?? true,
      variants: variantsList,
      // Legacy mapping
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      unitType: json['unit_type'] ?? '',
      minOrderQuantity: json['min_order_quantity'] ?? 1,
    );
  }
}
