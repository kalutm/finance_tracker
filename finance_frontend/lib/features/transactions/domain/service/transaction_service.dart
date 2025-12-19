import 'dart:async';

import 'package:finance_frontend/features/transactions/data/model/account_balances.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/list_transactions_in.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics_in.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_bulk_result.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_stats.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_summary.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_time_series.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';

abstract class TransactionService {
  Future<List<Transaction>> getUserTransactions();

  Stream<List<Transaction>> get transactionsStream;

  Stream<ReportAnalyticsIn> get reportAnalyticsInStream;

  // Transaction Crud mehtod's

  Future<Transaction> createTransaction(TransactionCreate create);

  Future<(Transaction, Transaction)> createTransferTransaction(
    TransferTransactionCreate create,
  );

  Future<Transaction> getTransaction(String id);

  Future<Transaction> updateTransaction(String id, TransactionPatch patch);

  Future<void> deleteTransaction(String id);

  Future<void> deleteTransferTransaction(String transferGroupId);

  Future<void> clearCache();

  Future<BulkResult> createBulkTransactions(
    List<TransactionCreate> transactions,
  );

  // Report and Analytic's method's
  Future<List<Transaction>> listTransactionsForReport(
    ListTransactionsIn listTransactionsIn,
  );
  Future<TransactionSummary> getTransactionSummary([
    String? month,
    DateRange? range,
  ]);
  Future<List<TransactionStats>> getTransactionStats(StatsIn statsIn);
  Future<List<TransactionTimeSeries>> getTransactionTimeSeries(
    TimeSeriesIn timeSeriesIn,
  );
  Future<AccountBalances> getAccountBalances();
  void refreshReportAndAnalytics();
}
