import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/utils/category_icon_mapper.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategorySelector extends StatelessWidget {
  final FinanceCategory? selectedCategory;
  final ValueChanged<FinanceCategory> onCategorySelected;
  final String label;

  const CategorySelector({
    required this.selectedCategory,
    required this.onCategorySelected,
    this.label = 'Category',
    super.key,
  });

  void _showCategorySelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<CategoriesBloc>(),
          child: _CategorySelectionSheet(
            onCategorySelected: onCategorySelected,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showCategorySelectionSheet(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            selectedCategory?.displayIcon ?? Icons.category_rounded,
          ),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          selectedCategory?.name ?? 'Tap to Select',
          style: theme.textTheme.bodyLarge?.copyWith(
            color:
                selectedCategory == null
                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                    : theme.colorScheme.onSurface,
            fontWeight:
                selectedCategory != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CategorySelectionSheet extends StatefulWidget {
  final ValueChanged<FinanceCategory> onCategorySelected;

  const _CategorySelectionSheet({required this.onCategorySelected});

  @override
  State<_CategorySelectionSheet> createState() =>
      _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<_CategorySelectionSheet> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  TextSpan _highlightOccurrences(
    String source,
    String query,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    if (query.isEmpty) {
      return TextSpan(text: source, style: normalStyle);
    }

    final lowerSource = source.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final List<TextSpan> spans = <TextSpan>[];
    int start = 0;
    int index;

    while (true) {
      index = lowerSource.indexOf(lowerQuery, start);
      if (index < 0) {
        // no more matches
        if (start < source.length) {
          spans.add(
            TextSpan(text: source.substring(start), style: normalStyle),
          );
        }
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: source.substring(start, index), style: normalStyle),
        );
      }
      spans.add(
        TextSpan(
          text: source.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );
      start = index + query.length;
    }

    return TextSpan(children: spans, style: normalStyle);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FinanceCategory> _filterCategories(
    List<FinanceCategory> input,
    String query,
  ) {
    if (query.isEmpty) return input;
    final q = query.toLowerCase();
    return input.where((c) {
      final name = c.name.toLowerCase();
      final desc = (c.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select a Category',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search categories by name or description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _query.isNotEmpty
                        ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is! CategoriesLoaded || state.categories.isEmpty) {
                  final message =
                      (state is CategoriesLoaded && state.categories.isEmpty)
                          ? 'No categories created yet.'
                          : 'No categories found.';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(178),
                        ),
                      ),
                    ),
                  );
                }

                final activeCategories = state.categories.where((cat) => cat.active).toList();

                final filtered = _filterCategories(activeCategories, _query);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'No categories match your search.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = filtered[index];

                    final nameNormal = theme.textTheme.titleMedium!;
                    final nameHighlight = nameNormal.copyWith(
                      backgroundColor: theme.colorScheme.primary.withAlpha(46),
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    );
                    final descNormal = theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(204),
                    );
                    final descHighlight = descNormal.copyWith(
                      backgroundColor: theme.colorScheme.primary.withAlpha(31),
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    );

                    final nameSpan = _highlightOccurrences(
                      category.name,
                      _query,
                      nameNormal,
                      nameHighlight,
                    );
                    final descText = (category.description ?? '').trim();
                    final descSpan = _highlightOccurrences(
                      descText,
                      _query,
                      descNormal,
                      descHighlight,
                    );

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withAlpha(
                          31,
                        ),
                        child: Icon(
                          category.displayIcon,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: RichText(
                        text: nameSpan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle:
                          descText.isNotEmpty
                              ? RichText(
                                text: descSpan,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                              : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        widget.onCategorySelected(category);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
