import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/admin_service.dart';
import '../../../models/category_model.dart';

// ══════════════════════════════════════════════
// STATE CLASSES
// ══════════════════════════════════════════════

class AdminCategoriesState {
  final bool isLoading;
  final String? error;
  final List<Category> categories;

  const AdminCategoriesState({
    this.isLoading = false,
    this.error,
    this.categories = const [],
  });

  AdminCategoriesState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Category>? categories,
  }) {
    return AdminCategoriesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      categories: categories ?? this.categories,
    );
  }
}

class AdminCategoryEditorState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Category? category;

  const AdminCategoryEditorState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.category,
  });

  AdminCategoryEditorState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    Category? category,
    bool clearCategory = false,
    bool clearError = false,
  }) {
    return AdminCategoryEditorState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

// ══════════════════════════════════════════════
// CATEGORIES LIST PROVIDER
// ══════════════════════════════════════════════

final adminCategoriesProvider =
    NotifierProvider<AdminCategoriesNotifier, AdminCategoriesState>(
        AdminCategoriesNotifier.new);

class AdminCategoriesNotifier extends Notifier<AdminCategoriesState> {
  late final AdminService _service;

  @override
  AdminCategoriesState build() {
    _service = AdminService();
    // Keep data alive so the list doesn't re-fetch on every navigation back.
    ref.keepAlive();
    // Use microtask so build() returns first and sets the initial state;
    // _fetchCategories reads `state` which would be uninitialized if called
    // synchronously here.
    Future.microtask(_fetchCategories);
    return const AdminCategoriesState(isLoading: true);
  }

  Future<void> _fetchCategories() async {
    // Only set loading if not already in that state (avoids unnecessary rebuilds
    // when called from build() via microtask where state is already loading).
    if (!state.isLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final categories = await _service.getCategories();
      state = state.copyWith(isLoading: false, categories: categories);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetchCategories();

  Future<bool> deleteCategory(String id) async {
    try {
      await _service.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ══════════════════════════════════════════════
// CATEGORY EDITOR PROVIDER
// ══════════════════════════════════════════════

final adminCategoryEditorProvider =
    NotifierProvider<AdminCategoryEditorNotifier, AdminCategoryEditorState>(
        AdminCategoryEditorNotifier.new);

class AdminCategoryEditorNotifier extends Notifier<AdminCategoryEditorState> {
  late final AdminService _service;

  @override
  AdminCategoryEditorState build() {
    _service = AdminService();
    return const AdminCategoryEditorState();
  }

  /// Call from screen initState to load an existing category.
  Future<void> loadCategory(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCategory: true,
    );
    try {
      final category = await _service.getCategory(id);
      state = state.copyWith(
        isLoading: false,
        category: category,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearCategory: true,
      );
    }
  }

  /// Reset state for create mode or when leaving screen.
  void reset() {
    state = const AdminCategoryEditorState();
  }

  Future<bool> createCategory(Map<String, dynamic> body) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _service.createCategory(body);
      state = state.copyWith(isSaving: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> body) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _service.updateCategory(id, body);
      state = state.copyWith(isSaving: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
