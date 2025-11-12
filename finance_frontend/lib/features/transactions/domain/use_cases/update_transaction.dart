import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class UpdateTransaction {
  final TransactionService service;
  UpdateTransaction(this.service);

  Future<Transaction> call(String id, TransactionPatch patch) async {
    return await service.updateTransaction(id, patch);
  }
}
