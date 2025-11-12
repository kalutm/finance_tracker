import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class CreateTransaction {
  final TransactionService service;
  CreateTransaction(this.service);

  Future<Transaction> call(TransactionCreate create) async {
    return await service.createTransaction(create);
  }
}
