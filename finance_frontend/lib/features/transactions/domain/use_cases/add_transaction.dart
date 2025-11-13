import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class CreateTransactionUc {
  final TransactionService service;
  static final _instance = CreateTransactionUc._internal(
    FinanceTransactionService(),
  );
  CreateTransactionUc._internal(this.service);
  factory CreateTransactionUc() => _instance;

  Future<Transaction> call(TransactionCreate create) async {
    return await service.createTransaction(create);
  }
}
