import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';

class CategoryPatch {
  final String? name;
  final CategoryType? type;

  const CategoryPatch({this.name, this.type});

  bool get isEmpty =>
      name == null && type == null;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (type != null) 'type': type!.name,
    };
  }
}
