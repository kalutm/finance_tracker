import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class GetTransaction {
  final TransactionService service;
  GetTransaction(this.service);

  Future<Transaction> call(String id) async {
    return await service.getTransaction(id);
  }
}
