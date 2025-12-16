class TransactionSummary {
  final String totalIncome;
  final String totalExpense;
  final String netSavings;
  final int transactionsCount;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.transactionsCount,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalIncome: json['total_income'] as String,
      totalExpense: json['total_expense'] as String,
      netSavings: json['net_savings'] as String,
      transactionsCount: json['transactions_count'] as int,
    );
  }
}
