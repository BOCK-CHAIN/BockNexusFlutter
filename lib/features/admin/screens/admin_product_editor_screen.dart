import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/admin_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/category_model.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/admin_product_providers.dart';

class AdminProductEditorScreen extends ConsumerStatefulWidget {
  final String? productId;
  final String? initialCategoryId;

  const AdminProductEditorScreen({
    super.key,
    this.productId,
    this.initialCategoryId,
  });

  bool get isEditMode => productId != null;

  @override
  ConsumerState<AdminProductEditorScreen> createState() =>
      _AdminProductEditorScreenState();
}

class _AdminProductEditorScreenState
    extends ConsumerState<AdminProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _imageUriCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _brandCtrl;

  String? _selectedCategoryId;
  String _sizeType = 'NONE';
  List<_EditableStockRow> _stockRows = [];

  List<Category> _categories = [];
  bool _categoriesLoading = true;
  bool _prefilled = false;

  /// Matches Prisma `SizeType` enum in `schema.prisma`.
  static const _sizeTypes = [
    'NONE',
    'GENERIC',
    'SHOES_UK_MEN',
    'SHOES_UK_WOMEN',
    'NUMERIC',
    'VOLUME_ML',
    'WEIGHT_G',
    'ONE_SIZE',
    'WAIST_INCH',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _imageUriCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _colorCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _selectedCategoryId = widget.initialCategoryId;
    _loadCategories();

    // Reset editor state and load product if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(adminProductEditorProvider.notifier);
      notifier.reset();
      if (widget.productId != null) {
        notifier.loadProduct(widget.productId!);
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AdminService().getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageUriCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _colorCtrl.dispose();
    _brandCtrl.dispose();
    for (final row in _stockRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _prefillFromState(AdminProductEditorState editorState) {
    if (_prefilled || editorState.product == null) return;
    _prefilled = true;
    final p = editorState.product!;
    _nameCtrl.text = p.name;
    _imageUriCtrl.text = p.imageUri;
    _priceCtrl.text = p.price.toString();
    _descCtrl.text = p.description ?? '';
    _colorCtrl.text = p.color ?? '';
    _brandCtrl.text = p.brand ?? '';
    _selectedCategoryId = p.categoryId;
    _sizeType =
        _sizeTypes.contains(p.sizeType) ? p.sizeType : _sizeTypes.first;
    _stockRows = editorState.stockRows
        .map((r) => _EditableStockRow(
              id: r.id,
              sizeCtrl: TextEditingController(text: r.size),
              stockCtrl: TextEditingController(text: r.stock.toString()),
              sortOrder: r.sortOrder,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(adminProductEditorProvider);

    // Prefill once after data arrives
    if (widget.isEditMode && !_prefilled) {
      _prefillFromState(editorState);
    }

    final isLoading = editorState.isLoading;
    final isSaving = editorState.isSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Product' : 'New Product'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Product fields ───
                    AppTextField(
                      labelText: 'Name',
                      hintText: 'Product name',
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
                    AppTextField(
                      labelText: 'Price',
                      hintText: '99.99',
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      labelText: 'Description',
                      hintText: 'Product description',
                      controller: _descCtrl,
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    _categoriesLoading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                                labelText: 'Category'),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                    value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategoryId = v),
                            validator: (v) =>
                                v == null ? 'Select a category' : null,
                          ),
                    const SizedBox(height: 16),

                    // Size type dropdown
                    DropdownButtonFormField<String>(
                      value: _sizeType,
                      decoration:
                          const InputDecoration(labelText: 'Size Type'),
                      items: _sizeTypes
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _sizeType = v ?? 'NONE'),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      labelText: 'Color',
                      hintText: 'e.g. Red',
                      controller: _colorCtrl,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      labelText: 'Brand',
                      hintText: 'e.g. Nike',
                      controller: _brandCtrl,
                    ),
                    const SizedBox(height: 24),

                    // ─── Stock section ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Stock / Sizes',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addStockRow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._stockRows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: row.sizeCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Size', isDense: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: row.stockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Stock', isDense: true),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Theme.of(context).colorScheme.error),
                              onPressed: () => _removeStockRow(i),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    if (editorState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          editorState.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),

                    AppButton(
                      text: widget.isEditMode
                          ? 'Update Product'
                          : 'Create Product',
                      isLoading: isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _addStockRow() {
    setState(() {
      _stockRows.add(_EditableStockRow(
        sizeCtrl: TextEditingController(),
        stockCtrl: TextEditingController(text: '0'),
        sortOrder: _stockRows.length,
      ));
    });
  }

  void _removeStockRow(int index) {
    setState(() {
      _stockRows[index].dispose();
      _stockRows.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'image_uri': _imageUriCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'description': _descCtrl.text.trim(),
      'categoryId': int.tryParse(_selectedCategoryId ?? '') ??
          _selectedCategoryId,
      'sizeType': _sizeType,
      'color': _colorCtrl.text.trim(),
      'brand': _brandCtrl.text.trim(),
    };

    final stockRows = _stockRows
        .map((r) => StockRow(
              id: r.id,
              size: r.sizeCtrl.text.trim(),
              stock: int.tryParse(r.stockCtrl.text.trim()) ?? 0,
              sortOrder: r.sortOrder,
            ))
        .toList();

    final notifier = ref.read(adminProductEditorProvider.notifier);

    if (widget.isEditMode) {
      final ok =
          await notifier.updateProduct(widget.productId!, body, stockRows);
      if (mounted) {
        showAppSnackBar(context,
            ok ? 'Product updated successfully' : 'Failed to update product');
        if (ok) Navigator.pop(context);
      }
    } else {
      final createdId = await notifier.createProduct(body, stockRows);
      if (mounted) {
        showAppSnackBar(context,
            createdId != null
                ? 'Product added successfully'
                : 'Failed to create product');
        if (createdId != null) Navigator.pop(context);
      }
    }
  }
}

/// Internal helper for editable stock rows with controllers.
class _EditableStockRow {
  final String? id;
  final TextEditingController sizeCtrl;
  final TextEditingController stockCtrl;
  final int sortOrder;

  _EditableStockRow({
    this.id,
    required this.sizeCtrl,
    required this.stockCtrl,
    required this.sortOrder,
  });

  void dispose() {
    sizeCtrl.dispose();
    stockCtrl.dispose();
  }
}
