import 'api_client.dart';
import '../../models/category_model.dart';

class CategoryService {
  final ApiClient _client;

  CategoryService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<Category>> getAllCategories() async {
    final response = await _client.get('/category');
    final data = response['data'] as List;
    return data
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
