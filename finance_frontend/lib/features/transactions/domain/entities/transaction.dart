
class Transaction {
  final String id;
  final String amount;
  final bool? isOutGoing;
  final String accountId;
  final String categoryId;
  final String currency;
  final String? merchant;
  final String type;
  final String? description;
  final String? transferGroupId;
  final DateTime createdAt;
  final DateTime occuredAt;


  Transaction({
    required this.id,
    required this.amount,
    this.isOutGoing,
    required this.accountId,
    required this.categoryId,
    required this.currency,
    this.merchant,
    required this.type,
    this.description,
    this.transferGroupId,
    required this.createdAt,
    required this.occuredAt
  });
}
