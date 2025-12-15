import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

class TransactionCreate {
  final String amount;
  final DateTime occuredAt;
  final String accountId;
  final String? categoryId;
  final String currency;
  final String? merchant;
  final TransactionType type;
  final String? description;
  final String? messageId;

  TransactionCreate({
    required this.amount,
    required this.occuredAt,
    required this.accountId,
    this.categoryId,
    required this.currency,
    this.merchant,
    required this.type,
    this.description,
    this.messageId,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'occurred_at': occuredAt.toIso8601String(),
    'account_id': accountId,
    'category_id': categoryId,
    'currency': currency,
    'merchant': merchant,
    'type': type.name,
    'description': description,
    'message_id': messageId,
  };
}
