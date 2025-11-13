import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class UpdateTransactionUc {
  final TransactionService service;
  static final _instance = UpdateTransactionUc._internal(
    FinanceTransactionService(),
  );
  UpdateTransactionUc._internal(this.service);
  factory UpdateTransactionUc() => _instance;
  Future<Transaction> call(String id, TransactionPatch patch) async {
    return await service.updateTransaction(id, patch);
  }
}
