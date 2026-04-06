import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/admin_service.dart';
import '../../../models/product_model.dart';

// ══════════════════════════════════════════════
// STATE CLASSES
// ══════════════════════════════════════════════

class AdminProductsState {
  final bool isLoading;
  final String? error;
  final List<Product> products;

  const AdminProductsState({
    this.isLoading = false,
    this.error,
    this.products = const [],
  });

  AdminProductsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Product>? products,
  }) {
    return AdminProductsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      products: products ?? this.products,
    );
  }
}

class AdminProductEditorState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Product? product;
  final List<StockRow> stockRows;

  const AdminProductEditorState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.product,
    this.stockRows = const [],
  });

  AdminProductEditorState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    Product? product,
    List<StockRow>? stockRows,
  }) {
    return AdminProductEditorState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      product: product ?? this.product,
      stockRows: stockRows ?? this.stockRows,
    );
  }
}

/// Editable row for stock management.
class StockRow {
  final String? id;
  final String size;
  final int stock;
  final int sortOrder;

  const StockRow({
    this.id,
    this.size = '',
    this.stock = 0,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'size': size,
      'stock': stock,
      'sortOrder': sortOrder,
    };
    if (id != null) map['id'] = int.tryParse(id!) ?? id;
    return map;
  }
}

// ══════════════════════════════════════════════
// PRODUCTS LIST PROVIDER
// ══════════════════════════════════════════════

final adminProductsProvider =
    NotifierProvider<AdminProductsNotifier, AdminProductsState>(
        AdminProductsNotifier.new);

class AdminProductsNotifier extends Notifier<AdminProductsState> {
  late final AdminService _service;

  @override
  AdminProductsState build() {
    _service = AdminService();
    // Keep data alive so navigating away and back doesn't re-trigger a fetch.
    // Data is refreshed via explicit refresh() calls after create/update/delete.
    ref.keepAlive();
    // Use microtask so build() returns first and the initial state is set before
    // _fetchProducts() tries to read `state`.
    Future.microtask(_fetchProducts);
    return const AdminProductsState(isLoading: true);
  }

  Future<void> _fetchProducts() async {
    if (!state.isLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final products = await _service.getProducts();
      state = state.copyWith(isLoading: false, products: products);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetchProducts();

  Future<bool> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      state = state.copyWith(
        products: state.products.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ══════════════════════════════════════════════
// PRODUCT EDITOR PROVIDER
// ══════════════════════════════════════════════

final adminProductEditorProvider =
    NotifierProvider<AdminProductEditorNotifier, AdminProductEditorState>(
        AdminProductEditorNotifier.new);

class AdminProductEditorNotifier extends Notifier<AdminProductEditorState> {
  late final AdminService _service;

  @override
  AdminProductEditorState build() {
    _service = AdminService();
    return const AdminProductEditorState();
  }

  /// Call this from the screen's initState to load an existing product.
  Future<void> loadProduct(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final product = await _service.getProduct(id);
      final rows = product.productSizes
          .map((s) => StockRow(
                id: s.id,
                size: s.size,
                stock: s.stock,
                sortOrder: s.sortOrder,
              ))
          .toList();
      state = state.copyWith(
        isLoading: false,
        product: product,
        stockRows: rows,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reset state (call when entering create mode or leaving the screen).
  void reset() {
    state = const AdminProductEditorState();
  }

  /// Creates a product and then saves stock rows.
  Future<String?> createProduct(
      Map<String, dynamic> body, List<StockRow> stockRows) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final product = await _service.createProduct(body);
      if (stockRows.isNotEmpty) {
        await _service.updateProductStock(
          product.id,
          stockRows.map((r) => r.toJson()).toList(),
        );
      }
      state = state.copyWith(isSaving: false);
      return product.id;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  /// Updates a product and then saves stock rows.
  Future<bool> updateProduct(
      String id, Map<String, dynamic> body, List<StockRow> stockRows) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _service.updateProduct(id, body);
      await _service.updateProductStock(
        id,
        stockRows.map((r) => r.toJson()).toList(),
      );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
