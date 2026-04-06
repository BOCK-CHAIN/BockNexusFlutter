import 'api_client.dart';
import '../../models/product_model.dart';

class ProductService {
  final ApiClient _client;

  ProductService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<Product>> getAllProducts() async {
    final response = await _client.get('/product');
    final data = response['data'] as List;
    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> getRandomProducts() async {
    final response = await _client.get('/product/random-products');
    final data = response['data'] as List;
    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProductById(String productId) async {
    final response = await _client.get('/product/$productId');
    return Product.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final response = await _client.get('/product/category/$categoryId');
    final data = response['data'] as List;
    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final response =
        await _client.get('/product/search', queryParams: {'query': query});
    final data = response['data'] as List;
    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> filterProducts({
    String? categoryId,
    String? color,
    String? size,
    String? brand,
    double? minPrice,
    double? maxPrice,
  }) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (color != null) params['color'] = color;
    if (size != null) params['size'] = size;
    if (brand != null) params['brand'] = brand;
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();

    final response = await _client.get('/product/filter', queryParams: params);
    final data = response['data'] as List;
    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getBrands(String categoryId) async {
    final response = await _client
        .get('/product/brands', queryParams: {'categoryId': categoryId});
    final data = response['data'] as List;
    return data.map((e) => e.toString()).toList();
  }

  Future<List<String>> getColours(String categoryId) async {
    final response = await _client
        .get('/product/colours', queryParams: {'categoryId': categoryId});
    final data = response['data'] as List;
    return data.map((e) => e.toString()).toList();
  }

  Future<List<String>> getSizes(String categoryId) async {
    final response = await _client
        .get('/product/sizes', queryParams: {'categoryId': categoryId});
    final data = response['data'] as List;
    return data.map((e) => e.toString()).toList();
  }
}
