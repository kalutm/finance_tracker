import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class DeleteTransactionUc {
  final TransactionService service;
  static final _instance = DeleteTransactionUc._internal(
    FinanceTransactionService(),
  );
  DeleteTransactionUc._internal(this.service);
  factory DeleteTransactionUc() => _instance;

  Future<void> call(String id) async {
    return await service.deleteTransaction(id);
  }
}
