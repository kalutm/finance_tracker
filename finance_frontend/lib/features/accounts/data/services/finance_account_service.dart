import 'dart:convert';

import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';
import 'package:finance_frontend/features/accounts/domain/exceptions/account_exceptions.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev_tool show log;

class FinanceAccountService implements AccountService {
  final SecureStorageService secureStorageService;

  FinanceAccountService._internal(this.secureStorageService);
  static final FinanceAccountService _instance = FinanceAccountService._internal(FinanceSecureStorageService());
  factory FinanceAccountService() => _instance;


  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/accounts";

  @override
  Future<Account> createAccount(AccountCreate create) async {
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
        throw CouldnotCreateAccount();
      }
      // request was successful -> return the created account
      return Account.fromFinance(json);
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Account Creation Failed: $e");
    }
  }

  @override
  Future<Account> deactivateAccount(String id) async {
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
        throw CouldnotDeactivateAccount();
      }
      // request was successful -> return the deactivated account
      return Account.fromFinance(json);
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Account deactivation Failed: $e");
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.delete(
        headers: {"Authorization": "Bearer $accessToken"},
        Uri.parse("$baseUrl/$id"),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 204) {
        dev_tool.log("EERROORR, EERROORR: ${json["detail"]}");
        throw CouldnotDeleteAccount();
      }
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Account deletion Failed: $e");
    }
  }

  @override
  Future<Account> getAccount(String id) async {
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
        throw CouldnotGetAccont();
      }
      // request successful -> return the fetched account
      return Account.fromFinance(resBody);
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Couldnot Get account: $e");
    }
  }

  @override
  Future<List<Account>> getUserAccounts() async {
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
        throw CouldnotFetchAccounts();
      }
      // request successful -> return the fetched convert to and return the fetched data as List<Account>

      final accountsMap = resBody["accounts"] as List<dynamic>;
      final List<Account> accounts = [];
      for (final account in accountsMap) {
        accounts.add(Account.fromFinance(account as Map<String, dynamic>));
      }

      return accounts;
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Couldnot fetch accounts: $e");
    }
  }

  @override
  Future<Account> restoreAccount(String id) async {
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
        throw CouldnotRestoreAccount();
      }
      // request was successful -> return the restored account
      return Account.fromFinance(json);
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Account Restoration Failed: $e");
    }
  }

  @override
  Future<Account> updateAccount(String id, AccountPatch patch) async {
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
        throw CouldnotUpdateAccount();
      }
      // request was successful -> return the updated account
      return Account.fromFinance(json);
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception("Updating account Failed: $e");
    }
  }
}
