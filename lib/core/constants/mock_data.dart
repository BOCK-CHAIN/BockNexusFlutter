import '../../models/product_model.dart';

// ─── Models that are still mock (not yet backend-integrated) ───

class ProductColor {
  final String name;
  final int colorValue;
  final bool available;

  const ProductColor({
    required this.name,
    required this.colorValue,
    this.available = true,
  });
}

class Review {
  final String id;
  final String userName;
  final String avatarUrl;
  final double rating;
  final DateTime date;
  final String text;
  final List<String> images;
  final int helpfulCount;

  const Review({
    required this.id,
    required this.userName,
    this.avatarUrl = '',
    required this.rating,
    required this.date,
    required this.text,
    this.images = const [],
    this.helpfulCount = 0,
  });
}

class Address {
  final String id;
  final String nickname;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String receiverName;
  final String type;
  final bool isDefault;

  const Address({
    required this.id,
    required this.nickname,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.zip,
    this.country = 'India',
    required this.receiverName,
    this.type = 'Home',
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'].toString(),
      nickname: json['nickname'] as String? ?? '',
      line1: json['line1'] as String? ?? '',
      line2: json['line2'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      receiverName: json['receiverName'] as String? ?? '',
      type: json['type'] as String? ?? 'Home',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  // Backward-compatible getters for existing UI
  String get name => receiverName;
  String get pincode => zip;
  String get addressLine1 => line1;
  String get addressLine2 => line2;
  String get phone => '';

  Address copyWith({
    String? id,
    String? nickname,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? receiverName,
    String? type,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      country: country ?? this.country,
      receiverName: receiverName ?? this.receiverName,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class Coupon {
  final String code;
  final String description;
  final double discountPercent;
  final double maxDiscount;
  final double minOrder;
  final bool isUsed;

  const Coupon({
    required this.code,
    required this.description,
    required this.discountPercent,
    this.maxDiscount = 100,
    this.minOrder = 0,
    this.isUsed = false,
  });
}

class CartItem {
  final String? cartItemId;
  final Product product;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;
  final String? productSizeId;
  final bool savedForLater;

  const CartItem({
    this.cartItemId,
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.selectedColor,
    this.productSizeId,
    this.savedForLater = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>;
    final product = Product.fromJson(productJson);
    final productSize = json['productSize'] as Map<String, dynamic>?;

    return CartItem(
      cartItemId: json['id'].toString(),
      product: product,
      quantity: json['quantity'] as int? ?? 1,
      selectedSize: json['size'] as String? ?? productSize?['size'] as String?,
      selectedColor: product.color,
      productSizeId: json['productSizeId']?.toString(),
    );
  }

  CartItem copyWith({
    String? cartItemId,
    Product? product,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
    String? productSizeId,
    bool? savedForLater,
  }) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      productSizeId: productSizeId ?? this.productSizeId,
      savedForLater: savedForLater ?? this.savedForLater,
    );
  }

  double get totalPrice => product.price * quantity;
  double get totalOriginalPrice => product.originalPrice * quantity;
}

class PaymentCard {
  final String id;
  final String last4;
  final String brand;
  final String expiry;
  final bool isExpired;

  const PaymentCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expiry,
    this.isExpired = false,
  });
}

// ─── Order Models ───

enum OrderStatus {
  placed,
  confirmed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returned
}

enum NotificationType { orderUpdate, dealAlert, priceDrop, system }

class TimelineEvent {
  final String title;
  final String description;
  final DateTime dateTime;
  final bool completed;

  const TimelineEvent({
    required this.title,
    required this.description,
    required this.dateTime,
    this.completed = false,
  });
}

class OrderItem {
  final Product product;
  final int quantity;
  final double priceAtPurchase;
  final String? selectedSize;
  final String? selectedColor;
  final OrderStatus status;
  final bool returnEligible;

  const OrderItem({
    required this.product,
    this.quantity = 1,
    required this.priceAtPurchase,
    this.selectedSize,
    this.selectedColor,
    this.status = OrderStatus.delivered,
    this.returnEligible = true,
  });

  double get totalPrice => priceAtPurchase * quantity;
}

class Order {
  final String id;
  final DateTime orderDate;
  final List<OrderItem> items;
  final OrderStatus status;
  final double totalAmount;
  final Address deliveryAddress;
  final String paymentMethod;
  final List<TimelineEvent> timeline;
  final String? trackingId;

  const Order({
    required this.id,
    required this.orderDate,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.timeline = const [],
    this.trackingId,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? deepLink;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.deepLink,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        deepLink: deepLink,
      );
}

class SubCategory {
  final String id;
  final String name;
  final String parentCategory;
  final String icon;

  const SubCategory({
    required this.id,
    required this.name,
    required this.parentCategory,
    this.icon = '📦',
  });
}

// ─── Mock Data ───

class MockData {
  // Legacy mock products kept for order/cart mock data references
  static final List<Product> products = [
    Product(id: '1', name: 'Premium Wireless Headphones', price: 24999, imageUri: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80', description: 'Experience pure sound with active noise cancellation.', categoryId: '1', sizeType: 'NONE', color: 'Black', brand: 'TechPro', rating: 4.5, reviewCount: 1280, categoryName: 'Electronics', createdAt: DateTime(2026, 2, 15)),
    Product(id: '2', name: 'Minimalist Wrist Watch', price: 12999, imageUri: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80', description: 'Elegant design with Swiss-made movements.', categoryId: '2', sizeType: 'NONE', brand: 'LuxeTime', rating: 4.8, reviewCount: 856, categoryName: 'Fashion', createdAt: DateTime(2026, 2, 10)),
    Product(id: '3', name: 'Classic White Sneakers', price: 4999, imageUri: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80', description: 'Versatile staple for any wardrobe.', categoryId: '2', sizeType: 'GENERIC', brand: 'StyleCo', rating: 4.2, reviewCount: 2340, categoryName: 'Fashion', createdAt: DateTime(2026, 1, 20), productSizes: [ProductSize(id: '1', productId: '3', size: 'S', stock: 30), ProductSize(id: '2', productId: '3', size: 'M', stock: 25), ProductSize(id: '3', productId: '3', size: 'L', stock: 20), ProductSize(id: '4', productId: '3', size: 'XL', stock: 15)]),
    Product(id: '4', name: 'Smart Fitness Tracker', price: 9999, imageUri: 'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=800&q=80', description: 'Track health metrics and workouts.', categoryId: '1', sizeType: 'GENERIC', brand: 'FitGear', rating: 4.0, reviewCount: 1567, categoryName: 'Electronics', createdAt: DateTime(2026, 2, 1)),
    Product(id: '5', name: 'Professional DSLR Camera', price: 89999, imageUri: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&q=80', description: 'Capture stunning 45MP photos and 4K video.', categoryId: '1', sizeType: 'NONE', brand: 'TechPro', rating: 4.9, reviewCount: 423, categoryName: 'Electronics', createdAt: DateTime(2026, 2, 20)),
    Product(id: '6', name: 'Aesthetic Desk Lamp', price: 2499, imageUri: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&q=80', description: 'Modern LED with stepless brightness.', categoryId: '3', sizeType: 'NONE', brand: 'HomeEssentials', rating: 4.6, reviewCount: 890, categoryName: 'Home', createdAt: DateTime(2026, 1, 25)),
    Product(id: '7', name: 'Yoga Mat Premium', price: 1999, imageUri: 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=800&q=80', description: 'Extra thick 6mm non-slip mat.', categoryId: '4', sizeType: 'NONE', brand: 'FitGear', rating: 4.3, reviewCount: 1120, categoryName: 'Sports', createdAt: DateTime(2026, 2, 5)),
  ];

  static const List<String> cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
  ];

  static const List<String> trendingSearches = [
    'Headphones',
    'Sneakers',
    'Camera',
    'Fitness',
    'Skincare',
    'Watch',
  ];

  static const List<Map<String, String>> banners = [
    {
      'title': 'Summer Sale',
      'subtitle': 'Up to 50% off on all electronics',
      'color': '0xFF1E3A8A',
    },
    {
      'title': 'New Arrivals',
      'subtitle': 'Check out the latest fashion trends',
      'color': '0xFF7C3AED',
    },
    {
      'title': 'Free Shipping',
      'subtitle': 'On orders above 499. Limited time!',
      'color': '0xFF059669',
    },
  ];

  // ─── Mock Reviews ───
  static final List<Review> reviews = [
    Review(id: 'r1', userName: 'Arjun M.', rating: 5.0, date: DateTime(2026, 2, 28), text: 'Absolutely love these! The noise cancellation is phenomenal.', helpfulCount: 42),
    Review(id: 'r2', userName: 'Priya S.', rating: 4.0, date: DateTime(2026, 2, 25), text: 'Great product for the price. Battery life is impressive.', helpfulCount: 18),
    Review(id: 'r3', userName: 'Rahul K.', rating: 5.0, date: DateTime(2026, 2, 20), text: 'Premium quality! The build feels solid and the comfort is unmatched.', helpfulCount: 31),
    Review(id: 'r4', userName: 'Sneha D.', rating: 3.0, date: DateTime(2026, 2, 15), text: 'Good sound but the touch controls can be finicky sometimes.', helpfulCount: 8),
    Review(id: 'r5', userName: 'Vikram P.', rating: 4.0, date: DateTime(2026, 2, 10), text: 'Solid headphones. The multipoint connectivity is a game changer.', helpfulCount: 24),
  ];

  // ─── Mock Addresses ───
  static final List<Address> addresses = [
    Address(id: 'a1', nickname: 'Home', receiverName: 'Rahul Sharma', line1: '42, Marine Drive Apartments', line2: 'Nariman Point', city: 'Mumbai', state: 'Maharashtra', zip: '400001', country: 'India', type: 'Home', isDefault: true),
    Address(id: 'a2', nickname: 'Office', receiverName: 'Rahul Sharma', line1: 'Office #305, Tech Park', line2: 'BKC Complex', city: 'Mumbai', state: 'Maharashtra', zip: '400051', country: 'India', type: 'Office', isDefault: false),
  ];

  // ─── Mock Coupons ───
  static const List<Coupon> coupons = [
    Coupon(code: 'NEXUS10', description: '10% off on your first order', discountPercent: 10, maxDiscount: 500, minOrder: 999),
    Coupon(code: 'SAVE20', description: '20% off on orders above 4,999', discountPercent: 20, maxDiscount: 2000, minOrder: 4999),
    Coupon(code: 'ELECTRO15', description: '15% off on Electronics', discountPercent: 15, maxDiscount: 1500, minOrder: 2999),
    Coupon(code: 'USED50', description: '50% off — Super Saver', discountPercent: 50, maxDiscount: 5000, minOrder: 9999, isUsed: true),
  ];

  // ─── Mock Payment Cards ───
  static const List<PaymentCard> savedCards = [
    PaymentCard(id: 'c1', last4: '4242', brand: 'Visa', expiry: '12/28'),
    PaymentCard(id: 'c2', last4: '8888', brand: 'Mastercard', expiry: '06/25', isExpired: true),
  ];

  // ─── Mock Pincode Data ───
  static Map<String, Map<String, String>> pincodeData = {
    '400001': {'city': 'Mumbai', 'state': 'Maharashtra', 'deliveryDays': '2'},
    '400051': {'city': 'Mumbai', 'state': 'Maharashtra', 'deliveryDays': '2'},
    '110001': {'city': 'New Delhi', 'state': 'Delhi', 'deliveryDays': '3'},
    '560001': {'city': 'Bangalore', 'state': 'Karnataka', 'deliveryDays': '3'},
    '500001': {'city': 'Hyderabad', 'state': 'Telangana', 'deliveryDays': '4'},
    '600001': {'city': 'Chennai', 'state': 'Tamil Nadu', 'deliveryDays': '3'},
    '700001': {'city': 'Kolkata', 'state': 'West Bengal', 'deliveryDays': '4'},
    '411001': {'city': 'Pune', 'state': 'Maharashtra', 'deliveryDays': '3'},
    '380001': {'city': 'Ahmedabad', 'state': 'Gujarat', 'deliveryDays': '4'},
    '302001': {'city': 'Jaipur', 'state': 'Rajasthan', 'deliveryDays': '5'},
  };

  // ─── Mock Bank List ───
  static const List<String> banks = [
    'State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank',
    'Kotak Mahindra Bank', 'Punjab National Bank', 'Bank of Baroda',
    'Yes Bank', 'IndusInd Bank', 'Federal Bank',
  ];

  // ─── Mock Orders (legacy, references mock products) ───
  static final List<Order> orders = [
    Order(id: 'NX100001', orderDate: DateTime(2026, 3, 5), status: OrderStatus.shipped, totalAmount: 24999, paymentMethod: 'Visa •••• 4242', deliveryAddress: addresses.first, trackingId: 'TRK9876543', items: [OrderItem(product: products[0], priceAtPurchase: 24999, selectedColor: 'Black')], timeline: [TimelineEvent(title: 'Order Placed', description: 'Your order has been placed', dateTime: DateTime(2026, 3, 5, 14, 30), completed: true), TimelineEvent(title: 'Confirmed', description: 'Seller confirmed your order', dateTime: DateTime(2026, 3, 5, 16, 0), completed: true), TimelineEvent(title: 'Shipped', description: 'Package picked up by courier', dateTime: DateTime(2026, 3, 6, 10, 0), completed: true), TimelineEvent(title: 'Out for Delivery', description: 'Your package is on its way', dateTime: DateTime(2026, 3, 8), completed: false), TimelineEvent(title: 'Delivered', description: 'Package delivered', dateTime: DateTime(2026, 3, 8, 18, 0), completed: false)]),
    Order(id: 'NX100002', orderDate: DateTime(2026, 3, 3), status: OrderStatus.delivered, totalAmount: 22998, paymentMethod: 'UPI', deliveryAddress: addresses.first, items: [OrderItem(product: products[1], priceAtPurchase: 12999, selectedSize: 'M'), OrderItem(product: products[3], priceAtPurchase: 9999, quantity: 1)], timeline: [TimelineEvent(title: 'Order Placed', description: 'Your order has been placed', dateTime: DateTime(2026, 3, 3, 9, 0), completed: true), TimelineEvent(title: 'Delivered', description: 'Package delivered to you', dateTime: DateTime(2026, 3, 5, 14, 30), completed: true)]),
    Order(id: 'NX100003', orderDate: DateTime(2026, 2, 28), status: OrderStatus.delivered, totalAmount: 89999, paymentMethod: 'Cash on Delivery', deliveryAddress: addresses.last, items: [OrderItem(product: products[4], priceAtPurchase: 89999, returnEligible: false)], timeline: [TimelineEvent(title: 'Order Placed', description: 'Your order has been placed', dateTime: DateTime(2026, 2, 28, 20, 0), completed: true), TimelineEvent(title: 'Delivered', description: 'Delivered successfully', dateTime: DateTime(2026, 3, 2, 13, 0), completed: true)]),
  ];

  // ─── Mock Notifications ───
  static final List<AppNotification> notifications = [
    AppNotification(id: 'n1', type: NotificationType.orderUpdate, title: 'Order Shipped!', body: 'Your order NX100001 has been shipped.', timestamp: DateTime(2026, 3, 6, 10, 30), deepLink: '/orders/NX100001'),
    AppNotification(id: 'n2', type: NotificationType.dealAlert, title: 'Flash Sale Live!', body: 'Up to 60% off on Electronics. Ends tonight!', timestamp: DateTime(2026, 3, 6, 8, 0), isRead: true),
    AppNotification(id: 'n3', type: NotificationType.priceDrop, title: 'Price Drop Alert', body: 'An item in your wishlist dropped to 9,999!', timestamp: DateTime(2026, 3, 6, 7, 0), deepLink: '/product/p1'),
    AppNotification(id: 'n4', type: NotificationType.orderUpdate, title: 'Order Delivered', body: 'Your order NX100002 was delivered successfully.', timestamp: DateTime(2026, 3, 5, 14, 30), isRead: true, deepLink: '/orders/NX100002'),
    AppNotification(id: 'n5', type: NotificationType.system, title: 'App Updated', body: 'Nexus has been updated to v2.1.', timestamp: DateTime(2026, 3, 5, 9, 0), isRead: true),
  ];
}
