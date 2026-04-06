import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mock_data.dart';
import '../../core/layout/responsive_layout.dart';
import '../../models/product_model.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/shimmer_loading.dart';
import '../home/providers/product_providers.dart';
import '../home/providers/shopping_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _pincodeController = TextEditingController();
  DeliveryInfo? _deliveryInfo;
  bool _shakeVariant = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pincodeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    setState(() => _shakeVariant = true);
    _shakeController.forward(from: 0).then((_) {
      if (mounted) setState(() => _shakeVariant = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final uiStateMap = ref.watch(productDetailUiProvider);
    final uiState = uiStateMap[widget.productId] ?? const ProductDetailUiState();

    return Scaffold(
      body: productAsync.when(
        data: (product) => _buildDetail(context, product, uiState),
        loading: () => _buildShimmerDetail(context),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Product product, ProductDetailUiState uiState) {
    final theme = Theme.of(context);
    final isWishlisted = ref.watch(wishlistProvider).any((w) => w.product.id == product.id);
    final effectiveImages = product.images.isNotEmpty ? product.images : [product.imageUrl];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ─── App Bar ───
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              title: const Text('Details'),
              actions: [
                IconButton(
                  icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.red : null),
                  onPressed: () async {
                    final err = await ref.read(wishlistProvider.notifier).toggle(product);
                    if (err != null && context.mounted) {
                      showAppSnackBar(context, err);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    showAppSnackBar(context, 'Share link copied!');
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: CenteredMaxWidth(
                maxWidth: AppBreakpoints.pageContentMaxWidth,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = AppBreakpoints.useProductDetailTwoColumn(
                        constraints.maxWidth);
                    final thumbGap = effectiveImages.length > 1
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              _buildThumbnailStrip(
                                  effectiveImages, uiState),
                            ],
                          )
                        : const SizedBox.shrink();

                    final galleryColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildImageGallery(
                          context,
                          effectiveImages,
                          uiState,
                          useAspectRatio: twoCol,
                        ),
                        thumbGap,
                      ],
                    );

                    if (!twoCol) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          galleryColumn,
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPurchaseInfoSection(
                                    context, theme, product, uiState),
                                _buildBelowFoldSection(
                                    context, product, uiState),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: galleryColumn,
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 6,
                                child: _buildPurchaseInfoSection(
                                    context, theme, product, uiState),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildBelowFoldSection(
                              context, product, uiState),
                        ),
                        const SizedBox(height: 100),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        // ─── Sticky Bottom Bar ───
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildStickyBottomBar(context, product, uiState),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  // PURCHASE INFO (title, price, variants — beside gallery on wide screens)
  // ════════════════════════════════════════════

  Widget _buildPurchaseInfoSection(
    BuildContext context,
    ThemeData theme,
    Product product,
    ProductDetailUiState uiState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand != null && product.brand!.isNotEmpty)
          Text(
            product.brand!.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 4),
        Text(product.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        if (product.sku.isNotEmpty)
          Text(
            'SKU: ${product.sku}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingStars(rating: product.rating, size: 18),
            const SizedBox(width: 8),
            Text(
              '${product.reviewCount} reviews',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Text(
              '${product.soldCount} sold',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPriceSection(context, product),
        const SizedBox(height: 8),
        if (!product.inStock)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 4),
                Text(
                  'Out of Stock',
                  style: TextStyle(
                      color: Colors.red.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else if (product.stockCount <= 3 && product.stockCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Only ${product.stockCount} left!',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        if (product.sizeType != 'NONE' && product.sizeType != 'ONE_SIZE')
          _buildSizeSelector(context, product, uiState),
        if (product.sizeType == 'ONE_SIZE')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              label: const Text('One Size'),
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        if (product.color != null && product.color!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildColorDisplay(context, product),
        ],
        if (product.inStock) ...[
          const SizedBox(height: 20),
          _buildQuantitySelector(context, product, uiState),
        ],
      ],
    );
  }

  Widget _buildBelowFoldSection(
    BuildContext context,
    Product product,
    ProductDetailUiState uiState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(context, product, uiState),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        if (product.specifications.isNotEmpty)
          _buildSpecifications(context, product),
        const Divider(),
        const SizedBox(height: 12),
        _buildDeliverySection(context),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        _buildOffersSection(context),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        _buildSellerInfo(context, product),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        _buildReviewsSection(context, product),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        _buildRelatedProducts(context, product),
        const SizedBox(height: 24),
        _buildYouMayAlsoLike(context, product),
      ],
    );
  }

  // ════════════════════════════════════════════
  // IMAGE GALLERY
  // ════════════════════════════════════════════

  Widget _buildImageGallery(
    BuildContext context,
    List<String> images,
    ProductDetailUiState uiState, {
    bool useAspectRatio = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget pageView = PageView.builder(
      controller: _pageController,
      itemCount: images.length,
      onPageChanged: (i) => ref
          .read(productDetailUiProvider.notifier)
          .selectImage(widget.productId, i),
      itemBuilder: (context, index) {
        final img = CachedNetworkImage(
          imageUrl: images[index],
          width: double.infinity,
          height: useAspectRatio ? double.infinity : 380,
          fit: BoxFit.cover,
          placeholder: (context, url) => useAspectRatio
              ? SizedBox.expand(
                  child: ShimmerLoading(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : const ShimmerLoading(
                  width: double.infinity,
                  height: 380,
                ),
          errorWidget: (context, url, error) => Container(
            width: double.infinity,
            height: useAspectRatio ? double.infinity : 380,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported,
                size: 64, color: Colors.grey),
          ),
        );
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: useAspectRatio ? SizedBox.expand(child: img) : img,
        );
      },
    );

    if (!useAspectRatio) {
      pageView = SizedBox(height: 380, child: pageView);
    } else {
      pageView = AspectRatio(aspectRatio: 1, child: pageView);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(useAspectRatio ? 12 : 0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(useAspectRatio ? 12 : 0),
            child: pageView,
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: uiState.selectedImageIndex == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: uiState.selectedImageIndex == i
                        ? colorScheme.primary
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildThumbnailStrip(List<String> images, ProductDetailUiState uiState) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final selected = uiState.selectedImageIndex == index;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(index,
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              ref.read(productDetailUiProvider.notifier).selectImage(widget.productId, index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════
  // PRICE SECTION
  // ════════════════════════════════════════════

  Widget _buildPriceSection(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${product.price.toStringAsFixed(2)}',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.originalPrice > product.price) ...[
          const SizedBox(width: 10),
          Text(
            '${product.originalPrice.toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${product.discountPercent}% OFF',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════
  // VARIANT SELECTORS
  // ════════════════════════════════════════════

  Widget _buildSizeSelector(BuildContext context, Product product, ProductDetailUiState uiState) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _shakeController,
      builder: (context, child) {
        final offset = _shakeVariant
            ? 10 * (0.5 - _shakeController.value) * (_shakeController.value < 0.5 ? 1 : -1)
            : 0.0;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Size', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: product.productSizes.map((ps) {
              final selected = uiState.selectedSize == ps.size;
              final outOfStock = ps.stock == 0;
              return ChoiceChip(
                label: Text(ps.size),
                selected: selected,
                onSelected: outOfStock
                    ? null
                    : (_) => ref
                        .read(productDetailUiProvider.notifier)
                        .selectSize(widget.productId, ps.size),
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                disabledColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: outOfStock
                      ? Colors.grey.shade400
                      : selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  decoration: outOfStock ? TextDecoration.lineThrough : null,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: outOfStock
                        ? Colors.grey.shade300
                        : selected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDisplay(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Chip(
          label: Text(product.color!),
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(color: theme.colorScheme.primary),
          labelStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  // QUANTITY SELECTOR
  // ════════════════════════════════════════════

  Widget _buildQuantitySelector(BuildContext context, Product product, ProductDetailUiState uiState) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('Quantity', style: theme.textTheme.titleMedium),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              _qtyButton(Icons.remove, () {
                if (uiState.quantity > 1) {
                  ref.read(productDetailUiProvider.notifier)
                      .setQuantity(widget.productId, uiState.quantity - 1);
                }
              }),
              SizedBox(
                width: 48,
                child: Text(
                  '${uiState.quantity}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _qtyButton(Icons.add, () {
                if (uiState.quantity < product.stockCount) {
                  ref.read(productDetailUiProvider.notifier)
                      .setQuantity(widget.productId, uiState.quantity + 1);
                } else {
                  showAppSnackBar(context, 'Max stock limit (${product.stockCount}) reached');
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20),
      ),
    );
  }

  // ════════════════════════════════════════════
  // DESCRIPTION
  // ════════════════════════════════════════════

  Widget _buildDescription(BuildContext context, Product product, ProductDetailUiState uiState) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: Text(
            product.description ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          secondChild: Text(
            product.description ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          crossFadeState:
              uiState.descriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        TextButton(
          onPressed: () =>
              ref.read(productDetailUiProvider.notifier).toggleDescription(widget.productId),
          child: Text(uiState.descriptionExpanded ? 'Show Less' : 'Read More'),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  // SPECIFICATIONS
  // ════════════════════════════════════════════

  Widget _buildSpecifications(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Specifications', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: product.specifications.entries.toList().asMap().entries.map((entry) {
              final isLast = entry.key == product.specifications.length - 1;
              final spec = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: entry.key.isEven ? Colors.grey.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.vertical(
                    top: entry.key == 0 ? const Radius.circular(12) : Radius.zero,
                    bottom: isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(spec.key,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                    ),
                    Expanded(
                      child: Text(spec.value,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ════════════════════════════════════════════
  // DELIVERY SECTION
  // ════════════════════════════════════════════

  Widget _buildDeliverySection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter pincode',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _checkDelivery,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _checkDelivery,
              child: const Text('Check'),
            ),
          ],
        ),
        if (_deliveryInfo != null) ...[
          const SizedBox(height: 12),
          if (_deliveryInfo!.available)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 20, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text('Delivery in ${_deliveryInfo!.deliveryDays} days',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${_deliveryInfo!.city}, ${_deliveryInfo!.state}',
                      style: theme.textTheme.bodySmall),
                  if (_deliveryInfo!.freeShipping)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('✓ Free Shipping',
                          style: TextStyle(
                              color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_deliveryInfo!.error ?? 'Not available',
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _checkDelivery() {
    final result = checkDelivery(_pincodeController.text);
    setState(() => _deliveryInfo = result);
  }

  // ════════════════════════════════════════════
  // OFFERS SECTION
  // ════════════════════════════════════════════

  Widget _buildOffersSection(BuildContext context) {
    final theme = Theme.of(context);
    final coupons = MockData.coupons.where((c) => !c.isUsed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Offers', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ...coupons.map((coupon) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
                color: Colors.green.shade50,
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coupon.description,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('Code: ${coupon.code}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ════════════════════════════════════════════
  // SELLER INFO
  // ════════════════════════════════════════════

  Widget _buildSellerInfo(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.store, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.sellerName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${product.sellerRating}', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Text('• Fulfilled by Nexus',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // REVIEWS SECTION
  // ════════════════════════════════════════════

  Widget _buildReviewsSection(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final reviews = MockData.reviews;

    if (reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Reviews', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No reviews yet', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Be the first to review'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Calculate rating breakdown
    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      ratingCounts[r.rating.round()] = (ratingCounts[r.rating.round()] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Reviews', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        // Rating Summary
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(product.rating.toString(),
                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                RatingStars(rating: product.rating, size: 16),
                const SizedBox(height: 4),
                Text('${product.reviewCount} reviews', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = ratingCounts[star] ?? 0;
                  final percent = reviews.isNotEmpty ? count / reviews.length : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('$star', style: theme.textTheme.bodySmall),
                        const SizedBox(width: 4),
                        Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.amber,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text('$count', style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Review Cards
        ...reviews.take(3).map((review) => _buildReviewCard(context, review)),

        if (reviews.length > 3)
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('See All Reviews →'),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(review.userName[0],
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        RatingStars(rating: review.rating, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          '${review.date.day}/${review.date.month}/${review.date.year}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Helpful (${review.helpfulCount})',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // RELATED PRODUCTS
  // ════════════════════════════════════════════

  Widget _buildRelatedProducts(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final allProducts = ref.watch(productsProvider).value ?? [];
    final related = allProducts
        .where((p) =>
            p.categoryId == product.categoryId && p.id != product.id)
        .take(8)
        .toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Related Products', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            var slots =
                (constraints.maxWidth / 165).floor().clamp(2, 5);
            var w = (constraints.maxWidth - 12 * (slots - 1)) / slots;
            w = math.min(200.0, math.max(132.0, w));
            final imgH = w * 0.82;
            return SizedBox(
              height: imgH + 88,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                itemBuilder: (context, index) {
                  final p = related[index];
                  return GestureDetector(
                    onTap: () => context.pushNamed('product_detail',
                        pathParameters: {'id': p.id}),
                    child: Container(
                      width: w,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              height: imgH,
                              width: w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.price.toStringAsFixed(2),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  // YOU MAY ALSO LIKE
  // ════════════════════════════════════════════

  Widget _buildYouMayAlsoLike(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final allProducts = ref.watch(productsProvider).value ?? [];
    final suggestions = allProducts
        .where((p) =>
            p.categoryId != product.categoryId && p.id != product.id)
        .take(8)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You May Also Like', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = AppBreakpoints.productGridCrossAxisCount(context);
            final ratio = count >= 4 ? 0.78 : (count >= 3 ? 0.75 : 0.72);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: ratio,
              ),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final p = suggestions[index];
                return GestureDetector(
                  onTap: () => context.pushNamed('product_detail',
                      pathParameters: {'id': p.id}),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                maxLines: count >= 3 ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    p.price.toStringAsFixed(2),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (p.discountPercent > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${p.discountPercent}% off',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  // STICKY BOTTOM BAR
  // ════════════════════════════════════════════

  Widget _buildStickyBottomBar(BuildContext context, Product product, ProductDetailUiState uiState) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return CenteredMaxWidth(
      maxWidth: AppBreakpoints.pageContentMaxWidth,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
          // Price column
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(product.price * uiState.quantity).toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )),
                if (uiState.quantity > 1)
                  Text('${uiState.quantity} items', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),

          if (!product.inStock)
            // Notify Me button
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () {
                  showAppSnackBar(context, 'We\'ll notify you when this is back in stock!');
                },
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: const Text('Notify Me'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else ...[
            // Add to Cart
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: () => _handleAddToCart(product, uiState),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: const Text('Add to Cart'),
              ),
            ),
            const SizedBox(width: 8),
            // Buy Now
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _handleBuyNow(product, uiState),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  String? _resolveProductSizeId(Product product, String? selectedSize) {
    if (selectedSize == null) return null;
    final match = product.productSizes.where((s) => s.size == selectedSize).firstOrNull;
    return match?.id;
  }

  Future<void> _handleAddToCart(Product product, ProductDetailUiState uiState) async {
    final needsSize = product.sizeType != 'NONE' &&
        product.sizeType != 'ONE_SIZE' &&
        product.productSizes.isNotEmpty;
    if (needsSize && uiState.selectedSize == null) {
      _triggerShake();
      showAppSnackBar(context, 'Please select a size');
      return;
    }

    final productSizeId = _resolveProductSizeId(product, uiState.selectedSize);

    final err = await ref.read(cartProvider.notifier).addProduct(
          product,
          size: uiState.selectedSize,
          color: product.color,
          productSizeId: productSizeId,
          qty: uiState.quantity,
        );
    if (!mounted || !context.mounted) return;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    // Clear space above sticky bottom bar so the snackbar is visible and dismisses on timer.
    final snackMargin = EdgeInsets.fromLTRB(16, 0, 16, 80 + bottomPad);
    if (err != null) {
      showAppSnackBar(context, err, margin: snackMargin);
    } else {
      showAppSnackBar(
        context,
        '${product.name} added to cart!',
        margin: snackMargin,
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            if (!context.mounted) return;
            context.pushNamed('cart');
          },
        ),
      );
    }
  }

  Future<void> _handleBuyNow(Product product, ProductDetailUiState uiState) async {
    final needsSize = product.sizeType != 'NONE' &&
        product.sizeType != 'ONE_SIZE' &&
        product.productSizes.isNotEmpty;
    if (needsSize && uiState.selectedSize == null) {
      _triggerShake();
      showAppSnackBar(context, 'Please select a size');
      return;
    }

    final productSizeId = _resolveProductSizeId(product, uiState.selectedSize);

    final err = await ref.read(cartProvider.notifier).addProduct(
          product,
          size: uiState.selectedSize,
          color: product.color,
          productSizeId: productSizeId,
          qty: uiState.quantity,
        );
    if (!mounted || !context.mounted) return;
    if (err != null) {
      final bottomPad = MediaQuery.paddingOf(context).bottom;
      showAppSnackBar(
        context,
        err,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 80 + bottomPad),
      );
    } else {
      context.pushNamed('checkout');
    }
  }

  // ════════════════════════════════════════════
  // SHIMMER LOADING
  // ════════════════════════════════════════════

  Widget _buildShimmerDetail(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: double.infinity, height: 380),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 100, height: 14),
                SizedBox(height: 8),
                ShimmerLoading(width: 250, height: 28),
                SizedBox(height: 8),
                ShimmerLoading(width: 150, height: 18),
                SizedBox(height: 16),
                ShimmerLoading(width: 200, height: 32),
                SizedBox(height: 24),
                ShimmerLoading(width: double.infinity, height: 100),
                SizedBox(height: 16),
                ShimmerLoading(width: double.infinity, height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

