import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_layout.dart';
import '../../widgets/shimmer_loading.dart';
import '../home/providers/product_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => CenteredMaxWidth(
          maxWidth: AppBreakpoints.pageContentMaxWidth,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  AppBreakpoints.categoryGridCrossAxisCount(context),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: 6,
            itemBuilder: (_, i) =>
                const ShimmerLoading(
                    width: double.infinity, height: double.infinity),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Failed to load categories',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categories) => CenteredMaxWidth(
          maxWidth: AppBreakpoints.pageContentMaxWidth,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  AppBreakpoints.categoryGridCrossAxisCount(context),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryCard(context, theme, cat.id, cat.name,
                  cat.imageUri, cat.productCount);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ThemeData theme, String id,
      String name, String imageUri, int productCount) {
    return GestureDetector(
      onTap: () => context.push('/categories/$id'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUri,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ShimmerLoading(width: 56, height: 56),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.category, size: 40),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$productCount products',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
