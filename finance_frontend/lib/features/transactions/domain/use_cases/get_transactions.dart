import 'package:finance_frontend/features/transactions/data/service/finance_transaction_service.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class GetTransactionsUc {
  final TransactionService service;
  static final _instance = GetTransactionsUc._internal(
    FinanceTransactionService(),
  );
  GetTransactionsUc._internal(this.service);
  factory GetTransactionsUc() => _instance;

  Future<List<Transaction>> call() async {
    return await service.getUserTransactions();
  }
}
