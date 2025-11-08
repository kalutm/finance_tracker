import 'dart:convert';
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_patch.dart';
import 'package:finance_frontend/features/categories/domain/exceptions/category_exceptions.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev_tool show log;

class FinanceCategoryService implements CategoryService{
  final SecureStorageService secureStorageService;

  FinanceCategoryService._internal(this.secureStorageService);
  static final FinanceCategoryService _instance =
      FinanceCategoryService._internal(FinanceSecureStorageService());
  factory FinanceCategoryService() => _instance;

  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/categories";

  @override
  Future<FinanceCategory> createCategory(CategoryCreate create) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.post(
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        Uri.parse("$baseUrl/"),
        body: jsonEncode(create.toJson()),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 201) {
        dev_tool.log("EERROORR, EERROORR: ${json["detail"]}");
        throw CouldnotCreateCategory();
      }
      // request was successful -> return the created category
      return FinanceCategory.fromFinance(json);
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> deactivateCategory(String id) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.patch(
        headers: {"Authorization": "Bearer $accessToken"},
        Uri.parse("$baseUrl/$id/deactivate"),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        dev_tool.log("EERROORR, EERROORR: ${json["detail"]}");
        throw CouldnotDeactivateCategory();
      }
      // request was successful -> return the deactivated category
      return FinanceCategory.fromFinance(json);
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.delete(
        headers: {"Authorization": "Bearer $accessToken"},
        Uri.parse("$baseUrl/$id"),
      );

      if (res.body.isNotEmpty) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 204) {
          dev_tool.log("EERROORR: ${json["detail"]}");
          throw CouldnotDeleteCategory();
        }
      } else {
        if (res.statusCode != 204) {
          throw CouldnotDeleteCategory();
        }
      }
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> getCategory(String id) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final resp = await http.get(
        Uri.parse("$baseUrl/$id"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      final resBody = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        dev_tool.log("EERROORR, EERROORR: ${resBody["detail"]}");
        throw CouldnotGetCategory();
      }
      // request successful -> return the fetched category
      return FinanceCategory.fromFinance(resBody);
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<FinanceCategory>> getUserCategories() async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final resp = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      final resBody = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        dev_tool.log("EERROORR, EERROORR: ${resBody["detail"]}");
        throw CouldnotFetchCategories();
      }
      // request successful -> return the fetched convert to and return the fetched data as List<FinanceCategory>

      final accountsMap = (resBody["categories"] ?? []) as List<dynamic>;
      final List<FinanceCategory> accounts = [];
      for (final account in accountsMap) {
        accounts.add(FinanceCategory.fromFinance(account as Map<String, dynamic>));
      }

      return accounts;
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> restoreCategory(String id) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.patch(
        headers: {"Authorization": "Bearer $accessToken"},
        Uri.parse("$baseUrl/$id/restore"),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotRestoreCategory();
      }
      // request was successful -> return the restored category
      return FinanceCategory.fromFinance(json);
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FinanceCategory> updateCategory(String id, CategoryPatch patch) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.patch(
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        Uri.parse("$baseUrl/$id"),
        body: jsonEncode(patch.toJson()),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotUpdateCategory();
      }
      // request was successful -> return the updated category
      return FinanceCategory.fromFinance(json);
    } on CategoryException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
