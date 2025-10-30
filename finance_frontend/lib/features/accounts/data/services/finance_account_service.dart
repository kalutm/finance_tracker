import 'dart:convert';

import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';
import 'package:finance_frontend/features/accounts/domain/exceptions/account_exceptions.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev_tool show log;

class FinanceAccountService implements AccountService{
  final FinanceSecureStorageService financeSecureStorageService;

  FinanceAccountService(this.financeSecureStorageService);

  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/accounts";


  @override
  Future<Account> createAccount(AccountCreate create) async {
    try {
      final accessToken = await financeSecureStorageService.readString(key: "access_token");
      final res = await http.post(
        headers: {
            "Authorization": "Bearer $accessToken",
          },
        Uri.parse(baseUrl),
        body: jsonEncode({"name": create.name, "type": create.type.name, "currency": create.currency}),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotCreateAccount();
      }
      // request was successful -> return the created account
      return Account.fromFinance(json);

    } on AccountException catch (_) {
      rethrow;
    } catch(e){
      throw Exception("Creating account Failed: $e");
    }
  }

  @override
  Future<Account> deactivateAccount(String id) {
    // TODO: implement deactivateAccount
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(String id) {
    // TODO: implement deleteAccount
    throw UnimplementedError();
  }

  @override
  Future<Account> getAccount(String id) {
    // TODO: implement getAccount
    throw UnimplementedError();
  }

  @override
  Future<List<Account>> getUserAccounts() async {
    try {
        final accessToken = await financeSecureStorageService.readString(key: "access_token");
        final resp = await http.get(
          Uri.parse(baseUrl),
          headers: {
            "Authorization": "Bearer $accessToken",
          },
        );

        final resBody = jsonDecode(resp.body) as Map<String, dynamic>;
        if (resp.statusCode != 200) {
          dev_tool.log(
            "EERROORR, EERROORR: ${resBody["detail"]}",
          );
          throw CouldnotFetchAccounts();
        }
        // request successful -> return the fetched convert to and return the fetched data as List<Account>

        final accountsMap = resBody["accounts"] as List<dynamic>;
        final List<Account> accounts = [];
        for (final account in accountsMap){
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
  Future<Account> restoreAccount(String id) {
    // TODO: implement restoreAccount
    throw UnimplementedError();
  }

  @override
  Future<Account> updateAccount(String id, AccountPatch patch) {
    // TODO: implement updateAccount
    throw UnimplementedError();
  }

}