import 'package:finance_frontend/features/transactions/data/model/account_balances.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_stats.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_summary.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_time_series.dart';

class ReportAnalyticsState {}

class ReportAnalyticsInitial extends ReportAnalyticsState {}

class ReportAnalyticsLoading extends ReportAnalyticsState {}

class ReportAnalytics extends ReportAnalyticsState {
  final TransactionSummary transactionSummary;
  final List<TransactionStats> transactionStats;
  final List<TransactionTimeSeries> transactionTimeSeriess;
  final AccountBalances accountBalances;

  ReportAnalytics({
    required this.transactionSummary,
    required this.transactionStats,
    required this.transactionTimeSeriess,
    required this.accountBalances,
  });
}

class ReportAnalyticsError extends ReportAnalyticsState {
  final String message;
  final ReportAnalytics reportAnalytics;
  ReportAnalyticsError(this.message, this.reportAnalytics);
}
