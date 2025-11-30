import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';

Map<String, dynamic> fakeCategoryJson({required int id, String? name, CategoryType? type, bool active = true}) {
    return {
      'id': id,
      'name': name ?? 'Category$id',
      'type': (type ?? CategoryType.INCOME).name,
      'active': active,
      'created_at': DateTime.now().toIso8601String(),
      'description': "test category"
    };
  }