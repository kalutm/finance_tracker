import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class GetTransactionUc {
  final TransactionService service;
  static final _instance = GetTransactionUc._internal(
    FinanceTransactionService(),
  );
  GetTransactionUc._internal(this.service);
  factory GetTransactionUc() => _instance;

  Future<Transaction> call(String id) async {
    return await service.getTransaction(id);
  }
}
