import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/providers/product_providers.dart';
import 'providers/search_providers.dart';

class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final previewCount = ref.watch(filteredProductCountProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters',
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(filterProvider.notifier).reset();
                      },
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ─── Category (from API) ───
                    const _SectionTitle(title: 'Category'),
                    categoriesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                      ),
                      error: (_, __) =>
                          const Text('Failed to load categories'),
                      data: (categories) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final selected = filter.selectedCategories
                              .contains(cat.name);
                          return FilterChip(
                            label: Text(cat.name),
                            selected: selected,
                            onSelected: (_) => ref
                                .read(filterProvider.notifier)
                                .toggleCategory(cat.name),
                            selectedColor: colorScheme.primary
                                .withValues(alpha: 0.15),
                            checkmarkColor: colorScheme.primary,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Price Range ───
                    const _SectionTitle(title: 'Price Range'),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${filter.minPrice.toInt()}'),
                        Text('${filter.maxPrice.toInt()}'),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(
                          filter.minPrice, filter.maxPrice),
                      min: 0,
                      max: 50000,
                      divisions: 100,
                      labels: RangeLabels(
                        '${filter.minPrice.toInt()}',
                        '${filter.maxPrice.toInt()}',
                      ),
                      onChanged: (values) {
                        ref
                            .read(filterProvider.notifier)
                            .setPriceRange(values.start, values.end);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ─── Rating ───
                    const _SectionTitle(title: 'Minimum Rating'),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final starValue = index + 1;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(filterProvider.notifier)
                                  .setMinRating(
                                    filter.minRating ==
                                            starValue.toDouble()
                                        ? 0
                                        : starValue.toDouble(),
                                  );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 4),
                              child: Icon(
                                starValue <= filter.minRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                                semanticLabel: '$starValue star',
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        if (filter.minRating > 0)
                          Text(
                              '${filter.minRating.toInt()}+ stars',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ─── In Stock ───
                    SwitchListTile(
                      value: filter.inStockOnly,
                      onChanged: (_) => ref
                          .read(filterProvider.notifier)
                          .toggleInStockOnly(),
                      title: const Text('In Stock Only'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        previewCount == 0
                            ? 'No Results — Apply Anyway'
                            : 'Show $previewCount Results',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
