import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_layout.dart';
import '../../models/product_model.dart';
import '../../widgets/shimmer_loading.dart';
import '../home/providers/product_providers.dart';

class SubcategoryScreen extends ConsumerWidget {
  final String category;
  const SubcategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsByCategoryProvider(category));
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryName = categoriesAsync.when(
      data: (cats) {
        final match = cats.where((c) => c.id == category);
        return match.isNotEmpty ? match.first.name : 'Category';
      },
      loading: () => 'Category',
      error: (_, __) => 'Category',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: productsAsync.when(
        loading: () => _buildShimmer(context),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Failed to load products',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(productsByCategoryProvider(category)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (products) => CenteredMaxWidth(
              maxWidth: AppBreakpoints.pageContentMaxWidth,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text('Categories',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey.shade400),
                          Text(categoryName,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('${products.length} Products',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: products.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text('No products in this category',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: AppBreakpoints
                                  .productGridCrossAxisCount(context),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio:
                                  AppBreakpoints.productGridCrossAxisCount(
                                              context) >=
                                          3
                                      ? 0.68
                                      : 0.62,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildProductCard(
                                  context, theme, products[index]),
                              childCount: products.length,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, ThemeData theme, Product product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUri,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (c1, c2, c3) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (product.rating > 0)
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade600),
                          const SizedBox(width: 2),
                          Text(product.rating.toString(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text('${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return CenteredMaxWidth(
      maxWidth: AppBreakpoints.pageContentMaxWidth,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count =
                AppBreakpoints.productGridCrossAxisCount(context);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: count >= 3 ? 0.68 : 0.62,
              ),
              itemCount: 6,
              itemBuilder: (_, i) => const ShimmerLoading(
                  width: double.infinity, height: double.infinity),
            );
          },
        ),
      ),
    );
  }
}
