import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mock_data.dart';
import '../../core/layout/responsive_layout.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';
import 'providers/product_providers.dart';
import 'providers/shopping_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerPage = 0;

  late DateTime _flashSaleEnd;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _flashSaleEnd = DateTime.now().add(const Duration(hours: 5, minutes: 30));
    _startCountdown();
    _startBannerAutoScroll();
  }

  void _startCountdown() {
    _remaining = _flashSaleEnd.difference(DateTime.now());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final diff = _flashSaleEnd.difference(DateTime.now());
      if (diff.isNegative) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = diff);
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _bannerPage = (_bannerPage + 1) % MockData.banners.length;
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _bannerPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final cartState = ref.watch(cartProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoryProductsAsync = ref.watch(categoryProductsProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final flashSaleAsync = ref.watch(flashSaleProductsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeProductsProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(categoryProductsProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: homeAsync.when(
          loading: () => _buildShimmer(context),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (_) => CenteredMaxWidth(
            maxWidth: AppBreakpoints.pageContentMaxWidth,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ─── SliverAppBar ───
                SliverAppBar(
                floating: true,
                snap: true,
                title: Text('Nexus',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                actions: [
                  IconButton(
                    icon: Badge(
                      label: Text(cartState.items.length.toString()),
                      isLabelVisible: cartState.items.isNotEmpty,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    onPressed: () => context.pushNamed('cart'),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      onTap: () => context.pushNamed('search'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.search,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5)),
                            const SizedBox(width: 8),
                            Text('Search products...',
                                style: TextStyle(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Offline banner ───
              if (isOffline)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.orange.shade100,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('You are offline. Showing cached content.',
                            style: TextStyle(
                                color: Colors.orange, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

              // ─── Location selector ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: MockData.cities.first,
                          isDense: true,
                          items: MockData.cities
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style:
                                          const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Category chips (from API) ───
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: categoriesAsync.when(
                    loading: () => const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (categories) {
                      final allCategories = [
                        'All',
                        ...categories.map((c) => c.id)
                      ];
                      final categoryNames = {
                        'All': 'All',
                        for (final c in categories) c.id: c.name,
                      };
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allCategories.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final catId = allCategories[index];
                          final catName =
                              categoryNames[catId] ?? catId;
                          final selected = selectedCategory == catId;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(selectedCategoryProvider.notifier)
                                  .set(catId);
                            },
                            child: Chip(
                              label: Text(catName),
                              backgroundColor: selected
                                  ? colorScheme.primary
                                  : colorScheme.surface,
                              labelStyle: TextStyle(
                                color: selected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.outline
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // ─── Banner Carousel ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: PageView.builder(
                          controller: _bannerController,
                          itemCount: MockData.banners.length,
                          onPageChanged: (i) =>
                              setState(() => _bannerPage = i),
                          itemBuilder: (context, index) {
                            final banner = MockData.banners[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(
                                        int.parse(banner['color']!)),
                                    Color(int.parse(
                                            banner['color']!))
                                        .withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    banner['title']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner['subtitle']!,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          MockData.banners.length,
                          (i) => AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: _bannerPage == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _bannerPage == i
                                  ? colorScheme.primary
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Flash Sale ───
              ..._buildFlashSale(context, flashSaleAsync),

              // ─── Trending Now ───
              ..._buildTrending(context, trendingAsync),

              // ─── For You header ───
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text('For You',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),

              // ─── For You grid — category filtered (async) ───
              ...categoryProductsAsync.when(
                loading: () => [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: CircularProgressIndicator()),
                    ),
                  ),
                ],
                error: (e, _) => [
                  SliverToBoxAdapter(
                    child: Center(child: Text('Error: $e')),
                  ),
                ],
                data: (categoryProducts) {
                  if (categoryProducts.isEmpty) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.search_off,
                                  size: 64,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('No products found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref
                                    .read(selectedCategoryProvider
                                        .notifier)
                                    .set('All'),
                                child: const Text(
                                    'View All Products'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  }
                  return [
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppBreakpoints.productGridCrossAxisCount(context),
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = categoryProducts[index];
                            return ProductCard(
                              product: product,
                              heroTag: 'forYou_${product.id}',
                              onTap: () => context.pushNamed(
                                  'product_detail',
                                  pathParameters: {
                                    'id': product.id
                                  }),
                            );
                          },
                          childCount: categoryProducts.length,
                        ),
                      ),
                    ),
                  ];
                },
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 24)),
            ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFlashSale(
      BuildContext context, AsyncValue<List<Product>> flashSaleAsync) {
    return flashSaleAsync.when(
      loading: () => [],
      error: (_, __) => [],
      data: (flashSaleProducts) {
        if (_remaining <= Duration.zero || flashSaleProducts.isEmpty) return [];
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on,
                          color: Colors.orange, size: 22),
                      const SizedBox(width: 4),
                      Text('Flash Sale',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(_remaining),
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: flashSaleProducts.length,
                      separatorBuilder: (_, i) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = flashSaleProducts[index];
                        return SizedBox(
                          width: 160,
                          child: ProductCard(
                            product: product,
                            heroTag: 'flash_${product.id}',
                            onTap: () => context.pushNamed(
                                'product_detail',
                                pathParameters: {'id': product.id}),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _buildTrending(
      BuildContext context, AsyncValue<List<Product>> trendingAsync) {
    return trendingAsync.when(
      loading: () => [],
      error: (_, __) => [],
      data: (trendingProducts) {
        if (trendingProducts.isEmpty) return [];
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trending Now',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: trendingProducts.length,
                      separatorBuilder: (_, i) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = trendingProducts[index];
                        return SizedBox(
                          width: 160,
                          child: ProductCard(
                            product: product,
                            heroTag: 'trending_${product.id}',
                            onTap: () => context.pushNamed(
                                'product_detail',
                                pathParameters: {'id': product.id}),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return CenteredMaxWidth(
      maxWidth: AppBreakpoints.pageContentMaxWidth,
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const ShimmerLoading(width: double.infinity, height: 44),
            const SizedBox(height: 16),
            const ShimmerLoading(width: double.infinity, height: 48),
            const SizedBox(height: 16),
            const ShimmerLoading(width: double.infinity, height: 160),
            const SizedBox(height: 24),
            const ShimmerLoading(width: 150, height: 24),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    const ShimmerLoading(width: 160, height: 200),
              ),
            ),
            const SizedBox(height: 24),
            const ShimmerLoading(width: 150, height: 24),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppBreakpoints.productGridCrossAxisCount(context),
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (_, i) => const ShimmerLoading(
                  width: double.infinity, height: double.infinity),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
