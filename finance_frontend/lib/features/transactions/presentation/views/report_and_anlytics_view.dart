// lib/features/transactions/presentation/views/report_and_anlytics_view.dart

// Required pubspec additions:
//   syncfusion_flutter_charts: ^20.4.46
//   intl: ^0.18.0
//   decimal: ^2.0.1

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_loading_enum.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:finance_frontend/themes/app_theme.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_cubit.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_time_series.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_stats.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_summary.dart';
import 'package:finance_frontend/features/transactions/data/model/account_balances.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/list_transactions_in.dart';
import 'package:finance_frontend/features/transactions/domain/entities/filter_on_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/granulity_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

// Main view widget expected by the app wrapper.
class ReportAndAnlyticsView extends StatefulWidget {
  const ReportAndAnlyticsView({super.key});

  @override
  State<ReportAndAnlyticsView> createState() => _ReportAndAnlyticsViewState();
}

class _ReportAndAnlyticsViewState extends State<ReportAndAnlyticsView> {
  ReportAnalytics? _cachedData; // last seen successful data snapshot
  ReportAnalyticsIsLoading? _loadingPart; // when cubit emits PartLoading
  String? _errorMessage;

  // UI state (controls)
  late DateTime _selectedMonthStart;
  DateRange _selectedRange = DateRange(start: DateTime.now(), end: DateTime.now());
  Granulity _granularity = Granulity.day;

  late ReportAnalyticsCubit _cubit;
  final _currencyFormatCache = <String, NumberFormat>{};

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ReportAnalyticsCubit>();
    final now = DateTime.now();
    _selectedMonthStart = DateTime(now.year, now.month, 1);

    // We do not call load here; cubit already initiated loading in constructor.
  }

  NumberFormat _currencyFormatFor(String? currency) {
    final key = (currency ?? 'ETB');
    return _currencyFormatCache.putIfAbsent(key, () {
      try {
        return NumberFormat.simpleCurrency(name: key);
      } catch (_) {
        return NumberFormat.currency(symbol: key);
      }
    });
  }

  void _onPrevMonth() {
    setState(() {
      _selectedMonthStart = DateTime(_selectedMonthStart.year, _selectedMonthStart.month - 1, 1);
    });
    _refreshForMonth();
  }

  void _onNextMonth() {
    setState(() {
      _selectedMonthStart = DateTime(_selectedMonthStart.year, _selectedMonthStart.month + 1, 1);
    });
    _refreshForMonth();
  }

  Future<void> _refreshForMonth() async {
    final month = _selectedMonthStart.toIso8601String().substring(0, 7);
    // Request summary for month
    await _cubit.getTransactionSummary(month, null);

    // request time series for the month range
    final start = _selectedMonthStart;
    final end = DateTime(start.year, start.month + 1, 1);
    final range = DateRange(start: start, end: end);

    await _cubit.getTransactionTimeSeries(
      TimeSeriesIn(granulity: _granularity, range: range),
    );

    await _cubit.getTransactionStats(StatsIn(filterOn: FilterOn.category, range: range));
    await _cubit.getAccountBalances();

    // optionally refresh transactions listing for this range
    await _cubit.getTransactionsForReport(ListTransactionsIn(range: range));
  }

  Future<void> _onGranularityChanged(Granulity g) async {
    setState(() => _granularity = g);
    // refresh timeseries with the selected range
    await _cubit.getTransactionTimeSeries(
      TimeSeriesIn(granulity: g, range: _selectedRange),
    );
  }

  Future<void> _onDayTap(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final listIn = ListTransactionsIn(range: DateRange(start: start, end: end));
    await _cubit.getTransactionsForReport(listIn);
  }

  Future<void> _onPullToRefresh() async {
    // Try to minimally refresh parts using current UI state
    final month = _selectedMonthStart.toIso8601String().substring(0, 7);
    await _cubit.getTransactionSummary(month, null);
    await _cubit.getTransactionTimeSeries(TimeSeriesIn(granulity: _granularity, range: _selectedRange));
    await _cubit.getTransactionStats(StatsIn(filterOn: FilterOn.category, range: _selectedRange));
    await _cubit.getAccountBalances();
    await _cubit.getTransactionsForReport(ListTransactionsIn(range: _selectedRange));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportAnalyticsCubit, ReportAnalyticsState>(
      listener: (context, state) {
        // Update local cache when we see loaded data
        if (state is ReportAnalyticsLoaded) {
          setState(() {
            _cachedData = state.data;
            _loadingPart = null;
            _errorMessage = null;
          });
        } else if (state is ReportAnalyticsPartLoading) {
          setState(() {
            _loadingPart = state.partial;
            // Use existing snapshot provided by cubit to avoid flicker
            if (state.existing != null) _cachedData = state.existing;
          });
        } else if (state is ReportAnalyticsError) {
          setState(() {
            _errorMessage = state.message;
            // keep _cachedData as-is to show previous data
            _loadingPart = null;
          });
        } else if (state is ReportAnalyticsInitial) {
          // ignore
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
              onPressed: _onPrevMonth,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _monthLabel(_selectedMonthStart),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
              onPressed: _onNextMonth,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export not implemented')));
              },
              itemBuilder: (_) => [const PopupMenuItem(value: 'export', child: Text('Export'))],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_cachedData == null) {
      // If no cached data available show a centered loader or friendly empty state
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _cachedData!.transactionSummary;
    final stats = _cachedData!.transactionStats;
    final timeseries = _cachedData!.transactionTimeSeriess;
    final balances = _cachedData!.accountBalances;
    final transactions = _cachedData!.transactions;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) _buildErrorBanner(),
          _buildSummaryCards(summary),
          const SizedBox(height: 12),
          _buildTimeSeriesCard(timeseries, theme),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCategoryCard(stats)),
              const SizedBox(width: 12),
              SizedBox(width: 140, child: _buildBalancesCard(balances)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTransactionsList(transactions),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorMessage ?? '', style: const TextStyle(color: Colors.red))),
          TextButton(onPressed: _onPullToRefresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TransactionSummary summary) {
    final currency = 'ETB'; // default; each model may have currency, but summary is general
    final fmt = _currencyFormatFor(currency);

    final income = _decimalToDouble(summary.totalIncomeValue);
    final expense = _decimalToDouble(summary.totalExpenseValue);
    final net = _decimalToDouble(summary.netSavingsValue);

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _summaryCard('Income', fmt.format(income), Icons.arrow_downward, Colors.green.shade700, isLoading: _loadingPart == ReportAnalyticsIsLoading.transactionSummary),
          const SizedBox(width: 8),
          _summaryCard('Expense', fmt.format(expense), Icons.arrow_upward, Colors.red.shade700, isLoading: _loadingPart == ReportAnalyticsIsLoading.transactionSummary),
          const SizedBox(width: 8),
          _summaryCard('Net', fmt.format(net), Icons.savings, Theme.of(context).primaryColor, isLoading: _loadingPart == ReportAnalyticsIsLoading.transactionSummary),
          const SizedBox(width: 8),
          _summaryCard('Tx Count', '${summary.transactionsCount}', Icons.list, Theme.of(context).colorScheme.secondary, isLoading: false),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, {bool isLoading = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.labelMedium)]),
                if (isLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSeriesCard(List<TransactionTimeSeries> series, ThemeData theme) {
    final isLoading = _loadingPart == ReportAnalyticsIsLoading.transactionTimeSeriess;
    final data = series.map((ts) => _TimeSeriesPoint(date: ts.date, income: _parseDecimalString(ts.income), expense: _parseDecimalString(ts.expense))).toList();

    if (data.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 180,
          child: Center(child: Text('No timeseries data for selected range', style: theme.textTheme.bodyMedium)),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cashflow', style: theme.textTheme.titleMedium),
                Row(children: [
                  _granularityToggle(),
                  const SizedBox(width: 8),
                  if (isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SfCartesianChart(
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                primaryXAxis: DateTimeAxis(edgeLabelPlacement: EdgeLabelPlacement.shift),
                series: <CartesianSeries<_TimeSeriesPoint, DateTime>>[
                  LineSeries<_TimeSeriesPoint, DateTime>(
                    name: 'Income',
                    dataSource: data,
                    xValueMapper: (d, _) => d.date,
                    yValueMapper: (d, _) => d.income,
                    markerSettings: const MarkerSettings(isVisible: true),
                    onPointTap: (pointInteractionDetails) {
                      final idx = pointInteractionDetails.pointIndex;
                      if (idx != null && idx >= 0 && idx < data.length) {
                        final dt = data[idx].date;
                        _onDayTap(dt);
                      }
                    },
                  ),
                  LineSeries<_TimeSeriesPoint, DateTime>(
                    name: 'Expense',
                    dataSource: data,
                    xValueMapper: (d, _) => d.date,
                    yValueMapper: (d, _) => d.expense,
                    markerSettings: const MarkerSettings(isVisible: true),
                    onPointTap: (pointInteractionDetails) {
                      final idx = pointInteractionDetails.pointIndex;
                      if (idx != null && idx >= 0 && idx < data.length) {
                        final dt = data[idx].date;
                        _onDayTap(dt);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _granularityToggle() {
    return ToggleButtons(
      isSelected: [ _granularity == Granulity.day, _granularity == Granulity.week, _granularity == Granulity.month ],
      onPressed: (i) {
        final g = i == 0 ? Granulity.day : (i == 1 ? Granulity.week : Granulity.month);
        _onGranularityChanged(g);
      },
      children: const [ Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Day')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Week')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Month')) ],
    );
  }

  Widget _buildCategoryCard(List<TransactionStats> stats) {
    final isLoading = _loadingPart == ReportAnalyticsIsLoading.transactionStats;
    final chartData = stats
        .map((s) => _PiePoint(name: s.name, value: _parseDecimalString(s.total)))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                if (isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SfCircularChart(
                legend: Legend(isVisible: false, overflowMode: LegendItemOverflowMode.wrap),
                series: <CircularSeries>[
                  DoughnutSeries<_PiePoint, String>(
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.name,
                    yValueMapper: (d, _) => d.value,
                    dataLabelMapper: (d, _) => d.name,
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                  
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // top list
            Column(
              children: stats.take(5).map((s) => _categoryRow(s)).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(TransactionStats s) {
    final value = _parseDecimalString(s.total);
    final fmt = _currencyFormatFor('ETB');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(s.name, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(fmt.format(value), style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildBalancesCard(AccountBalances balances) {
    final fmt = _currencyFormatFor('ETB');
    final total = Decimal.tryParse(balances.totalBalance) ?? Decimal.zero;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Net worth', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(fmt.format(_decimalToDouble(total)), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                itemCount: balances.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final a = balances.accounts[idx];
                  final accFmt = _currencyFormatFor('ETB');
                  final bVal = Decimal.tryParse(a.balance) ?? Decimal.zero;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [Icon(Icons.account_balance_wallet_outlined), const SizedBox(width: 8), Text(a.name)]),
                      Text(accFmt.format(_decimalToDouble(bVal))),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List transactions) {
    // transactions are domain Transaction entities; provide defensive access
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final t = transactions[idx];
              // Defensive: try to read common fields used in UI
              final date = (t.occuredAt ?? t.createdAt) ?? DateTime.now();
              final desc = (t.description ?? t.note ?? '').toString();
              final category = (t.categoryName ?? t.categoryId ?? 'Uncategorized').toString();
              final account = (t.accountName ?? t.accountId ?? '').toString();
              final amtDecimal = Decimal.tryParse((t.amount ?? '0').toString()) ?? Decimal.zero;
              final fmt = _currencyFormatFor(t.currency ?? 'ETB');
              final isExpense = (t.type?.name ?? '').toLowerCase() == 'expense';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onTap: () {
                  // TODO: wire to transaction detail or edit flow. For now, open snack.
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped transaction: ${t.id ?? ''}')));
                },
                leading: CircleAvatar(child: Icon(isExpense ? Icons.trending_down : Icons.trending_up)),
                title: Text(desc.isNotEmpty ? desc : category),
                subtitle: Text('${DateFormat.yMMMd().format(date)} • $account'),
                trailing: Text(_currencyFormatFor(t.currency ?? 'ETB').format(_decimalToDouble(amtDecimal)), style: TextStyle(color: isExpense ? Colors.red : Colors.green)),
              );
            },
          ),
        ]),
      ),
    );
  }

  double _parseDecimalString(String? s) {
    if (s == null) return 0.0;
    final d = Decimal.tryParse(s.toString()) ?? Decimal.zero;
    return _decimalToDouble(d);
  }

  double _decimalToDouble(Decimal d) {
    try {
      return d.toDouble();
    } catch (_) {
      // fallback
      return double.parse(d.toString());
    }
  }

  String _monthLabel(DateTime start) {
    return DateFormat.yMMM().format(start);
  }
}

// Small helper models private to this file
class _TimeSeriesPoint {
  final DateTime date;
  final double income;
  final double expense;
  _TimeSeriesPoint({required this.date, required this.income, required this.expense});
}

class _PiePoint {
  final String name;
  final double value;
  _PiePoint({required this.name, required this.value});
}

/*
QA Checklist (manual) - keep as comments in this file for quick reference:
1. Initial load: open the Reports & Analytics page. Verify summary cards, charts and transactions render.
2. Change month using prev/next: verify values refresh and small loaders appear on affected cards.
3. Pull-to-refresh: verify all parts reload.
4. Tap a day on cashflow chart: verify transactions list updates to that day's transactions.
5. Ensure category chart is read-only (no drill-down) and shows accurate percentages and totals.
6. Simulate partial failures: when network fails, existing data should remain visible and an error banner should appear with a Retry button.
7. Verify currency formatting (ETB) and that income shows green and expense red.
8. Accessibility: check text sizes and contrast in both light & dark modes.

Notes & assumptions:
- This view expects the cubit provided above in the widget tree via BlocProvider.value (as in your wrapper). Do not instantiate the cubit here.
- Transaction entity fields used in UI are defensive (try different properties). If your Transaction domain model uses different property names, adjust the ListTile builder accordingly.
- The view intentionally caches the last successful ReportAnalytics snapshot locally so that partial loading or errors do not remove visible content.
*/
