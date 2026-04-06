import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/product_service.dart';
import '../../../models/product_model.dart';

// ─── Search Query ───
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

// ─── Recent Searches (mock local) ───
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
        RecentSearchesNotifier.new);

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [trimmed, ...state.where((s) => s != trimmed)].take(10).toList();
  }

  void remove(String query) {
    state = state.where((s) => s != query).toList();
  }

  void clearAll() {
    state = [];
  }
}

// ─── Search Results (real API) ───
final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length <= 1) return [];
  return ProductService().searchProducts(query);
});

// ─── Sort ───
enum SortOption { relevance, priceLowHigh, priceHighLow, rating, newest }

final sortOptionProvider =
    NotifierProvider<SortOptionNotifier, SortOption>(SortOptionNotifier.new);

class SortOptionNotifier extends Notifier<SortOption> {
  @override
  SortOption build() => SortOption.relevance;
  void set(SortOption value) => state = value;
}

// ─── Filters ───
class FilterState {
  final Set<String> selectedCategories;
  final double minPrice;
  final double maxPrice;
  final Set<String> selectedBrands;
  final double minRating;
  final bool inStockOnly;

  const FilterState({
    this.selectedCategories = const {},
    this.minPrice = 0,
    this.maxPrice = 50000,
    this.selectedBrands = const {},
    this.minRating = 0,
    this.inStockOnly = false,
  });

  int get activeFilterCount {
    int count = 0;
    if (selectedCategories.isNotEmpty) count++;
    if (minPrice > 0 || maxPrice < 50000) count++;
    if (selectedBrands.isNotEmpty) count++;
    if (minRating > 0) count++;
    if (inStockOnly) count++;
    return count;
  }

  FilterState copyWith({
    Set<String>? selectedCategories,
    double? minPrice,
    double? maxPrice,
    Set<String>? selectedBrands,
    double? minRating,
    bool? inStockOnly,
  }) {
    return FilterState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      minRating: minRating ?? this.minRating,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}

final filterProvider =
    NotifierProvider<FilterNotifier, FilterState>(FilterNotifier.new);

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void toggleCategory(String cat) {
    final cats = Set<String>.from(state.selectedCategories);
    cats.contains(cat) ? cats.remove(cat) : cats.add(cat);
    state = state.copyWith(selectedCategories: cats);
  }

  void setPriceRange(double min, double max) {
    final correctedMin = min > max ? max : min;
    state = state.copyWith(minPrice: correctedMin, maxPrice: max);
  }

  void toggleBrand(String brand) {
    final brands = Set<String>.from(state.selectedBrands);
    brands.contains(brand) ? brands.remove(brand) : brands.add(brand);
    state = state.copyWith(selectedBrands: brands);
  }

  void setMinRating(double r) {
    state = state.copyWith(minRating: r);
  }

  void toggleInStockOnly() {
    state = state.copyWith(inStockOnly: !state.inStockOnly);
  }

  void reset() {
    state = const FilterState();
  }
}

// ─── Filtered result count preview (client-side from loaded products) ───
final filteredProductCountProvider = Provider<int>((ref) {
  final filter = ref.watch(filterProvider);
  final productsAsync = ref.watch(searchResultsProvider);
  return productsAsync.when(
    data: (products) => applyFiltersPublic(products, filter).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

List<Product> _applyFilters(List<Product> products, FilterState f) {
  return products.where((p) {
    if (f.selectedCategories.isNotEmpty &&
        !f.selectedCategories.contains(p.categoryName)) return false;
    if (p.price < f.minPrice || p.price > f.maxPrice) return false;
    if (f.selectedBrands.isNotEmpty &&
        !f.selectedBrands.contains(p.brand ?? '')) return false;
    if (p.rating < f.minRating) return false;
    if (f.inStockOnly && !p.inStock) return false;
    return true;
  }).toList();
}

List<Product> applyFiltersPublic(List<Product> products, FilterState f) =>
    _applyFilters(products, f);
