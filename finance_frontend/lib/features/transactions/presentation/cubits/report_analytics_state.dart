import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_loading_enum.dart';

class ReportAnalyticsState {}

class ReportAnalyticsInitial extends ReportAnalyticsState {}

class ReportAnalyticsPartLoading extends ReportAnalyticsState { 
  final ReportAnalyticsIsLoading partial; 
  final ReportAnalytics? existing;
  ReportAnalyticsPartLoading(this.partial, this.existing);
  }

class ReportAnalyticsLoaded extends ReportAnalyticsState { 
  final ReportAnalytics data; 
  ReportAnalyticsLoaded(this.data);
  }

class ReportAnalyticsError extends ReportAnalyticsState {
  final String message;
  final ReportAnalytics? reportAnalytics;
  ReportAnalyticsError(this.message, [this.reportAnalytics]);
}
