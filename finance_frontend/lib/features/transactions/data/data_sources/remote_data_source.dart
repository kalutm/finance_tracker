import 'dart:convert';
import 'dart:developer' as dev_tool;

import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_model.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RemoteDataSource {
    final SecureStorageService secureStorageService;

  RemoteDataSource._internal(this.secureStorageService);
  static final RemoteDataSource _instance =
      RemoteDataSource._internal(FinanceSecureStorageService());
  factory RemoteDataSource() => _instance;

  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/transactions";

  Future<TransactionModel> createTransaction(TransactionCreate create) async {
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
        throw CouldnotCreateTransaction();
      }
      // request was successful -> return the created Transaction
      return TransactionModel.fromFinance(json);
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  Future<TransactionModel> createTransferTransaction(TransferTransactionCreate create) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.patch(
        headers: {"Authorization": "Bearer $accessToken"},
        Uri.parse("$baseUrl/transfer"),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 201) {
        dev_tool.log("EERROORR, EERROORR: ${json["detail"]}");
        throw CouldnotCreateTransferTransaction();
      }
      // request was successful -> return the created transfer transaction
      return TransactionModel.fromFinance(json);
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> deleteTransaction(String id) async {
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
          if(res.statusCode == 400){
            throw AccountBalanceTnsufficient();
          }
          throw CouldnotDeleteTransaction();
        }
      } else {
        if (res.statusCode != 204) {
          if(res.statusCode == 400){
            throw AccountBalanceTnsufficient();
          }
          throw CouldnotDeleteTransaction();
        }
      }
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> deleteTransferTransaction(String transferGroupId) async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      final res = await http.delete(
        headers: {"Authorization": "Bearer $accessToken"},
        Uri.parse("$baseUrl/transfer/$transferGroupId"),
      );

      if (res.body.isNotEmpty) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 204) {
          dev_tool.log("EERROORR: ${json["detail"]}");
          if(res.statusCode == 400){
            throw AccountBalanceTnsufficient();
          }
          throw CouldnotDeleteTransferTransaction();
        }
      } else {
        if (res.statusCode != 204) {
          if(res.statusCode == 400){
            throw AccountBalanceTnsufficient();
          }
          throw CouldnotDeleteTransferTransaction();
        }
      }
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<TransactionModel> getTransaction(String id) async {
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
        throw CouldnotGetTransaction();
      }
      // request successful -> return the fetched Transaction
      return TransactionModel.fromFinance(resBody);
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionModel>> getUserTransactions() async {
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
        throw CouldnotFetchTransactions();
      }
      // request successful -> convert to and return the fetched data as List<TransactionModel>

      final transactionsMap = (resBody["accounts"] ?? []) as List<dynamic>;
      final List<TransactionModel> transactions = [];
      for (final transaction in transactionsMap) {
        transactions.add(TransactionModel.fromFinance(transaction as Map<String, dynamic>));
      }

      return transactions;
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  Future<TransactionModel> updateTransaction(String id, TransactionPatch patch) async {
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
        throw CouldnotUpdateTransaction();
      }
      // request was successful -> return the updated Transaction
      return TransactionModel.fromFinance(json);
    } on TransactionException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}