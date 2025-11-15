import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final FinanceCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const CategoryItem({
    required this.category,
    required this.onEdit,
    required this.onDeactivate,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: category.active ? 1.0 : 0.6,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(Icons.category, color: Colors.white),
          ),
          title: Text(category.name, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(category.description??''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusChip(context, category.active),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'deactivate':
                      onDeactivate();
                      break;
                    case 'restore':
                      onRestore();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (ctx) {
                  return [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (category.active)
                      const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                    if (!category.active)
                      const PopupMenuItem(value: 'restore', child: Text('Restore')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool active) {
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      avatar: Icon(active ? Icons.check_circle : Icons.pause_circle, size: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}
