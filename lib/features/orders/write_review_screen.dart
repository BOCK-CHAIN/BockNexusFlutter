import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/order_providers.dart';
import '../../core/utils/snackbar_utils.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;

  const WriteReviewScreen({super.key, required this.orderId, required this.productId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 0;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<int> _mockPhotos = []; // mock photo count
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = ref.watch(ordersProvider.notifier).getById(widget.orderId);
    final product = order?.items.where((i) => i.product.id == widget.productId).firstOrNull?.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Write Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product being reviewed
              if (product != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surface,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(product.imageUrl,
                            width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (c1, c2, c3) => Container(
                                width: 50, height: 50, color: Colors.grey.shade200,
                                child: const Icon(Icons.image))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ─── Star Rating ───
              Text('Overall Rating *',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedScale(
                          scale: _rating >= starIndex ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _rating >= starIndex ? Icons.star : Icons.star_border,
                            size: 40,
                            color: _rating >= starIndex ? Colors.amber : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_rating > 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _ratingLabel(_rating),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ─── Title ───
              Text('Review Title',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Summarize your review',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // ─── Review Body ───
              Text('Your Review *',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tell us about your experience (min 20 characters)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.length < 20) return 'Review must be at least 20 characters';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              // Live counter
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_bodyCtrl.text.length}/500',
                  style: TextStyle(
                    fontSize: 11,
                    color: _bodyCtrl.text.length < 20 ? Colors.red : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Photos ───
              Text('Add Photos',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...List.generate(_mockPhotos.length, (index) {
                    return Stack(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          ),
                          child: Icon(Icons.image, size: 28,
                              color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                        ),
                        Positioned(
                          top: -4, right: -4,
                          child: GestureDetector(
                            onTap: () => setState(() => _mockPhotos.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.red,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_mockPhotos.length < 5)
                    GestureDetector(
                      onTap: () {
                        setState(() => _mockPhotos.add(_mockPhotos.length));
                      },
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 22, color: Colors.grey.shade500),
                            const SizedBox(height: 2),
                            Text('${_mockPhotos.length}/5',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Submit ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Review'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_rating == 0) {
      showAppSnackBar(context, 'Please select a star rating');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppSnackBar(context, 'Review submitted! Thank you');
      context.pop();
    });
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}
