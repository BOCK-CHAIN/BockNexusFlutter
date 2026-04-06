import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/layout/responsive_layout.dart';
import '../../../core/network/admin_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/admin_category_providers.dart';
import '../providers/admin_product_providers.dart';
import 'package:go_router/go_router.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────

bool _isUnassigned(Product p) {
  final cid = p.categoryId;
  return cid.isEmpty || cid == 'null' || cid == '0';
}

dynamic _parseCatId(String? id) {
  if (id == null) return null;
  return int.tryParse(id) ?? id;
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class AdminCategoryEditorScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const AdminCategoryEditorScreen({super.key, this.categoryId});

  bool get isEditMode => categoryId != null;

  @override
  ConsumerState<AdminCategoryEditorScreen> createState() =>
      _AdminCategoryEditorScreenState();
}

class _AdminCategoryEditorScreenState
    extends ConsumerState<AdminCategoryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _imageUriCtrl;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _imageUriCtrl = TextEditingController();
    _imageUriCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catNotifier = ref.read(adminCategoryEditorProvider.notifier);
      catNotifier.reset();
      if (widget.categoryId != null) {
        catNotifier.loadCategory(widget.categoryId!);
      }
      // Bug fix: ensure products provider is populated
      final ps = ref.read(adminProductsProvider);
      if (!ps.isLoading && ps.products.isEmpty) {
        ref.read(adminProductsProvider.notifier).refresh();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdminCategoryEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _prefilled = false;
      _nameCtrl.clear();
      _imageUriCtrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final n = ref.read(adminCategoryEditorProvider.notifier);
        n.reset();
        if (widget.categoryId != null) n.loadCategory(widget.categoryId!);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageUriCtrl.dispose();
    super.dispose();
  }

  void _prefillFromState(AdminCategoryEditorState s) {
    if (_prefilled || s.category == null || s.isLoading) return;
    _prefilled = true;
    _nameCtrl.text = s.category!.name;
    _imageUriCtrl.text = s.category!.imageUri;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(adminCategoryEditorProvider);
    final theme = Theme.of(context);

    if (widget.isEditMode && !_prefilled && !editorState.isLoading) {
      _prefillFromState(editorState);
    }

    final loaded = editorState.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Category' : 'New Category'),
      ),
      body: editorState.isLoading && widget.isEditMode
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CenteredMaxWidth(
                maxWidth: AppBreakpoints.pageContentMaxWidth,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // ─── Edit-mode header ───
                    if (widget.isEditMode && loaded != null) ...[
                      _CategoryDetailsCard(category: loaded),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Add product in this category',
                        onPressed: () async {
                          // Ensure categories map is available for labels
                          final cs = ref.read(adminCategoriesProvider);
                          if (cs.categories.isEmpty && !cs.isLoading) {
                            await ref
                                .read(adminCategoriesProvider.notifier)
                                .refresh();
                          }
                          if (!mounted) return;
                          await _showAddProductsSheet(
                              context, ref, loaded.id);
                          // Refresh count after sheet closes
                          if (mounted) {
                            ref
                                .read(adminProductsProvider.notifier)
                                .refresh();
                            ref
                                .read(adminCategoryEditorProvider.notifier)
                                .loadCategory(loaded.id);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      widget.isEditMode
                          ? 'Update name and image URL. Changes apply to the category shown above.'
                          : 'Create a new category. Add a name and image URL.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (widget.isEditMode && loaded != null) ...[
                      _CategoryProductsSection(categoryId: loaded.id),
                      const SizedBox(height: 24),
                    ],

                    // ─── Form fields ───
                    AppTextField(
                      labelText: 'Name',
                      hintText: 'Category name',
                      controller: _nameCtrl,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      labelText: 'Image URI',
                      hintText: 'https://...',
                      controller: _imageUriCtrl,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Preview',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final url = _imageUriCtrl.text.trim();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: url.isEmpty
                                ? Container(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Enter an image URL to preview',
                                      style: theme.textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : SizedBox.expand(
                                    child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    placeholder: (_, __) => Container(
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: double.infinity,
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_outlined,
                                              color: theme.colorScheme.error),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              'Could not load image (check URL or CORS on web)',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurfaceVariant,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                    ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    if (editorState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(editorState.error!,
                            style:
                                TextStyle(color: theme.colorScheme.error)),
                      ),
                    AppButton(
                      text: widget.isEditMode
                          ? 'Update Category'
                          : 'Create Category',
                      isLoading: editorState.isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'image_uri': _imageUriCtrl.text.trim(),
    };
    final notifier = ref.read(adminCategoryEditorProvider.notifier);
    if (widget.isEditMode) {
      final ok = await notifier.updateCategory(widget.categoryId!, body);
      if (mounted) {
        showAppSnackBar(context,
            ok ? 'Category updated successfully' : 'Failed to update category');
        if (ok) Navigator.pop(context);
      }
    } else {
      final ok = await notifier.createCategory(body);
      if (mounted) {
        showAppSnackBar(context,
            ok ? 'Category added successfully' : 'Failed to create category');
        if (ok) {
          notifier.reset();
          Navigator.pop(context);
        }
      }
    }
  }
}

// ─── Category details card ────────────────────────────────────────────────────

class _CategoryDetailsCard extends ConsumerWidget {
  final Category category;
  const _CategoryDetailsCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Live count from products provider (updates after each operation)
    final count = ref
        .watch(adminProductsProvider.select((s) =>
            s.products.where((p) => p.categoryId == category.id).length));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category details',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('ID: ${category.id}', style: theme.textTheme.bodyMedium),
            Text(
              '$count products in this category',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Products section (AnimatedList) ─────────────────────────────────────────

class _CategoryProductsSection extends ConsumerStatefulWidget {
  final String categoryId;
  const _CategoryProductsSection({required this.categoryId});

  @override
  ConsumerState<_CategoryProductsSection> createState() =>
      _CategoryProductsSectionState();
}

class _CategoryProductsSectionState
    extends ConsumerState<_CategoryProductsSection> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _products = <Product>[];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(adminProductsProvider);
      if (!s.isLoading && s.products.isEmpty) {
        // Trigger load – listener in build will sync when it completes
        ref.read(adminProductsProvider.notifier).refresh();
      } else if (!s.isLoading && s.products.isNotEmpty) {
        _initList(s.products);
      }
    });
  }

  void _initList(List<Product> all) {
    if (_initialized) return;
    _initialized = true;
    final filtered =
        all.where((p) => p.categoryId == widget.categoryId).toList();
    if (mounted) setState(() => _products.addAll(filtered));
  }

  void _syncProducts(List<Product> freshAll) {
    if (!mounted) return;
    final fresh =
        freshAll.where((p) => p.categoryId == widget.categoryId).toList();
    final freshIds = {for (final p in fresh) p.id};
    final currentIds = {for (final p in _products) p.id};

    // Remove stale items (reverse to preserve indices)
    for (int i = _products.length - 1; i >= 0; i--) {
      if (!freshIds.contains(_products[i].id)) {
        final removed = _products[i];
        _products.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, anim) => _buildTile(removed, anim),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // Insert new items
    for (final p in fresh) {
      if (!currentIds.contains(p.id)) {
        final idx = _products.length;
        _products.add(p);
        _listKey.currentState?.insertItem(idx,
            duration: const Duration(milliseconds: 250));
      }
    }

    if (!_initialized) _initialized = true;
  }

  /// Optimistically remove a product (called by swap icon before refresh).
  void _removeProduct(Product p) {
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx == -1) return;
    _products.removeAt(idx);
    _listKey.currentState?.removeItem(
      idx,
      (ctx, anim) => _buildTile(p, anim),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildTile(Product p, Animation<double> anim) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: anim,
        child: _ProductTile(
          product: p,
          categoryId: widget.categoryId,
          onMoved: () => _removeProduct(p),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading =
        ref.watch(adminProductsProvider.select((s) => s.isLoading));

    // Sync whenever the products state updates
    ref.listen<AdminProductsState>(adminProductsProvider, (_, next) {
      if (!next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_initialized) {
            _initList(next.products);
          } else {
            _syncProducts(next.products);
          }
        });
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products in this category (${_products.length})',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isLoading && _products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_products.isEmpty)
          Text(
            'No products currently assigned. Use "Add product in this category" above.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          AnimatedList(
            key: _listKey,
            initialItemCount: _products.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, idx, anim) {
              if (idx >= _products.length) return const SizedBox.shrink();
              return _buildTile(_products[idx], anim);
            },
          ),
      ],
    );
  }
}

// ─── Product tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Product product;
  final String categoryId;
  final VoidCallback onMoved;

  const _ProductTile({
    required this.product,
    required this.categoryId,
    required this.onMoved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          product.imageUri,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 46,
            height: 46,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported_outlined, size: 20),
          ),
        ),
      ),
      title: Text(product.name,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '₹${product.price.toStringAsFixed(2)}',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
      onTap: () => context.push(
        '/admin/products/${product.id}',
        extra: {'categoryId': product.categoryId},
      ),
      trailing: Consumer(builder: (ctx, ref, _) {
        return IconButton(
          tooltip: 'Move to another category',
          icon: const Icon(Icons.swap_horiz_outlined),
          onPressed: () =>
              _showMoveBottomSheet(ctx, ref, product, categoryId, onMoved),
        );
      }),
    );
  }
}

// ─── Move-to-category bottom sheet ───────────────────────────────────────────

Future<void> _showMoveBottomSheet(
  BuildContext context,
  WidgetRef ref,
  Product product,
  String currentCategoryId,
  VoidCallback onMoved,
) async {
  // Ensure categories are loaded
  final cs = ref.read(adminCategoriesProvider);
  if (cs.categories.isEmpty && !cs.isLoading) {
    await ref.read(adminCategoriesProvider.notifier).refresh();
  }
  if (!context.mounted) return;

  final others = ref
      .read(adminCategoriesProvider)
      .categories
      .where((c) => c.id != currentCategoryId)
      .toList();

  if (others.isEmpty) {
    showAppSnackBar(context, 'No other categories available');
    return;
  }

  String? selectedId;
  Category? selectedCategory;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Move "${product.name}" to…',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: others.length,
                itemBuilder: (ctx, i) {
                  final cat = others[i];
                  final sel = selectedId == cat.id;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        cat.imageUri,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Theme.of(ctx)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.category_outlined),
                        ),
                      ),
                    ),
                    title: Text(cat.name),
                    selected: sel,
                    selectedTileColor: Theme.of(ctx)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.35),
                    trailing: sel
                        ? Icon(Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () => setModalState(() {
                      selectedId = cat.id;
                      selectedCategory = cat;
                    }),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedId == null
                          ? null
                          : () => Navigator.pop(ctx, true),
                      child: const Text('Move'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed != true ||
      selectedId == null ||
      selectedCategory == null) return;
  if (!context.mounted) return;

  try {
    await AdminService()
        .updateProduct(product.id, {'categoryId': _parseCatId(selectedId)});
    if (!context.mounted) return;
    // Optimistic animated removal before refresh
    onMoved();
    showAppSnackBar(
        context, '"${product.name}" moved to ${selectedCategory!.name}');
    ref.read(adminProductsProvider.notifier).refresh();
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Failed to move: ${e.toString()}');
    }
  }
}

// ─── Add-products bottom sheet ────────────────────────────────────────────────

Future<void> _showAddProductsSheet(
    BuildContext context, WidgetRef ref, String currentCategoryId) async {
  // Ensure products are loaded
  final ps = ref.read(adminProductsProvider);
  if (ps.products.isEmpty && !ps.isLoading) {
    await ref.read(adminProductsProvider.notifier).refresh();
  }
  if (!context.mounted) return;

  final catMap = {
    for (final c in ref.read(adminCategoriesProvider).categories)
      c.id: c.name
  };

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AddProductsSheet(
      currentCategoryId: currentCategoryId,
      categoriesMap: catMap,
    ),
  );
}

// ── Add-products sheet widget ─────────────────────────────────────────────────

enum _PStatus { inThis, inOther, unassigned }

class _AddProductsSheet extends ConsumerStatefulWidget {
  final String currentCategoryId;
  final Map<String, String> categoriesMap;

  const _AddProductsSheet({
    required this.currentCategoryId,
    required this.categoriesMap,
  });

  @override
  ConsumerState<_AddProductsSheet> createState() => _AddProductsSheetState();
}

class _AddProductsSheetState extends ConsumerState<_AddProductsSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _pending = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _PStatus _statusOf(Product p) {
    if (p.categoryId == widget.currentCategoryId) return _PStatus.inThis;
    if (_isUnassigned(p)) return _PStatus.unassigned;
    return _PStatus.inOther;
  }

  Future<void> _handleTap(Product p) async {
    if (_pending.contains(p.id)) return;
    setState(() => _pending.add(p.id));

    final status = _statusOf(p);
    final dynamic newCatId = status == _PStatus.inThis
        ? null // remove from category
        : _parseCatId(widget.currentCategoryId); // assign to this category
    final msg = status == _PStatus.inThis
        ? '"${p.name}" removed from this category'
        : '"${p.name}" added to this category';

    try {
      await AdminService()
          .updateProduct(p.id, {'categoryId': newCatId});
      if (!mounted) return;
      await ref.read(adminProductsProvider.notifier).refresh();
      if (mounted) {
        showAppSnackBar(context, msg);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _pending.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allProducts =
        ref.watch(adminProductsProvider.select((s) => s.products));
    final isLoading =
        ref.watch(adminProductsProvider.select((s) => s.isLoading));

    final filtered = _query.isEmpty
        ? allProducts
        : allProducts
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final inThis =
        filtered.where((p) => _statusOf(p) == _PStatus.inThis).toList();
    final inOther =
        filtered.where((p) => _statusOf(p) == _PStatus.inOther).toList();
    final unassigned =
        filtered.where((p) => _statusOf(p) == _PStatus.unassigned).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Add product to this category',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),
          if (isLoading && allProducts.isEmpty)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                controller: scroll,
                children: [
                  if (inThis.isNotEmpty) ...[
                    _SheetSectionHeader(
                        icon: Icons.check_circle_outline,
                        label: 'Already in this category',
                        color: Colors.green.shade600),
                    ...inThis.map((p) => _AddProductTile(
                          product: p,
                          subtitle: null,
                          trailing: const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          isPending: _pending.contains(p.id),
                          onTap: () => _handleTap(p),
                        )),
                  ],
                  if (inOther.isNotEmpty) ...[
                    _SheetSectionHeader(
                        icon: Icons.swap_horiz,
                        label: 'In another category',
                        color: Colors.orange.shade700),
                    ...inOther.map((p) => _AddProductTile(
                          product: p,
                          subtitle:
                              'Currently in: ${widget.categoriesMap[p.categoryId] ?? p.categoryId}',
                          trailing: const Icon(Icons.add_circle_outline,
                              size: 20),
                          isPending: _pending.contains(p.id),
                          onTap: () => _handleTap(p),
                        )),
                  ],
                  if (unassigned.isNotEmpty) ...[
                    _SheetSectionHeader(
                        icon: Icons.add_circle_outline,
                        label: 'Unassigned',
                        color: Colors.grey.shade600),
                    ...unassigned.map((p) => _AddProductTile(
                          product: p,
                          subtitle: null,
                          trailing: const Icon(Icons.add_circle_outline,
                              size: 20),
                          isPending: _pending.contains(p.id),
                          onTap: () => _handleTap(p),
                        )),
                  ],
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No products found',
                            style: theme.textTheme.bodyMedium),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section header chip ───────────────────────────────────────────────────────

class _SheetSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SheetSectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }
}

// ── Product tile inside add-sheet ─────────────────────────────────────────────

class _AddProductTile extends StatelessWidget {
  final Product product;
  final String? subtitle;
  final Widget trailing;
  final bool isPending;
  final VoidCallback onTap;

  const _AddProductTile({
    required this.product,
    required this.subtitle,
    required this.trailing,
    required this.isPending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          product.imageUri,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 44,
            height: 44,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported_outlined, size: 18),
          ),
        ),
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant))
          : Text('₹${product.price.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary)),
      trailing: isPending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : trailing,
      onTap: isPending ? null : onTap,
    );
  }
}
