class ProductSize {
  final String id;
  final String productId;
  final String size;
  final int stock;
  final int sortOrder;

  const ProductSize({
    required this.id,
    required this.productId,
    required this.size,
    required this.stock,
    this.sortOrder = 0,
  });

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      id: json['id'].toString(),
      productId: json['productId'].toString(),
      size: json['size'] as String,
      stock: json['stock'] as int? ?? 0,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUri;
  final String? arUri;
  final String? description;
  final String categoryId;
  final String sizeType;
  final String? color;
  final String? brand;
  final DateTime createdAt;
  final List<ProductSize> productSizes;
  final double rating;
  final int reviewCount;
  final String categoryName;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUri,
    this.arUri,
    this.description,
    required this.categoryId,
    this.sizeType = 'NONE',
    this.color,
    this.brand,
    required this.createdAt,
    this.productSizes = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.categoryName = '',
  });

  // Backward-compatible getters for existing UI
  String get title => name;
  String get imageUrl => imageUri;
  String get category => categoryName;
  bool get inStock =>
      productSizes.isEmpty || productSizes.any((s) => s.stock > 0);
  int get stockCount => productSizes.isEmpty
      ? 999
      : productSizes.fold(0, (sum, s) => sum + s.stock);
  List<String> get sizes => productSizes.map((s) => s.size).toList();

  double get originalPrice => price;
  int get discountPercent => 0;
  int get soldCount => 0;
  String get sku => '';
  List<String> get images => [imageUri];
  Map<String, String> get specifications => {};
  String get sellerName => 'BockNexus Store';
  double get sellerRating => 4.5;

  factory Product.fromJson(Map<String, dynamic> json) {
    final reviews = json['reviews'] as List? ?? [];
    double avgRating = 0.0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold<double>(
          0.0, (sum, r) => sum + (r['rating'] as num).toDouble());
      avgRating = double.parse((total / reviews.length).toStringAsFixed(1));
    }

    String catName = '';
    if (json['category'] is Map) {
      catName = (json['category'] as Map)['name']?.toString() ?? '';
    }

    return Product(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUri: json['image_uri'] as String,
      arUri: json['ar_uri'] as String?,
      description: json['description'] as String?,
      categoryId: json['categoryId'].toString(),
      sizeType: json['sizeType'] as String? ?? 'NONE',
      color: json['color'] as String?,
      brand: json['brand'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      productSizes: (json['productSizes'] as List?)
              ?.map((s) => ProductSize.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      rating: avgRating,
      reviewCount: reviews.length,
      categoryName: catName,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUri,
    String? arUri,
    String? description,
    String? categoryId,
    String? sizeType,
    String? color,
    String? brand,
    DateTime? createdAt,
    List<ProductSize>? productSizes,
    double? rating,
    int? reviewCount,
    String? categoryName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUri: imageUri ?? this.imageUri,
      arUri: arUri ?? this.arUri,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      sizeType: sizeType ?? this.sizeType,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      createdAt: createdAt ?? this.createdAt,
      productSizes: productSizes ?? this.productSizes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
