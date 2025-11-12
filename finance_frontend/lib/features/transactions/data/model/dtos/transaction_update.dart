class TransactionPatch {
  final String? amount;
  final DateTime? occuredAt;
  final String? categoryId;
  final String? description;
  final String? merchant;

  bool get isEmpty =>
      amount == null &&
      occuredAt == null &&
      categoryId == null &&
      description == null &&
      merchant == null;

  TransactionPatch({
    this.occuredAt,
    this.amount,
    this.categoryId,
    this.merchant,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    if (amount != null) 'amount': amount,
    if (occuredAt != null) 'occurred_at': occuredAt?.toIso8601String(),
    if (categoryId != null) 'category_id': categoryId,
    if (merchant != null) 'account_id': merchant,
    if (description != null) 'description': description,
  };
}
