import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/list_transactions_in.dart';

class ReportAnalyticsIn {
  final ListTransactionsIn listTransactionsIn;
  final String? month;
  final DateRange? range;
  final StatsIn statsIn;
  final TimeSeriesIn timeSeriesIn;

  ReportAnalyticsIn({required this.listTransactionsIn, this.month, this.range, required this.statsIn, required this.timeSeriesIn});
}