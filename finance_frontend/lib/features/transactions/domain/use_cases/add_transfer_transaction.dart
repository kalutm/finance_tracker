import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class CreateTransferTransaction {
  final TransactionService service;
  CreateTransferTransaction(this.service);

  Future<Transaction> call(TransferTransactionCreate create) async {
    return await service.createTransferTransaction(create);
  }
}
