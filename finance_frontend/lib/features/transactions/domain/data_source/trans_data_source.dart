import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_bulk_result.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_model.dart';

abstract class TransDataSource {
  // transaction crud method's
  Future<TransactionModel> createTransaction(TransactionCreate create);
  Future<(TransactionModel, TransactionModel)> createTransferTransaction(
    TransferTransactionCreate create,
  );
  Future<void> deleteTransaction(String id);
  Future<void> deleteTransferTransaction(String transferGroupId);
  Future<TransactionModel> getTransaction(String id);
  Future<List<TransactionModel>> getUserTransactions();
  Future<TransactionModel> updateTransaction(String id, TransactionPatch patch);
  Future<BulkResult> createBulkTransactions(
    List<TransactionCreate> transactions,
  );

  // report and analytic's method's
  Future<Map<String, dynamic>> getTransactionSummaryFromMonth(String month);
  Future<Map<String, dynamic>> getTransactionSummaryFromDateRange(
    DateRange range,
  );
  Future<List<Map<String, dynamic>>> getTransactionStats(
    StatsIn statsIn,
  );
  Future<List<Map<String, dynamic>>> getTransactionTimeSeries(
    TimeSeriesIn timeSeriesIn,
  );
  Future<(String, List<Map<String, dynamic>>)> getAccountBalances();
}
