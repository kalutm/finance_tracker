import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class CreateTransferTransactionUc {
  final TransactionService service;

  static final _instance = CreateTransferTransactionUc._internal(
    FinanceTransactionService(),
  );
  CreateTransferTransactionUc._internal(this.service);
  factory CreateTransferTransactionUc() => _instance;

  Future<(Transaction, Transaction)> call(
    TransferTransactionCreate create,
  ) async {
    return await service.createTransferTransaction(create);
  }
}
