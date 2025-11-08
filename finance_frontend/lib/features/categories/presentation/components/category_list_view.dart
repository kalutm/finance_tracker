import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/presentation/components/category_item.dart';
import 'package:flutter/material.dart';

typedef CategoryFormCallback = void Function(BuildContext context, FinanceCategory cat);
typedef DeleteFormCallback = void Function(BuildContext connect, String id);

class CategoryListView extends StatelessWidget {
  final CategoryFormCallback onEdit;
  final CategoryFormCallback onDeactivate;
  final CategoryFormCallback onRestore;
  final DeleteFormCallback onDelete;
  final List<FinanceCategory> filtered;
  const CategoryListView({
    super.key,
    required this.filtered,
    required this.onEdit,
    required this.onDeactivate,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, idx) {
        final cat = filtered[idx];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: CategoryItem(
            category: cat,
            onEdit: () => onEdit(context, cat),
            onDeactivate: () => onDeactivate(context, cat),
            onRestore: () => onRestore(context, cat),
            onDelete: () => onDelete(context, cat.id),
          ),
        );
      }, childCount: filtered.length),
    );
  }
}
