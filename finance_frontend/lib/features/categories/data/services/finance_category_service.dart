import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_patch.dart';
import 'package:finance_frontend/features/categories/domain/exceptions/category_exceptions.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FinanceCategoryService implements CategoryService {
  final SecureStorageService secureStorageService;

  FinanceCategoryService._internal(this.secureStorageService);
  static final FinanceCategoryService _instance =
      FinanceCategoryService._internal(FinanceSecureStorageService());
  factory FinanceCategoryService() => _instance;

  final String baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/categories";

  final List<FinanceCategory> _cache = [];
  final StreamController<List<FinanceCategory>> _controller =
      StreamController<List<FinanceCategory>>.broadcast();

  @override
  Stream<List<FinanceCategory>> get categoriesStream => _controller.stream;

  void _emitCache() {
    try {
      _controller.add(List.unmodifiable(_cache));
    } catch (_) {}
  }

  Future<String?> _readToken() =>
      secureStorageService.readString(key: "access_token");

  @override
  Future<List<FinanceCategory>> getUserCategories() async {
    try {
      final token = await _readToken();
      final resp = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      final resBody = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        dev.log("Failed fetching categories: ${resBody["detail"]}");
        throw CouldnotFetchCategories();
      }

      final categoriesMap = (resBody["categories"] ?? []) as List<dynamic>;
      final categories =
          categoriesMap
              .map(
                (c) => FinanceCategory.fromFinance(c as Map<String, dynamic>),
              )
              .toList();

      _cache
        ..clear()
        ..addAll(categories);

      _emitCache();
      return List.unmodifiable(_cache);
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> createCategory(CategoryCreate create) async {
    try {
      final token = await _readToken();
      final res = await http.post(
        Uri.parse("$baseUrl/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(create.toJson()),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 201) {
        dev.log("Create category failed: ${json["detail"]}");
        throw CouldnotCreateCategory();
      }

      final created = FinanceCategory.fromFinance(json);
      _cache.insert(0, created);
      _emitCache();
      return created;
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final token = await _readToken();
      final res = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.body.isNotEmpty) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 204) {
          dev.log("Delete category failed: ${json["detail"]}");
          if (res.statusCode == 400) {
            throw CannotDeleteCategoryWithTransactions();
          }
          throw CouldnotDeleteCategory();
        }
      } else {
        if (res.statusCode != 204) {
          if (res.statusCode == 400) {
            throw CannotDeleteCategoryWithTransactions();
          }
          throw CouldnotDeleteCategory();
        }
      }

      _cache.removeWhere((c) => c.id == id);
      _emitCache();
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> getCategory(String id) async {
    try {
      // Try cache first
      final cached = _cache.firstWhere(
        (c) => c.id == id,
        orElse:
            () => FinanceCategory(
              id: "",
              name: '',
              type: CategoryType.values.first,
              active: false,
              createdAt: DateTime.now(),
            ),
      );

      if (cached.id.isNotEmpty) return cached;

      final token = await _readToken();
      final resp = await http.get(
        Uri.parse("$baseUrl/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      final resBody = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        dev.log("Get category failed: ${resBody["detail"]}");
        throw CouldnotGetCategory();
      }

      final fetched = FinanceCategory.fromFinance(resBody);
      final idx = _cache.indexWhere((c) => c.id == fetched.id);
      if (idx != -1) {
        _cache[idx] = fetched;
      } else {
        _cache.insert(0, fetched);
      }
      _emitCache();
      return fetched;
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> restoreCategory(String id) async {
    try {
      final token = await _readToken();
      final res = await http.patch(
        Uri.parse("$baseUrl/$id/restore"),
        headers: {"Authorization": "Bearer $token"},
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        dev.log("Restore category failed: ${json["detail"]}");
        throw CouldnotRestoreCategory();
      }

      final restored = FinanceCategory.fromFinance(json);
      final idx = _cache.indexWhere((c) => c.id == restored.id);
      if (idx != -1) {
        _cache[idx] = restored;
      } else {
        _cache.insert(0, restored);
      }
      _emitCache();
      return restored;
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> updateCategory(String id, CategoryPatch patch) async {
    try {
      final token = await _readToken();
      final res = await http.patch(
        Uri.parse("$baseUrl/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(patch.toJson()),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        dev.log("Update category failed: ${json["detail"]}");
        throw CouldnotUpdateCategory();
      }

      final updated = FinanceCategory.fromFinance(json);
      final idx = _cache.indexWhere((c) => c.id == updated.id);
      if (idx != -1) {
        _cache[idx] = updated;
      } else {
        _cache.insert(0, updated);
      }
      _emitCache();
      return updated;
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> deactivateCategory(String id) async {
    try {
      final token = await _readToken();
      final res = await http.patch(
        Uri.parse("$baseUrl/$id/deactivate"),
        headers: {"Authorization": "Bearer $token"},
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        dev.log("Deactivate category failed: ${json["detail"]}");
        throw CouldnotDeactivateCategory();
      }

      final deactivated = FinanceCategory.fromFinance(json);
      final idx = _cache.indexWhere((c) => c.id == deactivated.id);
      if (idx != -1) {
        _cache[idx] = deactivated;
      } else {
        _cache.insert(0, deactivated);
      }
      _emitCache();
      return deactivated;
    } on CategoryException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // If you want to dispose the controller at app shutdown
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
