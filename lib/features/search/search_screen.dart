import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mock_data.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';
import 'providers/search_providers.dart';
import 'filter_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _searchCtrl.text = ref.read(searchQueryProvider);
  }

  void _onChanged(String val) {
    setState(() {}); // trigger rebuild for clear button
    _debounce?.cancel();
    if (val.trim().length <= 1) {
      ref.read(searchQueryProvider.notifier).set('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).set(val);
    });
  }

  void _searchFromChip(String term) {
    _searchCtrl.text = term;
    ref.read(searchQueryProvider.notifier).set(term);
    ref.read(recentSearchesProvider.notifier).add(term);
  }

  void _submitSearch(String val) {
    if (val.trim().length > 1) {
      ref.read(recentSearchesProvider.notifier).add(val.trim());
    }
  }

  List<Product> _sortProducts(List<Product> products, SortOption sort) {
    final sorted = List<Product>.from(products);
    switch (sort) {
      case SortOption.priceLowHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.relevance:
        break;
    }
    return sorted;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final recentSearches = ref.watch(recentSearchesProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final filterState = ref.watch(filterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onSubmitted: _submitSearch,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(searchQueryProvider.notifier).set('');
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const FilterBottomSheet(),
                  );
                },
              ),
              if (filterState.activeFilterCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      filterState.activeFilterCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: query.trim().length <= 1
          ? _buildIdleState(context, recentSearches)
          : resultsAsync.when(
              loading: () => _buildSearchShimmer(),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (results) {
                var filtered = applyFiltersPublic(results, filterState);
                filtered = _sortProducts(filtered, sortOption);

                if (filtered.isEmpty) {
                  return _buildNoResults(context, query);
                }
                return _buildResults(context, filtered, sortOption);
              },
            ),
    );
  }

  Widget _buildIdleState(BuildContext context, List<String> recent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => ref.read(recentSearchesProvider.notifier).clearAll(),
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recent.map(
              (s) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, size: 20),
                title: Text(s),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => ref.read(recentSearchesProvider.notifier).remove(s),
                ),
                onTap: () => _searchFromChip(s),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Trending Searches', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.trendingSearches
                .map(
                  (t) => ActionChip(
                    label: Text(t),
                    onPressed: () => _searchFromChip(t),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 72, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text("No results for '$query'", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Try these instead:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MockData.trendingSearches.take(4).map(
                (t) => ActionChip(label: Text(t), onPressed: () => _searchFromChip(t)),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<Product> products, SortOption sort) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${products.length} results', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<SortOption>(
                  value: sort,
                  isDense: true,
                  style: Theme.of(context).textTheme.bodySmall,
                  items: const [
                    DropdownMenuItem(value: SortOption.relevance, child: Text('Relevance')),
                    DropdownMenuItem(value: SortOption.priceLowHigh, child: Text('Price: Low-High')),
                    DropdownMenuItem(value: SortOption.priceHighLow, child: Text('Price: High-Low')),
                    DropdownMenuItem(value: SortOption.rating, child: Text('Rating')),
                    DropdownMenuItem(value: SortOption.newest, child: Text('Newest')),
                  ],
                  onChanged: (v) {
                    if (v != null) ref.read(sortOptionProvider.notifier).set(v);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    heroTag: 'search_${product.id}',
                    onTap: () => context.pushNamed('product_detail', pathParameters: {'id': product.id}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (_, i) => const ShimmerLoading(width: double.infinity, height: double.infinity),
      ),
    );
  }
}
