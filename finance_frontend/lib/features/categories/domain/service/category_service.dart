import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_patch.dart';

abstract class CategoryService {
  Future<List<FinanceCategory>> getUserCategories();

  Future<FinanceCategory> createCategory(CategoryCreate create);

  Future<FinanceCategory> getCategory(String id);

  Future<FinanceCategory> updateCategory(String id, CategoryPatch patch);

  Future<FinanceCategory> deactivateCategory(String id);

  Future<void> deleteCategory(String id);

  Future<FinanceCategory> restoreCategory(String id);
}
