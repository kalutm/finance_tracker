import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';

class CategoryPatch {
  final String? name;
  final CategoryType? type;
  final String? description;

  const CategoryPatch({this.name, this.type, this.description});

  bool get isEmpty =>
      name == null && type == null && description == null;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (type != null) 'type': type!.name,
      if (description != null) 'description': description,
    };
  }
}
