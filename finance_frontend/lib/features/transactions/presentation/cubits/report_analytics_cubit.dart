import 'dart:async';
import 'dart:io';

import 'package:finance_frontend/extensions/date_time_extension.dart';
import 'package:finance_frontend/features/transactions/data/model/account_balances.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/list_transactions_in.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics_in.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_stats.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_summary.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_time_series.dart';
import 'package:finance_frontend/features/transactions/domain/entities/filter_on_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/granulity_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_loading_enum.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportAnalyticsCubit extends Cubit<ReportAnalyticsState> {
  final TransactionService transactionsService;
  StreamSubscription<ReportAnalyticsIn>? _reportAnalyticsInSub;
  ReportAnalytics? _cachedReportAnalytics;

  ReportAnalyticsCubit(this.transactionsService)
    : super(ReportAnalyticsInitial()) {
    _reportAnalyticsInSub = transactionsService.reportAnalyticsInStream.listen((
      reportAnalyticsIn,
    ) async {
      await loadReportAnalytics(reportAnalyticsIn);
    });

    loadReportAnalytics(
      ReportAnalyticsIn(
        listTransactionsIn: ListTransactionsIn(),
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

  void refreshReportAndAnalytics() {
    transactionsService.refreshReportAndAnalytics();
  }

  Future<void> loadReportAnalytics(ReportAnalyticsIn reportAnalyticsIn) async {
    emit(ReportAnalyticsPartLoading(ReportAnalyticsIsLoading.all, _cachedReportAnalytics,));
    try {
      final results = await Future.wait([
        transactionsService.listTransactionsForReport(
          reportAnalyticsIn.listTransactionsIn,
        ),
        transactionsService.getTransactionSummary(reportAnalyticsIn.month),
        transactionsService.getTransactionStats(reportAnalyticsIn.statsIn),
        transactionsService.getTransactionTimeSeries(
          reportAnalyticsIn.timeSeriesIn,
        ),
        transactionsService.getAccountBalances(),
      ]);

      final reportAnalytics = ReportAnalytics(
        transactions: results[0] as List<Transaction>,
        transactionSummary: results[1] as TransactionSummary,
        transactionStats: results[2] as List<TransactionStats>,
        transactionTimeSeriess: results[3] as List<TransactionTimeSeries>,
        accountBalances: results[4] as AccountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(ReportAnalyticsLoaded(reportAnalytics));
    } catch (e) {
      print("ERRORRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR$e");
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionsForReport(
    ListTransactionsIn listTransactionsIn,
  ) async {
    try {
      emit(ReportAnalyticsPartLoading(ReportAnalyticsIsLoading.listTransaction, _cachedReportAnalytics,));
      final transactions = await transactionsService.listTransactionsForReport(
        listTransactionsIn,
      );
      final reportAnalytics = ReportAnalytics(
        transactions: transactions,
        transactionSummary: _cachedReportAnalytics!.transactionSummary,
        transactionStats: _cachedReportAnalytics!.transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics!.transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics!.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(ReportAnalyticsLoaded(reportAnalytics));
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionSummary(String? month, [DateRange? range]) async {
    try {
      emit(ReportAnalyticsPartLoading(ReportAnalyticsIsLoading.transactionSummary, _cachedReportAnalytics,));
      final transactionSummary = await transactionsService
          .getTransactionSummary(month, range);
      final reportAnalytics = ReportAnalytics(
        transactions: _cachedReportAnalytics!.transactions,
        transactionSummary: transactionSummary,
        transactionStats: _cachedReportAnalytics!.transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics!.transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics!.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(ReportAnalyticsLoaded(reportAnalytics));
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionStats(StatsIn statsIn) async {
    try {
      emit(ReportAnalyticsPartLoading(ReportAnalyticsIsLoading.transactionStats, _cachedReportAnalytics));
      final transactionStats = await transactionsService.getTransactionStats(
        statsIn,
      );
      final reportAnalytics = ReportAnalytics(
        transactions: _cachedReportAnalytics!.transactions,
        transactionSummary: _cachedReportAnalytics!.transactionSummary,
        transactionStats: transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics!.transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics!.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(ReportAnalyticsLoaded(reportAnalytics));
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getTransactionTimeSeries(TimeSeriesIn timeSeriesIn) async {
    try {
      emit(ReportAnalyticsPartLoading(ReportAnalyticsIsLoading.transactionTimeSeriess, _cachedReportAnalytics));
      final transactionTimeSeriess = await transactionsService
          .getTransactionTimeSeries(timeSeriesIn);
      final reportAnalytics = ReportAnalytics(
        transactions: _cachedReportAnalytics!.transactions,
        transactionSummary: _cachedReportAnalytics!.transactionSummary,
        transactionStats: _cachedReportAnalytics!.transactionStats,
        transactionTimeSeriess: transactionTimeSeriess,
        accountBalances: _cachedReportAnalytics!.accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(ReportAnalyticsLoaded(reportAnalytics));
    } catch (e) {
      emit(ReportAnalyticsError(_mapErrorToMessage(e), _cachedReportAnalytics));
    }
  }

  Future<void> getAccountBalances() async {
    try {
      emit(ReportAnalyticsPartLoading(ReportAnalyticsIsLoading.accountBalances, _cachedReportAnalytics));
      final accountBalances = await transactionsService.getAccountBalances();
      final reportAnalytics = ReportAnalytics(
        transactions: _cachedReportAnalytics!.transactions,
        transactionSummary: _cachedReportAnalytics!.transactionSummary,
        transactionStats: _cachedReportAnalytics!.transactionStats,
        transactionTimeSeriess: _cachedReportAnalytics!.transactionTimeSeriess,
        accountBalances: accountBalances,
      );
      _cachedReportAnalytics = reportAnalytics;
      emit(ReportAnalyticsLoaded(reportAnalytics));
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
    if (e is CouldnotListTransactionsForReport)
      return "Couldn't list transaction's for Report & Anlytics please try again later";
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
