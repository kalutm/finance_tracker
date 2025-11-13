import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

class TransferTransactionCreate {
  final int accountId;
  final int toAccountId;
  final String amount;
  final String currency;
  final TransactionType type;
  final String? description;
  final DateTime? occurredAt;

  TransferTransactionCreate({
    required this.accountId,
    required this.toAccountId,
    required this.amount,
    required this.currency,
    required this.type,
    this.description,
    this.occurredAt,
  });

  Map<String, dynamic> toJson() => {
        "account_id": accountId,
        "to_account_id": toAccountId,
        "amount": amount,
        "currency": currency,
        "type": type.name,
        "description": description,
        "occurred_at": occurredAt!.toIso8601String(),
      };
}
