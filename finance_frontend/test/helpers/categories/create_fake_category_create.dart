import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';

CategoryCreate fakeCategoryCreate({String name = "Food"}) {
  return CategoryCreate(name: name, type: CategoryType.EXPENSE, description: "test category");
}
