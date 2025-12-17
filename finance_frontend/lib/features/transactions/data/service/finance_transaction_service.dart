import 'dart:async';
import 'package:finance_frontend/extensions/date_time_extension.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
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
import 'package:finance_frontend/features/transactions/domain/data_source/trans_data_source.dart';
import 'package:finance_frontend/features/transactions/domain/entities/filter_on_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/granulity_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class FinanceTransactionService implements TransactionService {
  final AccountService accountService;
  final TransDataSource source;

  FinanceTransactionService(this.accountService, this.source);
  final List<Transaction> _cachedTransactions = [];
  ReportAnalyticsIn _cachedReportAnalyticsParams = ReportAnalyticsIn(
    listTransactionsIn: ListTransactionsIn(),
    month: DateTime.now().getMonth(),
    statsIn: StatsIn(filterOn: FilterOn.category),
    timeSeriesIn: TimeSeriesIn(
      granulity: Granulity.day,
      range: DateRange(start: DateTime.now(), end: DateTime.now()),
    ),
  );

  final StreamController<List<Transaction>> _controller =
      StreamController<List<Transaction>>.broadcast();
  final StreamController<ReportAnalyticsIn> _reportAnalyticsInController =
      StreamController<ReportAnalyticsIn>.broadcast();

  @override
  Stream<List<Transaction>> get transactionsStream => _controller.stream;

  @override
  Stream<ReportAnalyticsIn> get reportAnalyticsInStream =>
      _reportAnalyticsInController.stream;

  void _emitCache() {
    try {
      _controller.add(List.unmodifiable(_cachedTransactions));
    } catch (_) {}
  }

  Timer? _debounceTimer;
  void _emitReportAndAnalytics() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      try {
        _reportAnalyticsInController.add(_cachedReportAnalyticsParams);
      } catch (_) {}
    });
  }

  @override
  Future<List<Transaction>> getUserTransactions() async {
    final transactions = await source.getUserTransactions();
    final entities = transactions.map((t) => t.toEntity()).toList();

    _cachedTransactions
      ..clear()
      ..addAll(entities);
    _emitCache();

    return List.unmodifiable(_cachedTransactions);
  }

  @override
  Future<Transaction> createTransaction(TransactionCreate create) async {
    final dto = await source.createTransaction(create);
    final entity = dto.toEntity();

    _cachedTransactions.insert(0, entity);
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    // refresh all report and analytic's component's
    _emitReportAndAnalytics();

    return entity;
  }

  @override
  Future<BulkResult> createBulkTransactions(
    List<TransactionCreate> transactions,
  ) async {
    final result = await source.createBulkTransactions(transactions);
    await getUserTransactions();
    await accountService.getUserAccounts();
    return result;
  }

  @override
  Future<(Transaction, Transaction)> createTransferTransaction(
    TransferTransactionCreate create,
  ) async {
    final (outgoingDto, incomingDto) = await source.createTransferTransaction(
      create,
    );

    final outgoing = outgoingDto.toEntity();
    final incoming = incomingDto.toEntity();

    _cachedTransactions.insertAll(0, [outgoing, incoming]);
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    // refresh all report and analytic's component's
    _emitReportAndAnalytics();

    return (outgoing, incoming);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await source.deleteTransaction(id);

    _cachedTransactions.removeWhere((t) => t.id == id);
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    // refresh all report and analytic's component's
    _emitReportAndAnalytics();
  }

  @override
  Future<void> deleteTransferTransaction(String transferGroupId) async {
    await source.deleteTransferTransaction(transferGroupId);

    _cachedTransactions.removeWhere(
      (t) => t.transferGroupId == transferGroupId,
    );
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    // refresh all report and analytic's component's
    _emitReportAndAnalytics();
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    // try cache first
    final cached = _cachedTransactions.firstWhere(
      (t) => t.id == id,
      orElse:
          () => Transaction(
            id: "",
            amount: "0",
            accountId: "",
            currency: "",
            type: TransactionType.values.first,
            createdAt: DateTime.now(),
            occuredAt: DateTime.now(),
          ),
    );
    if (cached.id.isNotEmpty) return cached;

    final dto = await source.getTransaction(id);
    final entity = dto.toEntity();

    final idx = _cachedTransactions.indexWhere((t) => t.id == entity.id);
    if (idx != -1) {
      _cachedTransactions[idx] = entity;
    } else {
      _cachedTransactions.insert(0, entity);
    }
    _emitCache();

    return entity;
  }

  @override
  Future<Transaction> updateTransaction(
    String id,
    TransactionPatch patch,
  ) async {
    final dto = await source.updateTransaction(id, patch);
    final entity = dto.toEntity();

    final idx = _cachedTransactions.indexWhere((t) => t.id == entity.id);
    if (idx != -1) {
      _cachedTransactions[idx] = entity;
    } else {
      _cachedTransactions.insert(0, entity);
    }
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    // refresh all report and analytic's component's
    _emitReportAndAnalytics();

    return entity;
  }

  // Report and analytic's method's
  @override
  Future<List<Transaction>> listTransactionsForReport(
    ListTransactionsIn listTransactionsIn,
  ) async {
    final reportAnalyticsIn = ReportAnalyticsIn(
      listTransactionsIn: listTransactionsIn,
      month: _cachedReportAnalyticsParams.month,
      range: _cachedReportAnalyticsParams.range,
      statsIn: _cachedReportAnalyticsParams.statsIn,
      timeSeriesIn: _cachedReportAnalyticsParams.timeSeriesIn,
    );
    _cachedReportAnalyticsParams = reportAnalyticsIn;
    final listTransaction = await source.listTransactionsForReport(
      listTransactionsIn,
    );
    return listTransaction.map((tModel) => tModel.toEntity()).toList();
  }

  @override
  Future<TransactionSummary> getTransactionSummary([
    String? month,
    DateRange? range,
  ]) async {
    final reportAnalyticsIn = ReportAnalyticsIn(
      listTransactionsIn: _cachedReportAnalyticsParams.listTransactionsIn,
      month: month,
      range: range,
      statsIn: _cachedReportAnalyticsParams.statsIn,
      timeSeriesIn: _cachedReportAnalyticsParams.timeSeriesIn,
    );
    _cachedReportAnalyticsParams = reportAnalyticsIn;

    if (month != null) {
      final summaryMap = await source.getTransactionSummaryFromMonth(month);
      return TransactionSummary.fromJson(summaryMap);
    } else {
      final summaryMap = await source.getTransactionSummaryFromDateRange(
        range!,
      );
      return TransactionSummary.fromJson(summaryMap);
    }
  }

  @override
  Future<List<TransactionStats>> getTransactionStats(StatsIn statsIn) async {
    final reportAnalyticsIn = ReportAnalyticsIn(
      listTransactionsIn: _cachedReportAnalyticsParams.listTransactionsIn,
      month: _cachedReportAnalyticsParams.month,
      range: _cachedReportAnalyticsParams.range,
      statsIn: statsIn,
      timeSeriesIn: _cachedReportAnalyticsParams.timeSeriesIn,
    );
    _cachedReportAnalyticsParams = reportAnalyticsIn;
    final statsList = await source.getTransactionStats(statsIn);
    return statsList.map((s) => TransactionStats.fromJson(s)).toList();
  }

  @override
  Future<List<TransactionTimeSeries>> getTransactionTimeSeries(
    TimeSeriesIn timeSeriesIn,
  ) async {
    final reportAnalyticsIn = ReportAnalyticsIn(
      listTransactionsIn: _cachedReportAnalyticsParams.listTransactionsIn,
      month: _cachedReportAnalyticsParams.month,
      range: _cachedReportAnalyticsParams.range,
      statsIn: _cachedReportAnalyticsParams.statsIn,
      timeSeriesIn: timeSeriesIn,
    );
  _cachedReportAnalyticsParams = reportAnalyticsIn;
    final timeSeriesList = await source.getTransactionTimeSeries(timeSeriesIn);
    return timeSeriesList
        .map((ts) => TransactionTimeSeries.fromJson(ts))
        .toList();
  }

  @override
  Future<AccountBalances> getAccountBalances() async {
    final (totalBalance, accountsList) = await source.getAccountBalances();
    final accounts = AccountBalances.accountsFromJson(accountsList);
    return AccountBalances(totalBalance: totalBalance, accounts: accounts);
  }

  // helper's
  @override
  Future<void> clearCache() async {
    _cachedTransactions.clear();
    _emitCache();
  }

  // close stream when app disposes
  void dispose() {
    if (!_controller.isClosed) _controller.close();
    if (!_reportAnalyticsInController.isClosed) _reportAnalyticsInController.close();
      _debounceTimer?.cancel();
  }
}
