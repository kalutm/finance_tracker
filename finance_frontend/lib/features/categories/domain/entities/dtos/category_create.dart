import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';

class CategoryCreate {
  final String name;
  final CategoryType type;

  const CategoryCreate({
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
    };
  }
}
