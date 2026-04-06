class Category {
  final String id;
  final String name;
  final String imageUri;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    required this.imageUri,
    this.productCount = 0,
  });

  static int _parseProductCount(Map<String, dynamic> json) {
    final countVal = (json['_count'] as Map?)?['products'];
    if (countVal is num) return countVal.toInt();
    if (countVal != null) return int.tryParse(countVal.toString()) ?? 0;
    final products = json['products'];
    if (products is List) return products.length;
    return 0;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final uri = (json['image_uri'] ?? json['imageUri'])?.toString() ?? '';
    return Category(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      imageUri: uri,
      productCount: _parseProductCount(json),
    );
  }
}
