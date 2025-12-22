import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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

  String _formatMonthParam(DateTime date) => DateFormat('yyyy-MM').format(date);

  DateRange _getMonthRange(DateTime date) {
    return DateRange(
      start: DateTime(date.year, date.month, 1),
      end: DateTime(date.year, date.month + 1, 0),
    );
  }

  Future<void> _refreshAllForMonth() async {
    final cubit = context.read<ReportAnalyticsCubit>();
    // Prevent infinite loading if already busy
    if (cubit.state is ReportAnalyticsPartLoading) return;

    final range = _getMonthRange(_selectedMonth);
    cubit.getTransactionSummary(_formatMonthParam(_selectedMonth), range);
    cubit.getTransactionStats(StatsIn(filterOn: FilterOn.category, range: range));
    cubit.getTransactionTimeSeries(TimeSeriesIn(granulity: _granularity, range: range));
    cubit.getTransactionsForReport(ListTransactionsIn(range: range));
    cubit.getAccountBalances();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _MonthSelector(
            selectedDate: _selectedMonth,
            onChanged: (date) {
              setState(() => _selectedMonth = date);
              _refreshAllForMonth();
            },
          ),
        ),
      ),
      body: BlocBuilder<ReportAnalyticsCubit, ReportAnalyticsState>(
        builder: (context, state) {
          ReportAnalytics? data;
          bool isListLoading = false;

          if (state is ReportAnalyticsLoaded) {
            data = state.data;
          } else if (state is ReportAnalyticsPartLoading) {
            data = state.existing;
            isListLoading = state.partial == ReportAnalyticsIsLoading.listTransaction || state.partial == ReportAnalyticsIsLoading.all;
          }

          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshAllForMonth,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top: Monthly Net Flow (Income - Expense)
                SliverToBoxAdapter(
                  child: _MonthlyNetFlowHeader(summary: data.transactionSummary),
                ),
            
                // 2. Income/Expense Cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _SummaryCardsRow(summary: data.transactionSummary),
                  ),
                ),
            
                // 3. Cash Flow Chart
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: _TimeSeriesSection(
                      timeSeriesList: data.transactionTimeSeriess,
                      granularity: _granularity,
                      onGranularityChanged: (g) {
                        setState(() => _granularity = g);
                        context.read<ReportAnalyticsCubit>().getTransactionTimeSeries(
                          TimeSeriesIn(granulity: g, range: _getMonthRange(_selectedMonth))
                        );
                      },
                      onDateTap: (date) {
                        // Prevent refetch if currently loading
                        if (state is! ReportAnalyticsPartLoading) {
                          context.read<ReportAnalyticsCubit>().getTransactionsForReport(
                            ListTransactionsIn(range: DateRange(start: date, end: date))
                          );
                        }
                      },
                    ),
                  ),
                ),
            
                // 4. Category Breakdown
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _CategoryStatsSection(stats: data.transactionStats),
                  ),
                ),
            
                // 5. Net Worth & Account Balances (RELOCATED HERE)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: _AccountBalancesSection(balances: data.accountBalances),
                  ),
                ),
            
                // 6. Monthly Transactions List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      "Transactions for ${DateFormat.MMMM().format(_selectedMonth)}", 
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            
                if (isListLoading)
                  const SliverToBoxAdapter(child: LinearProgressIndicator()),
            
                SliverOpacity(
                  opacity: isListLoading ? 0.5 : 1.0,
                  sliver: _TransactionsSliverList(transactions: data.transactions),
                ),
                
                const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// helper widget's

class _MonthlyNetFlowHeader extends StatelessWidget {
  final TransactionSummary summary;
  const _MonthlyNetFlowHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = double.tryParse(summary.netSavings) ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text("Monthly Net Flow", style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(
            "ETB ${summary.netSavings}",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: net >= 0 ? Colors.green : Colors.redAccent,
            ),
          ),
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

  const _TimeSeriesSection({
    required this.timeSeriesList,
    required this.granularity,
    required this.onGranularityChanged,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Cash Flow", style: theme.textTheme.titleSmall),
                // Only Day and Week
                Row(
                  children: [Granulity.day, Granulity.week].map((g) {
                    final isSelected = granularity == g;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(g.name.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        onSelected: (_) => onGranularityChanged(g),
                        selectedColor: theme.primaryColor,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  // Fix for Interval: Uses Days, but set interval to 7 for weeks
                  intervalType: DateTimeIntervalType.days,
                  interval: granularity == Granulity.week ? 7 : 1, 
                  dateFormat: granularity == Granulity.day ? DateFormat.d() : DateFormat.Md(),
                  labelStyle: theme.textTheme.bodySmall,
                ),
                primaryYAxis: NumericAxis(isVisible: false),
                series: <CartesianSeries>[
                  ColumnSeries<TransactionTimeSeries, DateTime>(
                    name: 'Income',
                    dataSource: timeSeriesList,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => double.tryParse(data.income) ?? 0,
                    color: Colors.green.withAlpha(179),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    onPointTap: (details) {
                      if (details.pointIndex != null && details.pointIndex! >= 0 && details.pointIndex! < timeSeriesList.length) {
                        onDateTap(timeSeriesList[details.pointIndex!].date);
                      }
                    },
                  ),
                  ColumnSeries<TransactionTimeSeries, DateTime>(
                    name: 'Expense',
                    dataSource: timeSeriesList,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => double.tryParse(data.expense) ?? 0,
                    color: Colors.redAccent.withAlpha(179),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    onPointTap: (details) {
                      if (details.pointIndex != null && details.pointIndex! >= 0 && details.pointIndex! < timeSeriesList.length) {
                        onDateTap(timeSeriesList[details.pointIndex!].date);
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
}

class _AccountBalancesSection extends StatelessWidget {
  final AccountBalances balances;
  const _AccountBalancesSection({required this.balances});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Net Worth", style: theme.textTheme.titleSmall),
            Text("ETB ${balances.totalBalance}", 
                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: balances.accounts.length,
            itemBuilder: (context, i) {
              final acc = balances.accounts[i];
              return Card(
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(acc.name, style: theme.textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text("ETB ${acc.balance}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCardsRow extends StatelessWidget {
  final TransactionSummary summary;
  const _SummaryCardsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compactCurrency(symbol: 'ETB ');
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: "Income",
            value: fmt.format(double.parse(summary.totalIncome)),
            color: Colors.green,
            icon: Icons.south_west,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: "Expense",
            value: fmt.format(double.parse(summary.totalExpense)),
            color: Colors.redAccent,
            icon: Icons.north_east,
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _MonthSelector({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => onChanged(DateTime(selectedDate.year, selectedDate.month - 1)),
          ),
          Text(
            DateFormat.yMMMM().format(selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => onChanged(DateTime(selectedDate.year, selectedDate.month + 1)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CategoryStatsSection extends StatelessWidget {
  final List<TransactionStats> stats;
  const _CategoryStatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: 'ETB ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Spending by Category", style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            ...stats.map((s) {
              final double percent = double.tryParse(s.percentage.replaceAll('%', '')) ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.name, style: theme.textTheme.bodyMedium),
                        Text("${fmt.format(double.parse(s.total))} (${s.percentage})", 
                             style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: theme.dividerColor.withAlpha(26),
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


class _TransactionsSliverList extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionsSliverList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = transactions[index];
          final isExpense = tx.type == TransactionType.EXPENSE;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withAlpha(26),
                child: Icon(isExpense ? Icons.shopping_bag : Icons.account_balance_wallet, 
                      color: theme.primaryColor, size: 20),
              ),
              title: Text(tx.description ?? tx.merchant ?? "Transaction", style: theme.textTheme.bodyMedium),
              subtitle: Text(DateFormat.yMMMd().format(tx.occuredAt), style: theme.textTheme.bodySmall),
              trailing: Text(
                "${isExpense ? '-' : '+'} ${tx.amountValue}",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isExpense ? Colors.redAccent : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        childCount: transactions.length,
      ),
    );
  }
}