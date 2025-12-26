class Tea {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? categoryId;
  final bool isPopular;
  final bool isNew;

  Tea({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.categoryId,
    this.isPopular = false,
    this.isNew = false,
  });

  factory Tea.fromJson(Map<String, dynamic> json) {
    return Tea(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'],
      isPopular: json['is_popular'] ?? false,
      isNew: json['is_new'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_popular': isPopular,
      'is_new': isNew,
    };
  }
}
