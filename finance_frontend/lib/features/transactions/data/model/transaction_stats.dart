class TransactionStats {
  final String name;
  final String total;
  final String percentage;
  final int transactionCount;

  TransactionStats({
    required this.name,
    required this.total,
    required this.percentage,
    required this.transactionCount,
  });

  factory TransactionStats.fromJson(Map<String, dynamic> json) {
    return TransactionStats(
      name: json['name'] as String,
      total: json['total'] as String,
      percentage: json['percentage'] as String,
      transactionCount: json['transaction_count'] as int,
    );
  }
}
