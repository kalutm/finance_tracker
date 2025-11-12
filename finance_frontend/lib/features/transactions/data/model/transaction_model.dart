import 'package:decimal/decimal.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';

class TransactionModel {
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
  final String createdAt;
  final String occuredAt;

  Decimal get amountValue => Decimal.parse(amount);

  TransactionModel({
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
    required this.occuredAt,
  });

  Transaction toEntity() {
    return Transaction(
      id: id,
      amount: amount,
      isOutGoing: isOutGoing,
      accountId: accountId,
      categoryId: categoryId,
      currency: currency,
      merchant: merchant,
      type: type,
      description: description,
      transferGroupId: transferGroupId,
      createdAt: DateTime.parse(createdAt),
      occuredAt: DateTime.parse(occuredAt),
    );
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      isOutGoing: transaction.isOutGoing,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      currency: transaction.currency,
      merchant: transaction.merchant,
      type: transaction.type,
      description: transaction.description,
      transferGroupId: transaction.transferGroupId,
      createdAt: transaction.createdAt.toIso8601String(),
      occuredAt: transaction.occuredAt.toIso8601String(),
    );
  }

  factory TransactionModel.fromFinance(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'],
        amount: json['amount'],
        isOutGoing: json['is_outgoing'],
        accountId: json['account_id'],
        categoryId: json['category_id'],
        currency: json['currency'],
        merchant: json['merchant'],
        type: json['type'],
        description: json['description'],
        transferGroupId: json['transfer_group_id'],
        createdAt: json['created_at'],
        occuredAt: json['occurred_at'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'is_outgoing': isOutGoing,
    'account_id': accountId,
    'category_id': categoryId,
    'currency': currency,
    'merchant': merchant,
    'type': type,
    'description': description,
    'transfer_group_id': transferGroupId,
    'created_at':createdAt,
    'occurred_at':occuredAt,
  };
}
