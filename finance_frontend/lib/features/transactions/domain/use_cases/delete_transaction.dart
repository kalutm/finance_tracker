import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class DeleteTransaction {
  final TransactionService service;
  DeleteTransaction(this.service);

  Future<void> call(String id) async {
    return await service.deleteTransaction(id);
  }
}
