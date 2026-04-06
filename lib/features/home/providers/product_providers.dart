import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/category_service.dart';
import '../../../core/network/product_service.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';

// ─── Categories (cached — won't re-fetch on every rebuild) ───

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return CategoryService().getAllCategories();
});

// ─── Home-screen random products ───

final homeProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ProductService().getRandomProducts();
});

// ─── All products (for filter preview count, etc.) ───

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ProductService().getAllProducts();
});

// ─── Product Detail ───

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  return ProductService().getProductById(id);
});

// ─── Selected Category (stores category id; 'All' = show all) ───

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
        SelectedCategoryNotifier.new);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}

// ─── Products filtered by selected category ───

final categoryProductsProvider = FutureProvider<List<Product>>((ref) async {
  final selectedCat = ref.watch(selectedCategoryProvider);
  if (selectedCat == 'All') {
    return ProductService().getAllProducts();
  }
  return ProductService().getProductsByCategory(selectedCat);
});

// ─── Products by a specific category id ───

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  return ProductService().getProductsByCategory(categoryId);
});

// ─── Trending (random products sorted by rating) ───

final trendingProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(homeProductsProvider.future);
  final sorted = List<Product>.from(products)
    ..sort((a, b) => b.rating.compareTo(a.rating));
  return sorted;
});

// ─── Flash Sale (random products as promotion) ───

final flashSaleProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(homeProductsProvider.future);
  return products.take(5).toList();
});

// ─── Offline mock ───

final isOfflineProvider =
    NotifierProvider<IsOfflineNotifier, bool>(IsOfflineNotifier.new);

class IsOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}
