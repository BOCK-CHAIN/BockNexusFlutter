import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_layout.dart';
import '../home/providers/shopping_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(wishlistProvider.notifier).fetchWishlist());
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = ref.watch(wishlistProvider);
    final sort = ref.watch(wishlistSortProvider);
    final sorted = ref.read(wishlistProvider.notifier).sorted(sort);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist (${wishlist.length})'),
        actions: [
          if (wishlist.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                showAppSnackBar(context, 'Wishlist share link copied!');
              },
            ),
        ],
      ),
      body: wishlist.isEmpty
          ? _buildEmpty(context)
          : Center(
              child: CenteredMaxWidth(
                maxWidth: AppBreakpoints.pageContentMaxWidth,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Text('Sort by:', style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: WishlistSort.values.map((s) {
                                  final selected = sort == s;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(_sortLabel(s)),
                                      selected: selected,
                                      onSelected: (_) => ref
                                          .read(wishlistSortProvider.notifier)
                                          .set(s),
                                      selectedColor: theme
                                          .colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      labelStyle: TextStyle(
                                        color: selected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                        fontSize: 12,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            ref.read(wishlistProvider.notifier).fetchWishlist(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: AppBreakpoints
                                .productGridCrossAxisCount(context),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            return _buildWishlistCard(
                                context, ref, sorted[index]);
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              for (final item in wishlist) {
                                await ref.read(cartProvider.notifier).addProduct(
                                      item.product,
                                      productSizeId: item.productSizeId,
                                    );
                              }
                              if (!context.mounted) return;
                              showAppSnackBar(
                                  context, 'All items moved to cart!');
                            },
                            icon: const Icon(Icons.shopping_cart_outlined,
                                size: 18),
                            label: const Text('Move All to Cart'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 80,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            Text('Your wishlist is empty',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Save items you love to your wishlist',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start Wishlisting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, WidgetRef ref, WishlistItem item) {
    final theme = Theme.of(context);
    final product = item.product;
    final isOutOfStock = !product.inStock;

    return GestureDetector(
      onTap: () => context.pushNamed('product_detail', pathParameters: {'id': product.id}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(14)),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      if (isOutOfStock)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Out of Stock',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Row(
                          children: [
                            Text('${product.price.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                )),
                            if (product.originalPrice > product.price) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('${product.originalPrice.toStringAsFixed(2)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                    )),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isOutOfStock
                                ? null
                                : () async {
                                    final err = await ref
                                        .read(cartProvider.notifier)
                                        .addProduct(
                                          product,
                                          productSizeId: item.productSizeId,
                                        );
                                    if (!context.mounted) return;
                                    showAppSnackBar(context, err ?? '${product.title} moved to cart');
                                  },
                            icon: const Icon(Icons.shopping_cart_outlined, size: 14),
                            label: const Text('Move to Cart',
                                style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () async {
                  final err =
                      await ref.read(wishlistProvider.notifier).remove(product.id);
                  if (err != null && context.mounted) {
                    showAppSnackBar(context, err);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(WishlistSort sort) {
    switch (sort) {
      case WishlistSort.dateAdded:
        return 'Date Added';
      case WishlistSort.priceLowHigh:
        return 'Price: Low';
      case WishlistSort.priceHighLow:
        return 'Price: High';
      case WishlistSort.name:
        return 'Name';
    }
  }
}
