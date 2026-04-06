import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/network/order_service.dart';
import '../../../models/product_model.dart';

// ══════════════════════════════════════════════
// ORDER MODEL EXTENSIONS — fromJson mapping
// ══════════════════════════════════════════════

extension OrderFromJson on Order {
  static Order fromApiJson(Map<String, dynamic> json) {
    // Map backend status to Flutter enum
    OrderStatus mapStatus(String? s) {
      switch (s) {
        case 'ORDER_PLACED':
          return OrderStatus.placed;
        case 'SHIPPING':
          return OrderStatus.shipped;
        case 'OUT_FOR_DELIVERY':
          return OrderStatus.outForDelivery;
        case 'DELIVERED':
          return OrderStatus.delivered;
        case 'CANCELLED':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.placed;
      }
    }

    // Parse items
    final rawItems = json['items'] as List? ?? [];
    final items = rawItems.map<OrderItem>((item) {
      final productJson = item['product'] as Map<String, dynamic>? ?? {};
      final product = Product.fromJson(productJson);
      final qty = item['quantity'] as int? ?? 1;
      return OrderItem(
        product: product,
        quantity: qty,
        priceAtPurchase: (product.price).toDouble(),
      );
    }).toList();

    // Parse address
    final addrJson = json['Address'] as Map<String, dynamic>?;
    Address address;
    if (addrJson != null) {
      address = Address.fromJson(addrJson);
    } else {
      address = const Address(
        id: '0',
        nickname: 'Home',
        line1: '',
        city: '',
        state: '',
        zip: '',
        receiverName: 'Customer',
      );
    }

    final double total = items.fold(
      0.0,
      (sum, i) => sum + i.priceAtPurchase * i.quantity,
    );

    return Order(
      id: json['id']?.toString() ?? '',
      orderDate: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: items,
      status: mapStatus(json['status']?.toString()),
      totalAmount: total,
      deliveryAddress: address,
      paymentMethod: 'Online',
    );
  }
}

// ══════════════════════════════════════════════
// ORDERS STATE
// ══════════════════════════════════════════════

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ══════════════════════════════════════════════
// ORDERS PROVIDER
// ══════════════════════════════════════════════

final ordersProvider =
    NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<OrdersState> {
  final _service = OrderService();

  @override
  OrdersState build() => const OrdersState();

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _service.getMyOrders();
      final orders = data
          .map((json) =>
              OrderFromJson.fromApiJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Order? getById(String id) {
    try {
      return state.orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Order> get activeOrders => state.orders
      .where((o) =>
          o.status == OrderStatus.placed ||
          o.status == OrderStatus.confirmed ||
          o.status == OrderStatus.shipped ||
          o.status == OrderStatus.outForDelivery)
      .toList();

  List<Order> get deliveredOrders =>
      state.orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<Order> get cancelledOrders =>
      state.orders.where((o) => o.status == OrderStatus.cancelled).toList();

  List<Order> get returnedOrders =>
      state.orders.where((o) => o.status == OrderStatus.returned).toList();

  void cancelOrder(String orderId, String reason) {
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        return Order(
          id: o.id,
          orderDate: o.orderDate,
          items: o.items,
          status: OrderStatus.cancelled,
          totalAmount: o.totalAmount,
          deliveryAddress: o.deliveryAddress,
          paymentMethod: o.paymentMethod,
          timeline: [
            ...o.timeline.where((t) => t.completed),
            TimelineEvent(
              title: 'Cancelled',
              description: 'Reason: $reason',
              dateTime: DateTime.now(),
              completed: true,
            ),
          ],
        );
      }
      return o;
    }).toList();
    state = state.copyWith(orders: updated);
  }

  void requestReturn(String orderId, String itemProductId) {
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        return Order(
          id: o.id,
          orderDate: o.orderDate,
          items: o.items,
          status: OrderStatus.returned,
          totalAmount: o.totalAmount,
          deliveryAddress: o.deliveryAddress,
          paymentMethod: o.paymentMethod,
          timeline: [
            ...o.timeline,
            TimelineEvent(
              title: 'Return Requested',
              description: 'Return initiated',
              dateTime: DateTime.now(),
              completed: true,
            ),
          ],
        );
      }
      return o;
    }).toList();
    state = state.copyWith(orders: updated);
  }
}
