import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';

class ReportAnalyticsIn {
  String? month;
  DateRange? range;
  StatsIn statsIn;
  TimeSeriesIn timeSeriesIn;

  ReportAnalyticsIn({this.month, this.range, required this.statsIn, required this.timeSeriesIn});
}