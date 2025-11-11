import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';

class CategoryCreate {
  final String name;
  final CategoryType type;
  final String? description;

  const CategoryCreate({
    required this.name,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'description': description,
    };
  }
}
