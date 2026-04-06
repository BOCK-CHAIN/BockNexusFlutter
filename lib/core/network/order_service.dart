import 'api_client.dart';

class OrderService {
  final ApiClient _client;

  OrderService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Place a new order (no Razorpay required).
  /// [items] — list of { productId, quantity, productSizeId? }
  /// Returns the created order map.
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String addressId,
    String? paymentMethod,
  }) async {
    final body = <String, dynamic>{
      'items': items,
      'totalAmount': totalAmount,
      'addressId': addressId,
      'paymentMethod': paymentMethod ?? 'COD',
    };
    final response = await _client.post('/orders/place', body, auth: true);
    return response['order'] as Map<String, dynamic>;
  }

  /// Fetch all orders for the authenticated user.
  Future<List<dynamic>> getMyOrders() async {
    final response = await _client.get('/orders/my-orders', auth: true);
    return response['orders'] as List? ?? [];
  }
}
