class TransactionCreate {
  final String amount;
  final DateTime occuredAt;
  final String accountId;
  final String categoryId;
  final String currency;
  final String? merchant;
  final String type;
  final String? description;

  TransactionCreate({
    required this.amount,
    required this.occuredAt,
    required this.accountId,
    required this.categoryId,
    required this.currency,
    this.merchant,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'occurred_at': occuredAt.toIso8601String(),
        'account_id': accountId,
        'category_id': categoryId,
        'currency': currency,
        'merchant': merchant,
        'type': type,
        'description': description,
      };
}
