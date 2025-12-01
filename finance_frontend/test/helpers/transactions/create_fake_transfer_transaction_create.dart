import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';

TransferTransactionCreate fakeTransferTransactionCreate() {
  return TransferTransactionCreate(
    accountId: "1",
    toAccountId: "2",
    amount: "50",
    currency: "ETB",
    type: TransactionType.TRANSFER,
    description: "test transaction",
    occurredAt: DateTime.now(),
  );
}
