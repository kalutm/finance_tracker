import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';

class FinanceCategory {
  final String id;
  final String name;
  final CategoryType type;
  final bool active;
  final DateTime createdAt;

  FinanceCategory({required this.id, required this.name, required this.type, required this.active, required this.createdAt});
  

  factory FinanceCategory.fromFinance(Map<String, dynamic> json) {
    return FinanceCategory(
      id: (json['id'] as int).toString(),
      name: json['name'] as String,
      type: CategoryType.values.byName(json['type'] as String),
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toFinance() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
