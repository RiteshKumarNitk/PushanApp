class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double pricePerUnit;
  final int minOrderQuantity;
  final String unitType; // pack, kg, box
  final String imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.pricePerUnit,
    required this.minOrderQuantity,
    this.unitType = 'pack',
    required this.imageUrl,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      minOrderQuantity: json['min_order_quantity'] ?? 1,
      unitType: json['unit_type'] ?? 'pack',
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}
