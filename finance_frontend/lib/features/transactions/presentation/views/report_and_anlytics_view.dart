import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/presentation/cubit/report_analytics_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportAndAnlyticsView extends StatelessWidget {
  const ReportAndAnlyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report & Anlytics")),
      body: BlocConsumer<ReportAnalyticsCubit, ReportAnalyticsState>(
        builder: (context, state) {
          if (state is ReportAnalytics || state is ReportAnalyticsError) {
            final transactionSummary =
                state is ReportAnalytics
                    ? state.transactionSummary
                    : (state as ReportAnalyticsError)
                        .reportAnalytics
                        .transactionSummary;
            final transactionStats =
                state is ReportAnalytics
                    ? state.transactionStats
                    : (state as ReportAnalyticsError)
                        .reportAnalytics
                        .transactionStats;
            final transactionTimeSeriess =
                state is ReportAnalytics
                    ? state.transactionTimeSeriess
                    : (state as ReportAnalyticsError)
                        .reportAnalytics
                        .transactionTimeSeriess;
            final accountBalances =
                state is ReportAnalytics
                    ? state.accountBalances
                    : (state as ReportAnalyticsError)
                        .reportAnalytics
                        .accountBalances;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        "Transaction Summary->",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text("Total Income: ${transactionSummary.totalIncome}"),
                      Text("Total Expense: ${transactionSummary.totalExpense}"),
                      Text("Net Savings: ${transactionSummary.netSavings}"),
                      Text(
                        "Transactions Count: ${transactionSummary.transactionsCount}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats horizontal list with fixed height
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          transactionStats
                              .map(
                                (ts) => SizedBox(
                                  width: 260,
                                  child: Card(
                                    margin: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      leading: Text(ts.name),
                                      title: Text(ts.total),
                                      subtitle: Text(ts.percentage),
                                      trailing: Text(
                                        ts.transactionCount.toString(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time series horizontal list with fixed height
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          transactionTimeSeriess
                              .map(
                                (ts) => SizedBox(
                                  width: 260,
                                  child: Card(
                                    margin: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      leading: Text(ts.date.toString()),
                                      title: Text(ts.income),
                                      subtitle: Text(ts.expense),
                                      trailing: Text(ts.net),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Net worth:",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(accountBalances.totalBalance),
                  const SizedBox(height: 12),
                  // Accounts horizontal list with fixed height
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          accountBalances.accounts
                              .map(
                                (ts) => SizedBox(
                                  width: 260,
                                  child: Card(
                                    margin: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      leading: Text(ts.id.toString()),
                                      title: Text(ts.name),
                                      subtitle: Text(ts.balance),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
        listener: (context, state) {
          if (state is ReportAnalyticsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
      ),
    );
  }
}
