import 'dart:convert';
import 'dart:developer' as dev_tool;
import 'package:finance_frontend/core/network/network_client.dart';
import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_model.dart';
import 'package:finance_frontend/features/transactions/domain/data_source/trans_data_source.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteTransDataSource implements TransDataSource {
  final SecureStorageService secureStorageService;
  final NetworkClient client;

  RemoteTransDataSource(this.secureStorageService, this.client);

  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/transactions";

  Future<Map<String, String>> _authHeaders() async {
    final token = await secureStorageService.readString(key: "access_token");
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<TransactionModel> createTransaction(TransactionCreate create) async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'POST',
          url: Uri.parse("$baseUrl/"),
          headers: headers,
          body: jsonEncode(create.toJson()),
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 201) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");

        if (res.statusCode == 400 && detail['code'] == "INVALID_AMOUNT") {
          throw InvalidInputtedAmount();
        } else if (res.statusCode == 400 &&
            detail['code'] == "INSUFFICIENT_BALANCE") {
          throw AccountBalanceTnsufficient();
        }
        throw CouldnotCreateTransaction();
      }

      return TransactionModel.fromFinance(json);
    } on TransactionException {
      rethrow;
    }
  }

  @override
  Future<(TransactionModel, TransactionModel)> createTransferTransaction(
    TransferTransactionCreate create,
  ) async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'POST',
          url: Uri.parse("$baseUrl/transfer"),
          headers: headers,
          body: jsonEncode(create.toJson()),
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 201) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");

        if (res.statusCode == 400 && detail['code'] == "INVALID_AMOUNT") {
          throw InvalidInputtedAmount();
        } else if (res.statusCode == 400 &&
            detail['code'] == "INSUFFICIENT_BALANCE") {
          throw AccountBalanceTnsufficient();
        }
        throw CouldnotCreateTransferTransaction();
      }

      return (
        TransactionModel.fromFinance(
          json["outgoing_transaction"],
        ),
        TransactionModel.fromFinance(
          json["incoming_transaction"],
        ),
      );
    } on TransactionException {
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'DELETE',
          url: Uri.parse("$baseUrl/$id"),
          headers: headers,
        ),
      );

      if (res.statusCode != 204) {
        final json = _decode(res.body);
        final detail = json["detail"];

        if (res.statusCode == 400 &&
            detail?['code'] == "INSUFFICIENT_BALANCE") {
          throw AccountBalanceTnsufficient();
        }
        throw CouldnotDeleteTransaction();
      }
    } on TransactionException {
      rethrow;
    }
  }
  @override
  Future<void> deleteTransferTransaction(String transferGroupId) async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'DELETE',
          url: Uri.parse("$baseUrl/transfer/$transferGroupId"),
          headers: headers,
        ),
      );

      if (res.statusCode != 204) {
        final json = _decode(res.body);
        final detail = json["detail"];

        if (res.statusCode == 400 &&
            detail?['code'] == "INSUFFICIENT_BALANCE") {
          throw AccountBalanceTnsufficient();
        } else if (res.statusCode == 400 &&
            detail?['code'] == "INVALID_TRANSFER_TRANSACTION") {
          throw InvalidTransferTransaction();
        }
        throw CouldnotDeleteTransferTransaction();
      }
    } on TransactionException {
      rethrow;
    }
  }
  @override
  Future<TransactionModel> getTransaction(String id) async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'GET',
          url: Uri.parse("$baseUrl/$id"),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        dev_tool.log("ERROR: ${json["detail"]}");
        throw CouldnotGetTransaction();
      }

      return TransactionModel.fromFinance(json);
    } on TransactionException {
      rethrow;
    }
  }

  @override
  Future<List<TransactionModel>> getUserTransactions() async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'GET',
          url: Uri.parse(baseUrl),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        dev_tool.log("ERROR: ${json["detail"]}");
        throw CouldnotFetchTransactions();
      }

      final data = (json["transactions"] ?? []) as List<dynamic>;

      return data
          .map((t) => TransactionModel.fromFinance(t))
          .toList();
    } on TransactionException {
      rethrow;
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    String id,
    TransactionPatch patch,
  ) async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: 'PATCH',
          url: Uri.parse("$baseUrl/$id"),
          headers: headers,
          body: jsonEncode(patch.toJson()),
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];

        if (res.statusCode == 400 &&
            detail['code'] == "INSUFFICIENT_BALANCE") {
          throw AccountBalanceTnsufficient();
        } else if (res.statusCode == 400 &&
            detail['code'] == "INVALID_AMOUNT") {
          throw InvalidInputtedAmount();
        } else if (res.statusCode == 400 &&
            detail['code'] == "CANNOT_UPDATE_TRANSACTION") {
          throw CannotUpdateTransferTransactions();
        }
        throw CouldnotUpdateTransaction();
      }

      return TransactionModel.fromFinance(json);
    } on TransactionException {
      rethrow;
    }
  }
}
