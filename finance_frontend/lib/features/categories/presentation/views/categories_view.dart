import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_event.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/categories/categories_state.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_bloc.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_event.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/category_form/category_form_state.dart';
import 'package:finance_frontend/features/categories/presentation/blocs/entities/operation_type_enum.dart';
import 'package:finance_frontend/features/categories/presentation/components/category_form_sheet.dart';
import 'package:finance_frontend/features/categories/presentation/components/category_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesView> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Global listener: show errors from CategoriesBloc
        BlocListener<CategoriesBloc, CategoriesState>(
          listener: (context, state) {
            if (state is CategoriesOperationFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
        // Global listener: transform CategoryFormBloc successes into CategoriesBloc updates
        BlocListener<CategoryFormBloc, CategoryFormState>(
          listener: (context, state) {
            if (state is CategoryOperationSuccess) {
              final cat = state.category;
              final op = state.operationType;
              final opName = op.toString().split('.').last;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Category ${opName}d successful')),
              );
              // Notify CategoriesBloc to update cached list in-place:
              switch (op) {
                case CategoryOperationType.create:
                  context.read<CategoriesBloc>().add(
                    CategoryCreatedInForm(cat),
                  );
                  break;
                case CategoryOperationType.update:
                  context.read<CategoriesBloc>().add(
                    CategoryUpdatedInForm(cat),
                  );
                  break;
                case CategoryOperationType.deactivate:
                  context.read<CategoriesBloc>().add(
                    CategoryDeactivatedInForm(cat),
                  );
                  break;
                case CategoryOperationType.restore:
                  context.read<CategoriesBloc>().add(
                    CategoryRestoredInForm(cat),
                  );
                  break;
                default:
                  break;
              }
            } else if (state is CategoryDeleteOperationSuccess) {
              final id = state.id;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Category deleted')));
              context.read<CategoriesBloc>().add(CategoryDeletedInForm(id));
            } else if (state is CategoryOperationFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  () => context.read<CategoriesBloc>().add(RefreshCategories()),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody(context)),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openCreateSheet(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoading || state is CategoriesInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CategoriesLoaded) {
          final List<FinanceCategory> all = state.categories;
          final filtered = _applyFilter(all, _filter);

          // create favorites/top grid (active categories)
          final activeTop = filtered.where((c) => c.active).take(6).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CategoriesBloc>().add(RefreshCategories());
              // Wait a small duration for UI to update; ideally, connect to events.
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBar()),
                if (activeTop.isNotEmpty)
                  SliverToBoxAdapter(child: _buildTopGrid(activeTop)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, idx) {
                      final cat = filtered[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: CategoryItem(
                          category: cat,
                          onEdit: () => _openEditSheet(context, cat),
                          onDeactivate: () => _confirmDeactivate(context, cat),
                          onRestore: () => _confirmRestore(context, cat),
                          onDelete: () => _confirmDelete(context, cat.id),
                        ),
                      );
                    }, childCount: filtered.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 80),
                ), // space for FAB
              ],
            ),
          );
        } else if (state is CategoriesOperationFailure) {
          return Center(child: Text(state.message));
        } else {
          return const Center(child: Text('No categories found'));
        }
      },
    );
  }

  List<FinanceCategory> _applyFilter(List<FinanceCategory> all, String filter) {
    if (filter.isEmpty) return all;
    final lower = filter.toLowerCase();
    return all.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          (c.description.toLowerCase().contains(lower));
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        key: const Key('categories_search'),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search categories',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
        ),
        onChanged: (v) => setState(() => _filter = v),
      ),
    );
  }

  Widget _buildTopGrid(List<FinanceCategory> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick access', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final cat = list[i];
                return _TopCategoryChip(
                  category: cat,
                  onTap: () => _openEditSheet(context, cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CategoryFormBloc>()),
          ],
          child: CategoryFormSheet(
            initialCategory: null,
          ),
        );
      },
    );
  }

  void _openEditSheet(BuildContext context, FinanceCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<CategoryFormBloc>(),
          child: CategoryFormSheet(initialCategory: category),
        );
      },
    );
  }

  void _confirmDeactivate(BuildContext context, FinanceCategory cat) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Deactivate category'),
          content: Text('Are you sure you want to deactivate "${cat.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<CategoryFormBloc>().add(
                  DeactivateCategory(cat.id),
                );
              },
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRestore(BuildContext context, FinanceCategory cat) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Restore category'),
          content: Text('Restore "${cat.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<CategoryFormBloc>().add(RestoreCategory(cat.id));
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: const Text(
            'This will permanently delete the category. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<CategoryFormBloc>().add(DeleteCategory(id));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _TopCategoryChip extends StatelessWidget {
  final FinanceCategory category;
  final VoidCallback onTap;
  const _TopCategoryChip({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              category.active ? color.withAlpha(31) : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(31)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Icon(Icons.category, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
