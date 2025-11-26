import 'dart:async';

import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';

abstract class TransactionService {
  Future<List<Transaction>> getUserTransactions();

  Stream<List<Transaction>> get transactionsStream;

  Future<Transaction> createTransaction(TransactionCreate create);

  Future<(Transaction, Transaction)> createTransferTransaction(
    TransferTransactionCreate create,
  );

  Future<Transaction> getTransaction(String id);

  Future<Transaction> updateTransaction(String id, TransactionPatch patch);

  Future<void> deleteTransaction(String id);

  Future<void> deleteTransferTransaction(String transferGroupId);

  Future<void> clearCache();
}
