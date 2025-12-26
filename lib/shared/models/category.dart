class TeaCategory {
  final String id;
  final String name;
  final String imageUrl;

  TeaCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory TeaCategory.fromJson(Map<String, dynamic> json) {
    return TeaCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
