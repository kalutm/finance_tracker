import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class DeleteTransferTransactionUc {
  final TransactionService service;
  static final _instance = DeleteTransferTransactionUc._internal(
    FinanceTransactionService(),
  );
  DeleteTransferTransactionUc._internal(this.service);
  factory DeleteTransferTransactionUc() => _instance;

  Future<void> call(String transferGroupId) async {
    return await service.deleteTransferTransaction(transferGroupId);
  }
}
