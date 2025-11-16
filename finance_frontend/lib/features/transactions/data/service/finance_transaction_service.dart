import 'dart:async';

import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/transactions/data/data_sources/remote_data_source.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';

class FinanceTransactionService implements TransactionService {
  final AccountService accountService;
  final RemoteDataSource source;

  FinanceTransactionService._internal(this.source, this.accountService);
  static final FinanceTransactionService _instance =
      FinanceTransactionService._internal(
        RemoteDataSource(),
        FinanceAccountService(),
      );
  factory FinanceTransactionService() => _instance;

  final List<Transaction> _cachedTransactions = [];
  final StreamController<List<Transaction>> _controller =
      StreamController<List<Transaction>>.broadcast();

  @override
  Stream<List<Transaction>> get transactionsStream => _controller.stream;

  void _emitCache() {
    try {
      _controller.add(List.unmodifiable(_cachedTransactions));
    } catch (_) {}
  }

  @override
  Future<List<Transaction>> getUserTransactions() async {
    final transactions = await source.getUserTransactions();
    final entities = transactions.map((t) => t.toEntity()).toList();

    _cachedTransactions
      ..clear()
      ..addAll(entities);
    _emitCache();

    return List.unmodifiable(_cachedTransactions);
  }

  @override
  Future<Transaction> createTransaction(TransactionCreate create) async {
    final dto = await source.createTransaction(create);
    final entity = dto.toEntity();

    _cachedTransactions.insert(0, entity);
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    return entity;
  }

  @override
  Future<(Transaction, Transaction)> createTransferTransaction(
    TransferTransactionCreate create,
  ) async {
    final (outgoingDto, incomingDto) = await source.createTransferTransaction(
      create,
    );

    final outgoing = outgoingDto.toEntity();
    final incoming = incomingDto.toEntity();

    _cachedTransactions.insertAll(0, [outgoing, incoming]);
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();

    return (outgoing, incoming);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await source.deleteTransaction(id);

    _cachedTransactions.removeWhere((t) => t.id == id);
    _emitCache();

    // refresh accounts to update balances
    await FinanceAccountService().getUserAccounts();
  }

  @override
  Future<void> deleteTransferTransaction(String transferGroupId) async {
    await source.deleteTransferTransaction(transferGroupId);

    _cachedTransactions.removeWhere(
      (t) => t.transferGroupId == transferGroupId,
    );
    _emitCache();

    // refresh accounts to update balances
    await accountService.getUserAccounts();
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    // try cache first
    final cached = _cachedTransactions.firstWhere(
      (t) => t.id == id,
      orElse:
          () => Transaction(
            id: "",
            amount: "0",
            accountId: "",
            currency: "",
            type: TransactionType.values.first,
            createdAt: DateTime.now(),
            occuredAt: DateTime.now(),
          ),
    );
    if (cached.id.isNotEmpty) return cached;

    final dto = await source.getTransaction(id);
    final entity = dto.toEntity();

    final idx = _cachedTransactions.indexWhere((t) => t.id == entity.id);
    if (idx != -1) {
      _cachedTransactions[idx] = entity;
    } else {
      _cachedTransactions.insert(0, entity);
    }
    _emitCache();

    return entity;
  }

  @override
  Future<Transaction> updateTransaction(
    String id,
    TransactionPatch patch,
  ) async {
    final dto = await source.updateTransaction(id, patch);
    final entity = dto.toEntity();

    final idx = _cachedTransactions.indexWhere((t) => t.id == entity.id);
    if (idx != -1) {
      _cachedTransactions[idx] = entity;
    } else {
      _cachedTransactions.insert(0, entity);
    }
    _emitCache();

    // refresh accounts to update balances
      await accountService.getUserAccounts();

    return entity;
  }

  // close stream when app disposes 
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
