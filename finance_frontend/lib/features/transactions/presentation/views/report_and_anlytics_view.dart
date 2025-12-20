// -------------------------------------------------------------------------
// DEPENDENCY INSTRUCTIONS:
// Add to pubspec.yaml:
//   syncfusion_flutter_charts: ^24.0.0
//   intl: ^0.19.0
// -------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// -------------------------------------------------------------------------
// PROJECT IMPORTS
// -------------------------------------------------------------------------
import 'package:finance_frontend/themes/app_theme.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_cubit.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_state.dart';
import 'package:finance_frontend/features/transactions/presentation/cubits/report_analytics_loading_enum.dart';
import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_summary.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_stats.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_time_series.dart';
import 'package:finance_frontend/features/transactions/data/model/account_balances.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:finance_frontend/features/transactions/domain/entities/granulity_enum.dart';
import 'package:finance_frontend/features/transactions/domain/entities/filter_on_enum.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/date_range.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/stats_in.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/time_series_in.dart';
import 'package:finance_frontend/features/transactions/data/model/list_transactions_in.dart';

class ReportAndAnlyticsView extends StatefulWidget {
  const ReportAndAnlyticsView({super.key});

  @override
  State<ReportAndAnlyticsView> createState() => _ReportAndAnlyticsViewState();
}

class _ReportAndAnlyticsViewState extends State<ReportAndAnlyticsView> {
  DateTime _selectedMonth = DateTime.now();
  Granulity _granularity = Granulity.day;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- Date Helpers ---
  String _formatMonthParam(DateTime date) => DateFormat('yyyy-MM').format(date);

  DateRange _getMonthRange(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    return DateRange(start: start, end: end);
  }

  // --- Interactions ---
  void _onMonthChanged(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _refreshAllForMonth();
  }

  void _onDatePicked(DateTime picked) {
    setState(() => _selectedMonth = picked);
    _refreshAllForMonth();
  }

  void _refreshAllForMonth() {
    final cubit = context.read<ReportAnalyticsCubit>();
    final monthStr = _formatMonthParam(_selectedMonth);
    final monthRange = _getMonthRange(_selectedMonth);

    cubit.getTransactionSummary(monthStr, monthRange);
    cubit.getTransactionStats(StatsIn(filterOn: FilterOn.category, range: monthRange, onlyExpense: true));
    cubit.getTransactionTimeSeries(TimeSeriesIn(granulity: _granularity, range: monthRange));
    cubit.getTransactionsForReport(ListTransactionsIn(range: monthRange));
    cubit.getAccountBalances();
  }

  void _onGranularityChanged(Granulity newGranularity) {
    if (_granularity == newGranularity) return;
    setState(() => _granularity = newGranularity);
    context.read<ReportAnalyticsCubit>().getTransactionTimeSeries(TimeSeriesIn(
      granulity: newGranularity,
      range: _getMonthRange(_selectedMonth),
    ));
  }

  Future<void> _onPullRefresh() async {
    _refreshAllForMonth();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export functionality coming soon')),
              );
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _MonthSelector(
            selectedDate: _selectedMonth,
            onPrev: () => _onMonthChanged(-1),
            onNext: () => _onMonthChanged(1),
            onTapDate: () async {
               final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) _onDatePicked(picked);
            },
          ),
        ),
      ),
      body: BlocConsumer<ReportAnalyticsCubit, ReportAnalyticsState>(
        listener: (context, state) {
          if (state is ReportAnalyticsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), action: SnackBarAction(label: 'Retry', onPressed: _onPullRefresh)),
            );
          }
        },
        builder: (context, state) {
          if (state is ReportAnalyticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          ReportAnalytics? data;
          bool isSummaryLoading = false;
          bool isStatsLoading = false;
          bool isTimeSeriesLoading = false;
          bool isBalancesLoading = false;
          bool isListLoading = false;

          if (state is ReportAnalyticsLoaded) {
            data = state.data;
          } else if (state is ReportAnalyticsPartLoading) {
            data = state.existing;
            isSummaryLoading = state.partial == ReportAnalyticsIsLoading.transactionSummary || state.partial == ReportAnalyticsIsLoading.all;
            isStatsLoading = state.partial == ReportAnalyticsIsLoading.transactionStats || state.partial == ReportAnalyticsIsLoading.all;
            isTimeSeriesLoading = state.partial == ReportAnalyticsIsLoading.transactionTimeSeriess || state.partial == ReportAnalyticsIsLoading.all;
            isBalancesLoading = state.partial == ReportAnalyticsIsLoading.accountBalances || state.partial == ReportAnalyticsIsLoading.all;
            isListLoading = state.partial == ReportAnalyticsIsLoading.listTransaction || state.partial == ReportAnalyticsIsLoading.all;
          } else if (state is ReportAnalyticsError) {
            data = state.reportAnalytics;
          }

          if (data == null) {
            return Center(
              child: FilledButton.icon(onPressed: _onPullRefresh, icon: const Icon(Icons.refresh), label: const Text('Reload')),
            );
          }

          return RefreshIndicator(
            onRefresh: _onPullRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 1. Summary Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _SectionLoader(
                      isLoading: isSummaryLoading,
                      child: _SummaryCardsRow(summary: data.transactionSummary),
                    ),
                  ),
                ),

                // 2. Time Series Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionLoader(
                      isLoading: isTimeSeriesLoading,
                      child: _TimeSeriesSection(
                        timeSeriesList: data.transactionTimeSeriess,
                        granularity: _granularity,
                        onGranularityChanged: _onGranularityChanged,
                        onDateTap: (date) {
                          context.read<ReportAnalyticsCubit>().getTransactionsForReport(
                            ListTransactionsIn(range: DateRange(start: date, end: date))
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 3. Stats & Balances
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SectionLoader(
                          isLoading: isStatsLoading,
                          child: _CategoryStatsSection(
                            stats: data.transactionStats,
                            onCategoryTap: (catName) {
                               // Drill down logic placeholder
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionLoader(
                          isLoading: isBalancesLoading,
                          child: _AccountBalancesSection(balances: data.accountBalances),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Transactions (${data.transactions.length})",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // 5. Loading indicator for list (Standard Flutter way)
                if (isListLoading)
                   const SliverToBoxAdapter(
                     child: LinearProgressIndicator(minHeight: 2),
                   ),

                // 6. Transaction List (Standard Flutter Opacity)
                SliverOpacity(
                  opacity: isListLoading ? 0.5 : 1.0,
                  sliver: _TransactionsSliverList(transactions: data.transactions),
                ),
                
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------------
// PRIVATE WIDGETS
// -------------------------------------------------------------------------

class _SectionLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const _SectionLoader({required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: IgnorePointer(child: child)),
        Positioned.fill(child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapDate;

  const _MonthSelector({required this.selectedDate, required this.onPrev, required this.onNext, required this.onTapDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          InkWell(
            onTap: onTapDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(DateFormat.yMMMM().format(selectedDate), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_month, size: 18),
                ],
              ),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _SummaryCardsRow extends StatelessWidget {
  final TransactionSummary summary;
  const _SummaryCardsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final income = double.tryParse(summary.totalIncome) ?? 0.0;
    final expense = double.tryParse(summary.totalExpense) ?? 0.0;
    final net = double.tryParse(summary.netSavings) ?? 0.0;
    final fmt = NumberFormat.simpleCurrency(name: 'ETB', decimalDigits: 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SummaryCard(title: 'Income', amount: fmt.format(income), icon: Icons.arrow_downward, color: Colors.green),
          const SizedBox(width: 12),
          _SummaryCard(title: 'Expense', amount: fmt.format(expense), icon: Icons.arrow_upward, color: Colors.red),
          const SizedBox(width: 12),
          _SummaryCard(title: 'Net Savings', amount: fmt.format(net), icon: Icons.account_balance_wallet, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          _SummaryCard(title: 'Count', amount: '${summary.transactionsCount}', icon: Icons.receipt_long, color: Colors.orange),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(amount, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TimeSeriesSection extends StatelessWidget {
  final List<TransactionTimeSeries> timeSeriesList;
  final Granulity granularity;
  final ValueChanged<Granulity> onGranularityChanged;
  final ValueChanged<DateTime> onDateTap;

  const _TimeSeriesSection({required this.timeSeriesList, required this.granularity, required this.onGranularityChanged, required this.onDateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (timeSeriesList.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: const Text("No chart data"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cash Flow", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              _GranularitySwitch(current: granularity, onChanged: onGranularityChanged),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                dateFormat: granularity == Granulity.month ? DateFormat.MMM() : DateFormat.Md(),
              ),
              primaryYAxis: NumericAxis(isVisible: false),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries>[
                SplineAreaSeries<TransactionTimeSeries, DateTime>(
                  dataSource: timeSeriesList,
                  xValueMapper: (TransactionTimeSeries data, _) => data.date,
                  yValueMapper: (TransactionTimeSeries data, _) => double.tryParse(data.income) ?? 0,
                  name: 'Income',
                  color: Colors.green.withOpacity(0.3),
                  borderColor: Colors.green,
                  // FIX: Interaction moved here
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) onDateTap(timeSeriesList[details.pointIndex!].date);
                  },
                ),
                SplineAreaSeries<TransactionTimeSeries, DateTime>(
                  dataSource: timeSeriesList,
                  xValueMapper: (TransactionTimeSeries data, _) => data.date,
                  yValueMapper: (TransactionTimeSeries data, _) => double.tryParse(data.expense) ?? 0,
                  name: 'Expense',
                  color: Colors.red.withOpacity(0.3),
                  borderColor: Colors.red,
                  // FIX: Interaction moved here
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) onDateTap(timeSeriesList[details.pointIndex!].date);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GranularitySwitch extends StatelessWidget {
  final Granulity current;
  final ValueChanged<Granulity> onChanged;

  const _GranularitySwitch({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: Granulity.values.map((g) {
        final isSelected = g == current;
        return GestureDetector(
          onTap: () => onChanged(g),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.transparent : theme.dividerColor),
            ),
            child: Text(
              g.name.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? Colors.white : theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryStatsSection extends StatelessWidget {
  final List<TransactionStats> stats;
  final ValueChanged<String> onCategoryTap;

  const _CategoryStatsSection({required this.stats, required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Spending by Category", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCircularChart(
              series: <CircularSeries>[
                DoughnutSeries<TransactionStats, String>(
                  dataSource: stats,
                  xValueMapper: (TransactionStats data, _) => data.name,
                  yValueMapper: (TransactionStats data, _) => double.tryParse(data.total) ?? 0,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                  onPointTap: (ChartPointDetails details) {
                    if (details.pointIndex != null) onCategoryTap(stats[details.pointIndex!].name);
                  },
                )
              ],
              legend: Legend(isVisible: true, position: LegendPosition.right, overflowMode: LegendItemOverflowMode.wrap),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBalancesSection extends StatelessWidget {
  final AccountBalances balances;
  const _AccountBalancesSection({required this.balances});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: 'ETB', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Accounts", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text("Total: ${fmt.format(double.tryParse(balances.totalBalance) ?? 0)}", style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: balances.accounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final acc = balances.accounts[index];
              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(acc.name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(fmt.format(double.tryParse(acc.balance) ?? 0), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionsSliverList extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionsSliverList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: 'ETB');

    if (transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text("No transactions found", style: theme.textTheme.bodyMedium)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = transactions[index];
          final amountVal = tx.amountValue.toDouble();
          
          final isExpense = tx.type == TransactionType.EXPENSE;
          final isTransfer = tx.type == TransactionType.TRANSFER;
          
          Color color = isExpense ? Colors.red : Colors.green;
          IconData icon = isExpense ? Icons.arrow_outward : Icons.arrow_downward;
          if (isTransfer) {
            color = Colors.blue;
            icon = Icons.swap_horiz;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
              title: Text(tx.description ?? (tx.merchant ?? 'Unknown'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1),
              subtitle: Text(DateFormat.MMMEd().format(tx.occuredAt), style: theme.textTheme.bodySmall),
              trailing: Text(fmt.format(amountVal.abs()), style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
          );
        },
        childCount: transactions.length,
      ),
    );
  }
}