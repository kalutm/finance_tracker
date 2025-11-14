
import 'package:finance_frontend/features/categories/domain/entities/category.dart'; // Assume Category entity exists
import 'package:finance_frontend/features/categories/domain/utils/category_icon_mapper.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart'; // Assume Bloc
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_state.dart'; // Assume State
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

  // Function to show the selection bottom sheet
  void _showCategorySelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<CategoriesBloc>(), // Pass existing bloc
          child: _CategorySelectionSheet(onCategorySelected: onCategorySelected),
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
          prefixIcon: Icon(selectedCategory?.displayIcon ?? Icons.category_rounded),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          selectedCategory?.name ?? 'Tap to Select',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: selectedCategory == null 
              ? theme.colorScheme.onSurface.withOpacity(0.6) 
              : theme.colorScheme.onSurface,
            fontWeight: selectedCategory != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// --- Internal Widget for the Modal Bottom Sheet ---
class _CategorySelectionSheet extends StatelessWidget {
  final ValueChanged<FinanceCategory> onCategorySelected;

  const _CategorySelectionSheet({required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic height based on screen size (e.g., 80% of screen height)
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select a Category',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          // Search Bar (Essential for long lists, using a placeholder)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Category List
          Expanded(
            child: BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) {
                // Assuming state is CategoriesLoaded
                if (state is CategoriesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is! CategoriesLoaded || state.categories.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories found.', 
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)
                    )
                  );
                }

                return ListView.builder(
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return ListTile(
                      leading: Icon(
                        category.displayIcon, // Assuming Category has an icon property
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(category.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        onCategorySelected(category);
                        Navigator.pop(context); // Close the sheet after selection
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