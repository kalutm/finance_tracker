import 'dart:convert';
import 'dart:developer' as dev_tool;
import 'package:finance_frontend/core/network/network_client.dart';
import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_bulk_result.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_model.dart';
import 'package:finance_frontend/features/transactions/domain/data_source/trans_data_source.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';

class RemoteTransDataSource implements TransDataSource {
  final SecureStorageService secureStorageService;
  final NetworkClient client;
  final String baseUrl;

  RemoteTransDataSource({
    required this.secureStorageService,
    required this.client,
    required this.baseUrl,
  });

  String get transactionsBaseUrl => "$baseUrl/transactions";

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
          url: Uri.parse("$transactionsBaseUrl/"),
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
  Future<BulkResult> createBulkTransactions(
    List<TransactionCreate> transactions,
  ) async {
    try {
      final headers = await _authHeaders();
      final body = {
        "transactions": transactions.map((create) => create.toJson()).toList(),
      };

      final resp = await client.send(
        RequestModel(
          method: "POST",
          url: Uri.parse("$transactionsBaseUrl/bulk"),
          headers: headers,
          body: jsonEncode(body),
        ),
      );

      if (resp.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(resp.body);
        final inserted = data['inserted'] ?? 0;
        final skipped = data['skipped'] ?? 0;
        final skippedReasons = Map<String, int>.from(
          data['skipped_reasons'] ?? {},
        );
        return BulkResult(
          success: true,
          inserted: inserted,
          skipped: skipped,
          skippedReasons: skippedReasons,
          statusCode: 201,
        );
      } else {
        dev_tool.log('_sendBulk: error: ${resp.body}');
        throw CouldnotCreateBulkTransactions(resp.statusCode);
      }
    } on TransactionException catch (_) {
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
          url: Uri.parse("$transactionsBaseUrl/transfer"),
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
        TransactionModel.fromFinance(json["outgoing_transaction"]),
        TransactionModel.fromFinance(json["incoming_transaction"]),
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
          url: Uri.parse("$transactionsBaseUrl/$id"),
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
          url: Uri.parse("$transactionsBaseUrl/transfer/$transferGroupId"),
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
          url: Uri.parse("$transactionsBaseUrl/$id"),
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
          url: Uri.parse(transactionsBaseUrl),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        dev_tool.log("ERROR: ${json["detail"]}");
        throw CouldnotFetchTransactions();
      }

      final data = (json["transactions"] ?? []) as List<dynamic>;

      return data.map((t) => TransactionModel.fromFinance(t)).toList();
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
          url: Uri.parse("$transactionsBaseUrl/$id"),
          headers: headers,
          body: jsonEncode(patch.toJson()),
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];

        if (res.statusCode == 400 && detail['code'] == "INSUFFICIENT_BALANCE") {
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

  // Report and analytic's mehtod's
  @override
  Future<Map<String, dynamic>> getTransactionSummaryFromMonth(
    String month,
  ) async {
    try {
      final headers = await _authHeaders();
      final res = await client.send(
        RequestModel(
          method: "GET",
          url: Uri.parse("$transactionsBaseUrl/summary?month=$month"),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");
        throw CouldnotGenerateTransactionsSummary();
      }

      return json;
    } on TransactionException catch (_) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionSummaryFromDateRange(
    DateRange range,
  ) async {
    try {
      final headers = await _authHeaders();

      final dateFrom = DateRange.toQueryParam(range.start!);
      final dateTo = DateRange.toQueryParam(range.end!);

      final res = await client.send(
        RequestModel(
          method: "GET",
          url: Uri.parse(
            "$transactionsBaseUrl/summary?date_from=$dateFrom&date_to=$dateTo",
          ),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");
        throw CouldnotGenerateTransactionsSummary();
      }

      return json;
    } on TransactionException catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionStats(
    StatsIn statsIn,
  ) async {
    try {
      final headers = await _authHeaders();
      final by = statsIn.filterOn.name;
      final dateFrom = DateRange.toQueryParam(statsIn.range?.start);
      final dateTo = DateRange.toQueryParam(statsIn.range?.end);

      final res = await client.send(
        RequestModel(
          method: "GET",
          url: Uri.parse(
            "$transactionsBaseUrl/stats?by=$by&is_expense=${statsIn.onlyExpense}&date_from=$dateFrom&date_to=$dateTo&limit=1000",
          ),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");
        throw CouldnotGenerateTransactionsStats();
      }

      return json as List<Map<String, dynamic>>;
    } on TransactionException catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionTimeSeries(
    TimeSeriesIn timeSeriesIn,
  ) async {
    try {
      final headers = await _authHeaders();
      final granulity = timeSeriesIn.granulity.name;
      final dateFrom = DateRange.toQueryParam(timeSeriesIn.range.start!);
      final dateTo = DateRange.toQueryParam(timeSeriesIn.range.end!);

      final res = await client.send(
        RequestModel(
          method: "GET",
          url: Uri.parse(
            "$transactionsBaseUrl/timeseries?date_from=$dateFrom&date_to=$dateTo&granularity=$granulity",
          ),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");
        throw CouldnotGenerateTimeSeries();
      }

      return json as List<Map<String, dynamic>>;
    } on TransactionException catch (_) {
      rethrow;
    }
  }

  @override
  Future<(String, List<Map<String, dynamic>>)> getAccountBalances() async {
    try {
      final headers = await _authHeaders();

      final res = await client.send(
        RequestModel(
          method: "GET",
          url: Uri.parse("$transactionsBaseUrl/balances"),
          headers: headers,
        ),
      );

      final json = _decode(res.body);

      if (res.statusCode != 200) {
        final detail = json["detail"];
        dev_tool.log("ERROR: $detail");
        throw CouldnotGetAccountBalances();
      }

      return (
        json['total_balance'] as String,
        json['accounts'] as List<Map<String, dynamic>>,
      );
    } on TransactionException catch (_) {
      rethrow;
    }
  }
}
