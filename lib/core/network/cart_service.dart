import 'api_client.dart';

class CartService {
  final ApiClient _client;

  CartService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getCart() async {
    final response = await _client.get('/cart', auth: true);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToCart({
    required String productId,
    String? productSizeId,
    required int quantity,
    String? size,
  }) async {
    final body = <String, dynamic>{
      'productId': int.parse(productId),
      'quantity': quantity,
    };
    if (productSizeId != null) {
      body['productSizeId'] = int.parse(productSizeId);
    }
    if (size != null) body['size'] = size;

    final response = await _client.post('/cart/add', body, auth: true);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final response = await _client.put(
      '/cart/$cartItemId',
      {'quantity': quantity},
      auth: true,
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> removeItem(String cartItemId) async {
    await _client.delete('/cart/$cartItemId', auth: true);
  }

  Future<void> clearCart() async {
    await _client.delete('/cart/clear', auth: true);
  }
}
