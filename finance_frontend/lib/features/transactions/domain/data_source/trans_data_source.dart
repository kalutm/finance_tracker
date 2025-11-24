import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/transaction_model.dart';

abstract class TransDataSource {
  Future<TransactionModel> createTransaction(TransactionCreate create);
  Future<(TransactionModel, TransactionModel)> createTransferTransaction(
    TransferTransactionCreate create,
  );
  Future<void> deleteTransaction(String id);
  Future<void> deleteTransferTransaction(String transferGroupId);
  Future<TransactionModel> getTransaction(String id);
  Future<List<TransactionModel>> getUserTransactions();
  Future<TransactionModel> updateTransaction(String id, TransactionPatch patch);
  
}
