import 'dart:async';
import 'dart:io';

import 'package:finance_frontend/extensions/date_time_extension.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics_in.dart';
import 'package:finance_frontend/features/transactions/domain/entities/filter_on_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/granulity_enum.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportAnalyticsCubit extends Cubit<ReportAnalyticsState> {
  final TransactionService transactionsService;
  StreamSubscription<ReportAnalyticsIn>? _reportAnalyticsInSub;
  late ReportAnalytics _cachedReportAnalytics;

  ReportAnalyticsCubit(this.transactionsService)
    : super(ReportAnalyticsInitial()) {
    _reportAnalyticsInSub = transactionsService.reportAnalyticsInStream.listen((
      reportAnalyticsIn,
    ) async {
      await loadReportAnalytics(reportAnalyticsIn);
    });

    loadReportAnalytics(
      ReportAnalyticsIn(
        month: DateTime.now().getMonth(),
        statsIn: StatsIn(filterOn: FilterOn.category),
        timeSeriesIn: TimeSeriesIn(
          granulity: Granulity.day,
          range: DateRange(
            start: DateTime(2025, 12, 1),
            end: DateTime(2025, 12, 18),
          ),
        ),
      ),
    );
  }

  Future<void> loadReportAnalytics(ReportAnalyticsIn reportAnalyticsIn) async {
    emit(ReportAnalyticsLoading());
    try {
      final transactionSummary = await transactionsService
          .getTransactionSummary(reportAnalyticsIn.month);
      final transactionStats = await transactionsService.getTransactionStats(
        reportAnalyticsIn.statsIn,
      );
      final transactionTimeSeriess = await transactionsService
          .getTransactionTimeSeries(reportAnalyticsIn.timeSeriesIn);
      final accountBalances = await transactionsService.getAccountBalances();

      final reportAnalytics = ReportAnalytics(
        transactionSummary: transactionSummary,
        transactionStats: transactionStats,
        transactionTimeSeriess: transactionTimeSeriess,
        accountBalances: accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(reportAnalytics);
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionSummary(String? month, DateRange? range) async {
    try {
      emit(ReportAnalyticsLoading());
      final transactionSummary = await transactionsService
          .getTransactionSummary(month, range);
      final reportAnalytics = ReportAnalytics(
        transactionSummary: transactionSummary,
        transactionStats: _cachedReportAnalytics.transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics.transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(reportAnalytics);
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionStats(StatsIn statsIn) async {
    try {
      emit(ReportAnalyticsLoading());
      final transactionStats = await transactionsService.getTransactionStats(
        statsIn,
      );
      final reportAnalytics = ReportAnalytics(
        transactionSummary: _cachedReportAnalytics.transactionSummary,
        transactionStats: transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics.transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(reportAnalytics);
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionTimeSeries(TimeSeriesIn timeSeriesIn) async {
    try {
      emit(ReportAnalyticsLoading());
      final transactionTimeSeriess = await transactionsService
          .getTransactionTimeSeries(timeSeriesIn);
      final reportAnalytics = ReportAnalytics(
        transactionSummary: _cachedReportAnalytics.transactionSummary,
        transactionStats: _cachedReportAnalytics.transactionStats,
        transactionTimeSeriess: transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(reportAnalytics);
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getAccountBalances() async {
    try {
      emit(ReportAnalyticsLoading());
      final accountBalances = await transactionsService.getAccountBalances();
      final reportAnalytics = ReportAnalytics(
        transactionSummary: _cachedReportAnalytics.transactionSummary,
        transactionStats: _cachedReportAnalytics.transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics.transactionTimeSeriess,
        accountBalances: accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(reportAnalytics);
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotGenerateTransactionsSummary)
      return "Couldn't generate transaction Summary please try again later";
    if (e is CouldnotGenerateTransactionsStats)
      return "Couldn't generate transaction Stat's please try again later";
    if (e is CouldnotGenerateTimeSeries)
      return "Couldn't generate transaction TimeSeries's please try again later";
    if (e is SocketException)
      return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
  }

  @override
  Future<void> close() {
    _reportAnalyticsInSub?.cancel();
    return super.close();
  }
}
