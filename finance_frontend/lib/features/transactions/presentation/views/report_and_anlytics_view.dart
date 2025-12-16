import 'package:finance_frontend/features/transactions/data/model/report_analytics.dart';
import 'package:finance_frontend/features/transactions/presentation/cubit/report_analytics_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
            final transactionSummary = state is ReportAnalytics? state.transactionSummary : (state as ReportAnalyticsError).reportAnalytics.transactionSummary;
            final transactionStats = state is ReportAnalytics? state.transactionStats : (state as ReportAnalyticsError).reportAnalytics.transactionStats;
            final transactionTimeSeriess = state is ReportAnalytics? state.transactionTimeSeriess : (state as ReportAnalyticsError).reportAnalytics.transactionTimeSeriess;
            final accountBalances = state is ReportAnalytics? state.accountBalances : (state as ReportAnalyticsError).reportAnalytics.accountBalances;
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Transaction Summary->"),
                    Text("Total Income: ${transactionSummary.totalIncome}"),
                    Text("Total Expense: ${transactionSummary.totalExpense}"),
                    Text("Net Savings: ${transactionSummary.netSavings}"),
                    Text(
                      "Transactions Count: ${transactionSummary.transactionsCount}",
                    ),
                  ],
                ),
                ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      transactionStats
                          .map(
                            (ts) => ListTile(
                              leading: Text(ts.name),
                              title: Text(ts.total),
                              subtitle: Text(ts.percentage),
                              trailing: Text(ts.transactionCount.toString()),
                            ),
                          )
                          .toList(),
                ),
                ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      transactionTimeSeriess
                          .map(
                            (ts) => ListTile(
                              leading: Text(ts.date.toString()),
                              title: Text(ts.income),
                              subtitle: Text(ts.expense),
                              trailing: Text(ts.net),
                            ),
                          )
                          .toList(),
                ),
                Text("Net worth:"),
                Text(accountBalances.totalBalance),
                ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      accountBalances.accounts
                          .map(
                            (ts) => ListTile(
                              leading: Text(ts.id.toString()),
                              title: Text(ts.name),
                              subtitle: Text(ts.balance),
                            ),
                          )
                          .toList(),
                ),
              ],
            );
          } else {
            return CircularProgressIndicator();
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
