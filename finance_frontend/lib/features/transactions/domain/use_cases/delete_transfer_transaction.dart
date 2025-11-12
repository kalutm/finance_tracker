import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class DeleteTransferTransaction {
  final TransactionService service;
  DeleteTransferTransaction(this.service);

  Future<void> call(String transferGroupId) async {
    return await service.deleteTransferTransaction(transferGroupId);
  }
}
