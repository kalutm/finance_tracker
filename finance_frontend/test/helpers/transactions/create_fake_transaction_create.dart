import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

TransactionCreate fakeTransactionCreate({
  TransactionType? type,
}) {
  return TransactionCreate(
    amount: "50",
    occuredAt: DateTime.now(),
    accountId: "1",
    categoryId: "1",
    currency: "ETB",
    merchant: "Queen's",
    type: type ?? TransactionType.EXPENSE,
    description: "test transaction",
  );
}
