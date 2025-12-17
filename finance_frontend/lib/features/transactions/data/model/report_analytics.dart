import 'package:finance_frontend/features/transactions/data/model/account_balances.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_stats.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_summary.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_time_series.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';

class ReportAnalytics {
  final List<Transaction> transactions;
  final TransactionSummary transactionSummary;
  final List<TransactionStats> transactionStats;
  final List<TransactionTimeSeries> transactionTimeSeriess;
  final AccountBalances accountBalances;

  ReportAnalytics({
    required this.transactions,
    required this.transactionSummary,
    required this.transactionStats,
    required this.transactionTimeSeriess,
    required this.accountBalances,
  });
}