import 'api_client.dart';

class WishlistService {
  final ApiClient _client;

  WishlistService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<dynamic>> getWishlist() async {
    final response = await _client.get('/wishlist', auth: true);
    return response['data'] as List;
  }

  Future<Map<String, dynamic>> addToWishlist({
    required String productId,
    String? productSizeId,
    int quantity = 1,
  }) async {
    final body = <String, dynamic>{
      'productId': int.parse(productId),
      'quantity': quantity,
    };
    if (productSizeId != null) {
      body['productSizeId'] = int.parse(productSizeId);
    }

    final response =
        await _client.post('/wishlist/add', body, auth: true);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateQuantity({
    required String wishlistItemId,
    required int quantity,
  }) async {
    final response = await _client.put(
      '/wishlist/$wishlistItemId',
      {'quantity': quantity},
      auth: true,
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> removeItem(String wishlistItemId) async {
    await _client.delete('/wishlist/$wishlistItemId', auth: true);
  }

  Future<void> clearWishlist() async {
    await _client.delete('/wishlist/clear', auth: true);
  }
}
