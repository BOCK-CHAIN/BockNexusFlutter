import 'api_client.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';

/// Single-entity admin responses are the JSON object itself (`res.json(entity)`),
/// not `{ data: ... }`. List endpoints still use `{ data, total, ... }`.
Map<String, dynamic> _entityMap(dynamic response) {
  if (response == null) {
    throw const FormatException('Empty admin response');
  }
  if (response is! Map) {
    throw FormatException('Expected JSON object, got ${response.runtimeType}');
  }
  final map = Map<String, dynamic>.from(response as Map);
  final nested = map['data'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return map;
}

/// Admin-only API service for managing products and categories.
class AdminService {
  final ApiClient _client;

  AdminService([ApiClient? client]) : _client = client ?? ApiClient();

  // ─── Products ──────────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final response = await _client.get('/admin/products', auth: true);
    final data = response['data'] as List;
    return data
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(String id) async {
    final response = await _client.get('/admin/products/$id', auth: true);
    return Product.fromJson(_entityMap(response));
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    final response =
        await _client.post('/admin/products', body, auth: true);
    return Product.fromJson(_entityMap(response));
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> body) async {
    final response =
        await _client.put('/admin/products/$id', body, auth: true);
    return Product.fromJson(_entityMap(response));
  }

  Future<void> deleteProduct(String id) async {
    await _client.delete('/admin/products/$id', auth: true);
  }

  Future<void> updateProductStock(
      String id, List<Map<String, dynamic>> sizes) async {
    await _client.put(
      '/admin/products/$id/stock',
      {'productSizes': sizes},
      auth: true,
    );
  }

  // ─── Categories ────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final response = await _client.get('/admin/categories', auth: true);
    final data = response['data'] as List;
    return data
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Category> getCategory(String id) async {
    final response = await _client.get('/admin/categories/$id', auth: true);
    return Category.fromJson(_entityMap(response));
  }

  Future<Category> createCategory(Map<String, dynamic> body) async {
    final response =
        await _client.post('/admin/categories', body, auth: true);
    return Category.fromJson(_entityMap(response));
  }

  Future<Category> updateCategory(
      String id, Map<String, dynamic> body) async {
    final response =
        await _client.put('/admin/categories/$id', body, auth: true);
    return Category.fromJson(_entityMap(response));
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/admin/categories/$id', auth: true);
  }
}
