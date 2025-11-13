import 'package:decimal/decimal.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

class TransactionModel {
  final String id;
  final String amount;
  final bool? isOutGoing;
  final String accountId;
  final String? categoryId;
  final String currency;
  final String? merchant;
  final TransactionType type;
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
    this.categoryId,
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

  factory TransactionModel.fromFinance(
    Map<String, dynamic> json,
  ) => TransactionModel(
    id: (json['id'] as int).toString(),
    amount: json['amount'] as String,
    isOutGoing:
        json['is_outgoing'] != null ? (json['is_outgoing'] as bool) : null,
    accountId: (json['account_id'] as int).toString(),
    categoryId:
        json['category_id'] != null
            ? (json['category_id'] as int).toString()
            : null,
    currency: json['currency'] as String,
    merchant: json['merchant'] != null ? (json['merchant'] as String) : null,
    type: TransactionType.values.byName(json['type'] as String),
    description:
        json['description'] != null ? (json['description'] as String) : null,
    transferGroupId:
        json['transfer_group_id'] != null
            ? (json['transfer_group_id'] as String)
            : null,
    createdAt: json['created_at'] as String,
    occuredAt: json['occurred_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'is_outgoing': isOutGoing,
    'account_id': accountId,
    'category_id': categoryId,
    'currency': currency,
    'merchant': merchant,
    'type': type.name,
    'description': description,
    'transfer_group_id': transferGroupId,
    'created_at': createdAt,
    'occurred_at': occuredAt,
  };
}
