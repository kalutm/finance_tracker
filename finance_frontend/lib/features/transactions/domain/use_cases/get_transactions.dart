import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class GetTransactions {
  final TransactionService service;
  GetTransactions(this.service);

  Future<List<Transaction>> call() async {
    return await service.getUserTransactions();
  }
}
