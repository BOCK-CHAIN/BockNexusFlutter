import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/network/address_service.dart';
import '../../../core/network/cart_service.dart';
import '../../../core/network/exceptions.dart';
import '../../../core/network/wishlist_service.dart';
import '../../../models/product_model.dart';

// ══════════════════════════════════════════════
// WISHLIST
// ══════════════════════════════════════════════

class WishlistItem {
  final String? wishlistItemId;
  final Product product;
  final DateTime addedAt;
  final String? productSizeId;

  const WishlistItem({
    this.wishlistItemId,
    required this.product,
    required this.addedAt,
    this.productSizeId,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>;
    final product = Product.fromJson(productJson);

    return WishlistItem(
      wishlistItemId: json['id'].toString(),
      product: product,
      addedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      productSizeId: json['productSizeId']?.toString(),
    );
  }
}

enum WishlistSort { dateAdded, priceLowHigh, priceHighLow, name }

final wishlistProvider =
    NotifierProvider<WishlistNotifier, List<WishlistItem>>(WishlistNotifier.new);

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  final _service = WishlistService();

  @override
  List<WishlistItem> build() => [];

  Future<void> fetchWishlist() async {
    try {
      final data = await _service.getWishlist();
      state = data
          .map((json) => WishlistItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Keep current state on error
    }
  }

  /// Optimistic toggle: adds or removes from wishlist.
  /// Returns error message or null on success.
  Future<String?> toggle(Product product) async {
    final existing = state.indexWhere((w) => w.product.id == product.id);
    if (existing >= 0) {
      return _removeByIndex(existing);
    } else {
      return _add(product);
    }
  }

  Future<String?> _add(Product product) async {
    final optimistic = WishlistItem(product: product, addedAt: DateTime.now());
    final previousState = [...state];
    state = [...state, optimistic];

    try {
      await _service.addToWishlist(productId: product.id);
      await fetchWishlist();
      return null;
    } catch (e) {
      state = previousState;
      return e.toString();
    }
  }

  Future<String?> _removeByIndex(int index) async {
    final item = state[index];
    final previousState = [...state];
    state = [...state]..removeAt(index);

    if (item.wishlistItemId == null) return null;

    try {
      await _service.removeItem(item.wishlistItemId!);
      return null;
    } on NotFoundException {
      return null;
    } catch (e) {
      state = previousState;
      return e.toString();
    }
  }

  Future<String?> remove(String productId) async {
    final index = state.indexWhere((w) => w.product.id == productId);
    if (index < 0) return null;
    return _removeByIndex(index);
  }

  bool isWishlisted(String productId) =>
      state.any((w) => w.product.id == productId);

  String? wishlistItemIdFor(String productId) {
    final item = state.where((w) => w.product.id == productId).firstOrNull;
    return item?.wishlistItemId;
  }

  List<WishlistItem> sorted(WishlistSort sort) {
    final list = [...state];
    switch (sort) {
      case WishlistSort.dateAdded:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case WishlistSort.priceLowHigh:
        list.sort((a, b) => a.product.price.compareTo(b.product.price));
      case WishlistSort.priceHighLow:
        list.sort((a, b) => b.product.price.compareTo(a.product.price));
      case WishlistSort.name:
        list.sort((a, b) => a.product.title.compareTo(b.product.title));
    }
    return list;
  }
}

final wishlistSortProvider =
    NotifierProvider<WishlistSortNotifier, WishlistSort>(
        WishlistSortNotifier.new);

class WishlistSortNotifier extends Notifier<WishlistSort> {
  @override
  WishlistSort build() => WishlistSort.dateAdded;
  void set(WishlistSort value) => state = value;
}

// ══════════════════════════════════════════════
// CART (API-BACKED)
// ══════════════════════════════════════════════

class CartState {
  final List<CartItem> items;
  final Coupon? appliedCoupon;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.isLoading = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    Coupon? appliedCoupon,
    bool? isLoading,
    bool clearCoupon = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<CartItem> get activeItems =>
      items.where((i) => !i.savedForLater).toList();
  List<CartItem> get savedItems =>
      items.where((i) => i.savedForLater).toList();

  double get mrpTotal =>
      activeItems.fold(0, (sum, i) => sum + i.product.originalPrice * i.quantity);
  double get subtotal => activeItems.fold(0, (sum, i) => sum + i.totalPrice);
  double get discount => mrpTotal - subtotal;
  double get deliveryCharge => subtotal >= 499 ? 0 : 49;
  double get platformFee => 20;

  double get couponDiscount {
    if (appliedCoupon == null) return 0;
    final raw = subtotal * appliedCoupon!.discountPercent / 100;
    return raw > appliedCoupon!.maxDiscount ? appliedCoupon!.maxDiscount : raw;
  }

  double get grandTotal =>
      subtotal - couponDiscount + deliveryCharge + platformFee;
  double get freeDeliveryRemaining => subtotal >= 499 ? 0 : 499 - subtotal;
  double get freeDeliveryProgress => (subtotal / 499).clamp(0, 1);
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartNotifier extends Notifier<CartState> {
  final _service = CartService();

  @override
  CartState build() => const CartState();

  /// Fetch cart from server and replace local state.
  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.getCart();
      final items = (data['items'] as List)
          .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Add product to cart via API.
  /// Returns error message string, or null on success.
  Future<String?> addProduct(
    Product product, {
    String? size,
    String? color,
    String? productSizeId,
    int qty = 1,
  }) async {
    if (product.sizeType != 'NONE' &&
        product.sizeType != 'ONE_SIZE' &&
        product.productSizes.isNotEmpty &&
        productSizeId == null) {
      return 'Please select a size';
    }

    try {
      await _service.addToCart(
        productId: product.id,
        productSizeId: productSizeId,
        quantity: qty,
        size: size,
      );
      await fetchCart();
      return null;
    } on ValidationException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Update item quantity. Quantity 0 triggers deletion.
  /// Returns error message or null.
  Future<String?> updateQuantity(String cartItemId, int qty) async {
    if (qty <= 0) {
      return removeItem(cartItemId);
    }

    final previousItems = [...state.items];
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.cartItemId == cartItemId) return i.copyWith(quantity: qty);
        return i;
      }).toList(),
    );

    try {
      await _service.updateQuantity(cartItemId: cartItemId, quantity: qty);
      return null;
    } on NotFoundException {
      state = state.copyWith(
        items: state.items
            .where((i) => i.cartItemId != cartItemId)
            .toList(),
      );
      return 'Item no longer exists in cart';
    } catch (e) {
      state = state.copyWith(items: previousItems);
      return e.toString();
    }
  }

  /// Remove a cart item by its server-side cartItemId.
  Future<String?> removeItem(String cartItemId) async {
    final previousItems = [...state.items];
    state = state.copyWith(
      items: state.items
          .where((i) => i.cartItemId != cartItemId)
          .toList(),
    );

    try {
      await _service.removeItem(cartItemId);
      return null;
    } on NotFoundException {
      return null;
    } catch (e) {
      state = state.copyWith(items: previousItems);
      return e.toString();
    }
  }

  /// Clear entire cart.
  Future<String?> clearAll() async {
    final previousItems = [...state.items];
    state = state.copyWith(items: [], clearCoupon: true);

    try {
      await _service.clearCart();
      return null;
    } catch (e) {
      state = state.copyWith(items: previousItems);
      return e.toString();
    }
  }

  // ── Local-only features (coupon, save for later) ──

  void saveForLater(String cartItemId) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.cartItemId == cartItemId) {
          return i.copyWith(savedForLater: true);
        }
        return i;
      }).toList(),
    );
  }

  void moveToCart(String cartItemId) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.cartItemId == cartItemId) {
          return i.copyWith(savedForLater: false);
        }
        return i;
      }).toList(),
    );
  }

  void applyCoupon(Coupon coupon) {
    state = state.copyWith(appliedCoupon: coupon);
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }
}

// ══════════════════════════════════════════════
// ADDRESSES
// ══════════════════════════════════════════════

final addressProvider =
    NotifierProvider<AddressNotifier, List<Address>>(AddressNotifier.new);

class AddressNotifier extends Notifier<List<Address>> {
  final _service = AddressService();

  @override
  List<Address> build() => [];

  Future<void> fetchAddresses() async {
    try {
      final data = await _service.getAddresses();
      state = data
          .map((json) => Address.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Keep current state on error
    }
  }

  Future<String?> add(Address address) async {
    try {
      await _service.addAddress(
        nickname: address.nickname,
        line1: address.line1,
        line2: address.line2,
        city: address.city,
        state: address.state,
        zip: address.zip,
        country: address.country,
        receiverName: address.receiverName,
        isDefault: address.isDefault,
        type: address.type,
      );
      await fetchAddresses();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> setDefault(String id) async {
    final previousState = [...state];
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    try {
      await _service.editAddress(id: int.parse(id), isDefault: true);
      return null;
    } catch (e) {
      state = previousState;
      return e.toString();
    }
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  Future<String?> deleteAddress(String id) async {
    final previousState = [...state];
    state = state.where((a) => a.id != id).toList();
    try {
      await _service.deleteAddress(id);
      return null;
    } catch (e) {
      state = previousState;
      return e.toString();
    }
  }

  Address? get defaultAddress {
    try {
      return state.firstWhere((a) => a.isDefault);
    } catch (_) {
      return state.isNotEmpty ? state.first : null;
    }
  }
}

final selectedAddressProvider = NotifierProvider<SelectedAddressNotifier, String?>(SelectedAddressNotifier.new);

class SelectedAddressNotifier extends Notifier<String?> {
  @override
  String? build() {
    final addresses = ref.watch(addressProvider);
    final defaultAddr = addresses.where((a) => a.isDefault);
    return defaultAddr.isNotEmpty ? defaultAddr.first.id : (addresses.isNotEmpty ? addresses.first.id : null);
  }
  void set(String? value) => state = value;
}

// ══════════════════════════════════════════════
// CHECKOUT
// ══════════════════════════════════════════════

enum PaymentMethod { savedCard, newCard, upi, netBanking, cod, wallet }

class CheckoutState {
  final int currentStep;
  final PaymentMethod? selectedPayment;
  final String? selectedCardId;
  final bool isPlacingOrder;

  const CheckoutState({
    this.currentStep = 0,
    this.selectedPayment,
    this.selectedCardId,
    this.isPlacingOrder = false,
  });

  CheckoutState copyWith({
    int? currentStep,
    PaymentMethod? selectedPayment,
    String? selectedCardId,
    bool? isPlacingOrder,
  }) {
    return CheckoutState(
      currentStep: currentStep ?? this.currentStep,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      selectedCardId: selectedCardId ?? this.selectedCardId,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
    );
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step.clamp(0, 2));
  }

  void setPaymentMethod(PaymentMethod method, {String? cardId}) {
    state = state.copyWith(selectedPayment: method, selectedCardId: cardId);
  }

  void setPlacingOrder(bool placing) {
    state = state.copyWith(isPlacingOrder: placing);
  }

  void reset() {
    state = const CheckoutState();
  }
}

// ══════════════════════════════════════════════
// DELIVERY CHECK
// ══════════════════════════════════════════════

class DeliveryInfo {
  final bool available;
  final String? city;
  final String? state;
  final int? deliveryDays;
  final bool freeShipping;
  final String? error;

  const DeliveryInfo({
    required this.available,
    this.city,
    this.state,
    this.deliveryDays,
    this.freeShipping = false,
    this.error,
  });
}

DeliveryInfo checkDelivery(String pincode) {
  if (pincode.length != 6 || int.tryParse(pincode) == null) {
    return const DeliveryInfo(available: false, error: 'Please enter a valid 6-digit pincode');
  }
  final data = MockData.pincodeData[pincode];
  if (data == null) {
    return const DeliveryInfo(available: false, error: 'Delivery not available for this pincode');
  }
  return DeliveryInfo(
    available: true,
    city: data['city'],
    state: data['state'],
    deliveryDays: int.parse(data['deliveryDays']!),
    freeShipping: true,
  );
}

// ══════════════════════════════════════════════
// PRODUCT DETAIL UI STATE
// ══════════════════════════════════════════════

class ProductDetailUiState {
  final int selectedImageIndex;
  final String? selectedSize;
  final String? selectedColor;
  final int quantity;
  final bool descriptionExpanded;

  const ProductDetailUiState({
    this.selectedImageIndex = 0,
    this.selectedSize,
    this.selectedColor,
    this.quantity = 1,
    this.descriptionExpanded = false,
  });

  ProductDetailUiState copyWith({
    int? selectedImageIndex,
    String? selectedSize,
    String? selectedColor,
    int? quantity,
    bool? descriptionExpanded,
  }) {
    return ProductDetailUiState(
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      quantity: quantity ?? this.quantity,
      descriptionExpanded: descriptionExpanded ?? this.descriptionExpanded,
    );
  }
}

final productDetailUiProvider =
    NotifierProvider<ProductDetailUiNotifier, Map<String, ProductDetailUiState>>(ProductDetailUiNotifier.new);

class ProductDetailUiNotifier extends Notifier<Map<String, ProductDetailUiState>> {
  @override
  Map<String, ProductDetailUiState> build() => {};

  ProductDetailUiState getState(String productId) =>
      state[productId] ?? const ProductDetailUiState();

  void _update(String productId, ProductDetailUiState newState) {
    state = Map.from(state)..[productId] = newState;
  }

  void selectImage(String productId, int index) =>
      _update(productId, getState(productId).copyWith(selectedImageIndex: index));
  void selectSize(String productId, String size) =>
      _update(productId, getState(productId).copyWith(selectedSize: size));
  void selectColor(String productId, String color) =>
      _update(productId, getState(productId).copyWith(selectedColor: color));
  void setQuantity(String productId, int qty) =>
      _update(productId, getState(productId).copyWith(quantity: qty.clamp(1, 99)));
  void toggleDescription(String productId) {
    final current = getState(productId);
    _update(productId, current.copyWith(descriptionExpanded: !current.descriptionExpanded));
  }
}
