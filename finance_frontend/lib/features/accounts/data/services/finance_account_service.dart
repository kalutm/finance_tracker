import 'dart:async';
import 'dart:convert';

import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
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
  static final FinanceAccountService _instance =
      FinanceAccountService._internal(FinanceSecureStorageService());
  factory FinanceAccountService() => _instance;

  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/accounts";


  final List<Account> _cachedAccounts = [];
  final StreamController<List<Account>> _controller =
      StreamController<List<Account>>.broadcast();

  @override
  Stream<List<Account>> get accountsStream => _controller.stream;

  void _emitCache() {
    try {
      _controller.add(List.unmodifiable(_cachedAccounts));
    } catch (_) {
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

      final accountsMap = (resBody["accounts"] ?? []) as List<dynamic>;
      final List<Account> accounts = [];
      for (final account in accountsMap) {
        accounts.add(Account.fromFinance(account as Map<String, dynamic>));
      }

      // update cache + emit
      _cachedAccounts
        ..clear()
        ..addAll(accounts);
      _emitCache();

      return List.unmodifiable(_cachedAccounts);
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

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

      final created = Account.fromFinance(json);

      // update cache + emit
      _cachedAccounts.insert(0, created);
      _emitCache();

      return created;
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
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

      final deactivated = Account.fromFinance(json);

      // update cache + emit
      final idx = _cachedAccounts.indexWhere((a) => a.id == deactivated.id);
      if (idx != -1) {
        _cachedAccounts[idx] = deactivated;
        _emitCache();
      }

      return deactivated;
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
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

      if (res.body.isNotEmpty) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 204) {
          dev_tool.log("EERROORR: ${json["detail"]}");
          if (res.statusCode == 400) {
            throw CannotDeleteAccountWithTransactions();
          }
          throw CouldnotDeleteAccount();
        }
      } else {
        if (res.statusCode != 204) {
          if (res.statusCode == 400) {
            throw CannotDeleteAccountWithTransactions();
          }
          throw CouldnotDeleteAccount();
        }
      }

      // update cache + emit
      _cachedAccounts.removeWhere((a) => a.id == id);
      _emitCache();
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Account> getAccount(String id) async {
    try {
      // Try find in cache first
      final cached = _cachedAccounts.firstWhere(
        (a) => a.id == id,
        orElse: () => Account(
          id: '',
          balance: '0',
          name: '',
          type: AccountType.values.first,
          currency: '',
          active: false,
          createdAt: DateTime.now(),
        ),
      );

      // If found in cache and has valid id, return it
      if (cached.id.isNotEmpty) return cached;

      // else fetch from server
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

      final fetched = Account.fromFinance(resBody);

      // update cache and emit (upsert)
      final idx = _cachedAccounts.indexWhere((a) => a.id == fetched.id);
      if (idx != -1) {
        _cachedAccounts[idx] = fetched;
      } else {
        _cachedAccounts.insert(0, fetched);
      }
      _emitCache();

      return fetched;
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
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

      final restored = Account.fromFinance(json);

      // update cache + emit
      final idx = _cachedAccounts.indexWhere((a) => a.id == restored.id);
      if (idx != -1) {
        _cachedAccounts[idx] = restored;
      } else {
        _cachedAccounts.insert(0, restored);
      }
      _emitCache();

      return restored;
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
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

      final updated = Account.fromFinance(json);

      // update cache + emit
      final idx = _cachedAccounts.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        _cachedAccounts[idx] = updated;
      } else {
        _cachedAccounts.insert(0, updated);
      }
      _emitCache();

      return updated;
    } on AccountException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // close stream when app disposes 
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
