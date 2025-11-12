import 'package:finance_frontend/features/transactions/data/data_sources/remote_data_source.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class FinanceTransactionService implements TransactionService {
  final RemoteDataSource source;

  FinanceTransactionService._internal(this.source);
  static final FinanceTransactionService _instance =
      FinanceTransactionService._internal(RemoteDataSource());
  factory FinanceTransactionService() => _instance;

  @override
  Future<Transaction> createTransaction(TransactionCreate create) async {
    final transaction = await source.createTransaction(create);
    return transaction.toEntity();
  }

  @override
  Future<Transaction> createTransferTransaction(
    TransferTransactionCreate create,
  ) async {
    final transaction = await source.createTransferTransaction(create);
    return transaction.toEntity();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await source.deleteTransaction(id);
  }

  @override
  Future<void> deleteTransferTransaction(String transferGroupId) async {
    await source.deleteTransferTransaction(transferGroupId);
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    final transaction = await source.getTransaction(id);
    return transaction.toEntity();
  }

  @override
  Future<List<Transaction>> getUserTransactions() async {
    final transactions = await source.getUserTransactions();
    return transactions.map((transaction) => transaction.toEntity()).toList();
  }

  @override
  Future<Transaction> updateTransaction(String id, TransactionPatch patch) async {
    final transaction = await source.updateTransaction(id, patch);
    return transaction.toEntity();
  }
}
