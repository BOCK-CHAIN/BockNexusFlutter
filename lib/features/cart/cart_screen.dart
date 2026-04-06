import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mock_data.dart';
import '../../core/layout/responsive_layout.dart';
import '../home/providers/shopping_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  String? _couponError;
  bool _showCoupons = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final activeItems = cartState.activeItems;
    final savedItems = cartState.savedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${activeItems.length})'),
        actions: [
          if (activeItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _showClearCartDialog(context),
            ),
        ],
      ),
      body: cartState.isLoading && cartState.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : activeItems.isEmpty && savedItems.isEmpty
              ? _buildEmptyCart(context)
              : Center(
              child: CenteredMaxWidth(
                maxWidth: AppBreakpoints.pageContentMaxWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(cartProvider.notifier).fetchCart(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (activeItems.isNotEmpty && cartState.freeDeliveryRemaining > 0)
                                _buildFreeDeliveryBar(context, cartState),
                              if (activeItems.isNotEmpty)
                                _buildAddressMiniCard(context),
                              if (activeItems.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text('Cart Items',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                ...activeItems.map((item) =>
                                    _buildCartItem(context, ref, item, false)),
                              ],
                              if (activeItems.isNotEmpty)
                                _buildCouponSection(context, cartState),
                              if (activeItems.isNotEmpty)
                                _buildPriceBreakdown(context, cartState),
                              if (savedItems.isNotEmpty) ...[
                                const Divider(height: 32),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Text('Saved for Later (${savedItems.length})',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                ...savedItems.map((item) =>
                                    _buildCartItem(context, ref, item, true)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (activeItems.isNotEmpty)
                      _buildStickyCheckout(context, cartState),
                  ],
                ),
              ),
            ),
    );
  }

  // ════════════════════════════════════════════
  // EMPTY CART
  // ════════════════════════════════════════════

  Widget _buildEmptyCart(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            Text('Your cart is empty',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add items to get started',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // FREE DELIVERY BAR
  // ════════════════════════════════════════════

  Widget _buildFreeDeliveryBar(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 18, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add ${cartState.freeDeliveryRemaining.toStringAsFixed(2)} more for free delivery',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cartState.freeDeliveryProgress,
              backgroundColor: Colors.amber.shade100,
              color: Colors.amber.shade700,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // ADDRESS MINI-CARD
  // ════════════════════════════════════════════

  Widget _buildAddressMiniCard(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = ref.watch(addressProvider);
    final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

    if (defaultAddr == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deliver to ${defaultAddr.receiverName} — ${defaultAddr.zip}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('${defaultAddr.line1}, ${defaultAddr.city}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.pushNamed('checkout'),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // CART ITEM
  // ════════════════════════════════════════════

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item, bool isSaved) {
    final theme = Theme.of(context);
    final product = item.product;
    final itemId = item.cartItemId;

    return Dismissible(
      key: Key('${itemId ?? product.id}_${isSaved ? 'saved' : 'active'}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        if (itemId == null) return;
        final err = await ref.read(cartProvider.notifier).removeItem(itemId);
        if (!context.mounted) return;
        showAppSnackBar(context, err ?? '${product.title} removed');
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (item.selectedSize != null || item.selectedColor != null)
                    Text(
                      [
                        if (item.selectedSize != null) 'Size: ${item.selectedSize}',
                        if (item.selectedColor != null) 'Color: ${item.selectedColor}',
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          )),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 6),
                        Text('${product.originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            )),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!isSaved && itemId != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _miniQtyBtn(Icons.remove, () async {
                                if (item.quantity <= 1) {
                                  final err = await ref
                                      .read(cartProvider.notifier)
                                      .removeItem(itemId);
                                  if (!context.mounted) return;
                                  showAppSnackBar(context, err ?? '${product.title} removed');
                                } else {
                                  final err = await ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(itemId, item.quantity - 1);
                                  if (err != null && context.mounted) {
                                    showAppSnackBar(context, err);
                                  }
                                }
                              }),
                              SizedBox(
                                width: 32,
                                child: Text('${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              _miniQtyBtn(Icons.add, () async {
                                if (item.quantity >= product.stockCount) {
                                  showAppSnackBar(context, 'Max stock (${product.stockCount}) reached');
                                } else {
                                  final err = await ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(itemId, item.quantity + 1);
                                  if (err != null && context.mounted) {
                                    showAppSnackBar(context, err);
                                  }
                                }
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (itemId != null)
                        InkWell(
                          onTap: () {
                            if (isSaved) {
                              ref.read(cartProvider.notifier).moveToCart(itemId);
                            } else {
                              ref.read(cartProvider.notifier).saveForLater(itemId);
                            }
                          },
                          child: Text(
                            isSaved ? 'Move to Cart' : 'Save for Later',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniQtyBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16),
      ),
    );
  }

  // ════════════════════════════════════════════
  // COUPON SECTION
  // ════════════════════════════════════════════

  Widget _buildCouponSection(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cartState.appliedCoupon != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cartState.appliedCoupon!.code} applied — You save ${cartState.couponDiscount.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(cartProvider.notifier).removeCoupon(),
                    child: Icon(Icons.close, size: 18, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    errorText: _couponError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _showCoupons = !_showCoupons),
            child: Text(_showCoupons ? 'Hide Coupons' : 'View Available Coupons'),
          ),
          if (_showCoupons)
            ...MockData.coupons.map((coupon) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: coupon.isUsed ? Colors.grey.shade300 : Colors.green.shade200,
                    ),
                    color: coupon.isUsed ? Colors.grey.shade50 : Colors.green.shade50,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(coupon.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: coupon.isUsed ? Colors.grey : null,
                                )),
                            Text(coupon.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: coupon.isUsed ? Colors.grey : null,
                                )),
                            if (coupon.minOrder > 0)
                              Text('Min order: ${coupon.minOrder.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (coupon.isUsed)
                        const Text('Used',
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                      else
                        TextButton(
                          onPressed: () {
                            _couponController.text = coupon.code;
                            _applyCouponDirect(coupon);
                          },
                          child: const Text('Apply', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final coupon = MockData.coupons.where((c) => c.code == code).firstOrNull;
    if (coupon == null) {
      setState(() => _couponError = 'Invalid coupon code');
      return;
    }
    _applyCouponDirect(coupon);
  }

  void _applyCouponDirect(Coupon coupon) {
    final cartState = ref.read(cartProvider);
    if (coupon.isUsed) {
      setState(() => _couponError = 'This coupon has already been used');
      return;
    }
    if (cartState.subtotal < coupon.minOrder) {
      setState(() =>
          _couponError = 'Minimum order ${coupon.minOrder.toStringAsFixed(0)} required');
      return;
    }
    setState(() => _couponError = null);
    ref.read(cartProvider.notifier).applyCoupon(coupon);
    showAppSnackBar(context, 'Coupon ${coupon.code} applied!');
  }

  // ════════════════════════════════════════════
  // PRICE BREAKDOWN
  // ════════════════════════════════════════════

  Widget _buildPriceBreakdown(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _priceRow(context, 'MRP Total', '${cartState.mrpTotal.toStringAsFixed(2)}'),
          _priceRow(context, 'Discount', '-${cartState.discount.toStringAsFixed(2)}',
              color: Colors.green.shade700),
          if (cartState.couponDiscount > 0)
            _priceRow(context, 'Coupon Discount', '-${cartState.couponDiscount.toStringAsFixed(2)}',
                color: Colors.green.shade700),
          _priceRow(context, 'Delivery',
              cartState.deliveryCharge > 0 ? '${cartState.deliveryCharge.toStringAsFixed(2)}' : 'FREE',
              color: cartState.deliveryCharge == 0 ? Colors.green.shade700 : null),
          _priceRow(context, 'Platform Fee', '${cartState.platformFee.toStringAsFixed(2)}'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${cartState.grandTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )),
            ],
          ),
          if (cartState.discount > 0) ...[
            const SizedBox(height: 8),
            Text('You save ${(cartState.discount + cartState.couponDiscount).toStringAsFixed(2)} on this order!',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // STICKY CHECKOUT
  // ════════════════════════════════════════════

  Widget _buildStickyCheckout(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cartState.grandTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )),
                Text('${cartState.activeItems.length} items',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.pushNamed('checkout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final err = await ref.read(cartProvider.notifier).clearAll();
              if (err != null && mounted) {
                showAppSnackBar(context, err);
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
