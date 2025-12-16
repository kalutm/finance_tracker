class TransactionTimeSeries {
  final DateTime date;
  final String income;
  final String expense;
  final String net;

  TransactionTimeSeries({
    required this.date,
    required this.income,
    required this.expense,
    required this.net,
  });

  factory TransactionTimeSeries.fromJson(Map<String, dynamic> json) {
    return TransactionTimeSeries(
      date: DateTime.parse(json['date'] as String),
      income: json['income'] as String,
      expense: json['expense'] as String,
      net: json['net'] as String,
    );
  }
}
