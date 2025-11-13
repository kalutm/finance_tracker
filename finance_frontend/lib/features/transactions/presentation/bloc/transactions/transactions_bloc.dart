import 'dart:developer' as developer;
import 'dart:io';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/get_transactions.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_event.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final GetTransactionsUc getTransactionsUc;

  List<Transaction> _cachedTransactions = [];

  TransactionsBloc(this.getTransactionsUc)
    : super(const TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions, transformer: droppable());
    on<RefreshTransactions>(_onRefreshTransactions, transformer: droppable());
    on<TransactionCreatedInForm>(_onCreatedTransaction);
    on<TransferTransactionCreatedInForm>(_onTransferTransactionCreated);
    on<TransactionUpdatedInForm>(_onUpdatedTransaction);
    on<TransferTransactionDeletedInForm>(_onTransferTransactionDeleted);
    on<TransactionDeletedInForm>(_onDeletedTransaction);
    on<TransactionFilterChanged>(_onTransactionFilterChanged);

    add(LoadTransactions());
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());
    try {
      final transactions = await getTransactionsUc.call();
      _cachedTransactions = transactions;
      emit(TransactionsLoaded(List.unmodifiable(_cachedTransactions)));
    } catch (e) {
      emit(
        TransactionOperationFailure(
          transactions: _cachedTransactions,
          message: _mapErrorToMessage(e),
        ),
      );
    }
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final prevState = state;
    emit(const TransactionsLoading());
    try {
      final transactions = await getTransactionsUc.call();
      _cachedTransactions = transactions;

      _emitFilteredTransactionsLoaded(emit, prevState);
    } catch (e, st) {
      developer.log('LoadTransactions error', error: e, stackTrace: st);
      _emitFilteredTransactionOperationFailure(emit, prevState, e);
    }
  }

  Future<void> _onCreatedTransaction(
    TransactionCreatedInForm event,
    Emitter<TransactionsState> emit,
  ) async {
    final prevState = state;

    final updated = List<Transaction>.from(_cachedTransactions);
    updated.insert(0, event.transaction);
    _cachedTransactions = updated;

    _emitFilteredTransactionsLoaded(emit, prevState);
  }

  Future<void> _onUpdatedTransaction(
    TransactionUpdatedInForm event,
    Emitter<TransactionsState> emit,
  ) async {
    final prevState = state;

    final index = _cachedTransactions.indexWhere(
      (txn) => txn.id == event.transaction.id,
    );
    if (index != -1) {
      final updated = List<Transaction>.from(_cachedTransactions);
      updated[index] = event.transaction;
      _cachedTransactions = updated;

      _emitFilteredTransactionsLoaded(emit, prevState);
    }
  }

  Future<void> _onTransferTransactionDeleted(
    TransferTransactionDeletedInForm event,
    Emitter<TransactionsState> emit,
  ) async {
    final prevState = state;

    final updated = List<Transaction>.from(_cachedTransactions);
    updated.removeWhere((txn) => txn.transferGroupId == event.transferGroupId);
    _cachedTransactions = updated;

    _emitFilteredTransactionsLoaded(emit, prevState);
  }

  Future<void> _onTransferTransactionCreated(
    TransferTransactionCreatedInForm event,
    Emitter<TransactionsState> emit,
  ) async {
    final prevState = state;

    final updated = List<Transaction>.from(_cachedTransactions);
    updated.insert(0, event.incoming);
    updated.insert(0, event.outgoing);
    _cachedTransactions = updated;

    _emitFilteredTransactionsLoaded(emit, prevState);
  }

  Future<void> _onDeletedTransaction(
    TransactionDeletedInForm event,
    Emitter<TransactionsState> emit,
  ) async {
    final prevState = state;

    final updated = List<Transaction>.from(_cachedTransactions);
    updated.removeWhere((txn) => txn.id == event.id);
    _cachedTransactions = updated;

    _emitFilteredTransactionsLoaded(emit, prevState);
  }

  Future<void> _onTransactionFilterChanged(
    TransactionFilterChanged event,
    Emitter<TransactionsState> emit,
  ) async {
    final account = event.account;
    if (account != null) {
      final filtered = List<Transaction>.from(_cachedTransactions);
      emit(
        TransactionsLoaded(
          List.unmodifiable(
            filtered.where((txn) => txn.accountId == account.id),
          ),
          account,
        ),
      );
    } else {
      emit(TransactionsLoaded(List.unmodifiable(_cachedTransactions)));
    }
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotFetchTransactions) return 'Couldnot fetch transactions, please try reloading the page';
    if (e is SocketException) return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
  }

  _emitFilteredTransactionsLoaded(
    Emitter<TransactionsState> emit,
    TransactionsState prevState,
  ) {
    if (prevState is TransactionsLoaded) {
      final account = prevState.account;
      if (account != null) {
        final accountId = account.id;
        final filtered = List<Transaction>.from(_cachedTransactions);
        emit(
          TransactionsLoaded(
            List.unmodifiable(
              filtered.where(
                (transaction) => transaction.accountId == accountId,
              ),
            ),
            account,
          ),
        );
      } else {
        emit(TransactionsLoaded(List.unmodifiable(_cachedTransactions)));
      }
    } else if (prevState is TransactionOperationFailure) {
      final account = prevState.account;
      if (account != null) {
        final accountId = account.id;
        final filtered = List<Transaction>.from(_cachedTransactions);
        emit(
          TransactionsLoaded(
            List.unmodifiable(
              filtered.where(
                (transaction) => transaction.accountId == accountId,
              ),
            ),
            account,
          ),
        );
      } else {
        emit(TransactionsLoaded(List.unmodifiable(_cachedTransactions)));
      }
    } else {
      emit(TransactionsLoaded(List.unmodifiable(_cachedTransactions)));
    }
  }

  _emitFilteredTransactionOperationFailure(
    Emitter<TransactionsState> emit,
    TransactionsState prevState,
    Object e,
  ) {
    if (prevState is TransactionsLoaded) {
      final account = prevState.account;
      if (account != null) {
        final accountId = account.id;
        final filtered = List<Transaction>.from(_cachedTransactions);
        emit(
          TransactionOperationFailure(
            transactions: List.unmodifiable(
              filtered.where(
                (transaction) => transaction.accountId == accountId,
              ),
            ),
            account: account,
            message: _mapErrorToMessage(e),
          ),
        );
      } else {
        emit(
          TransactionOperationFailure(
            transactions: List.unmodifiable(_cachedTransactions),
            message: _mapErrorToMessage(e),
          ),
        );
      }
    } else if (prevState is TransactionOperationFailure) {
      final account = prevState.account;
      if (account != null) {
        final accountId = account.id;
        final filtered = List<Transaction>.from(_cachedTransactions);
        emit(
          TransactionOperationFailure(
            transactions: List.unmodifiable(
              filtered.where(
                (transaction) => transaction.accountId == accountId,
              ),
            ),
            account: account,
            message: _mapErrorToMessage(e),
          ),
        );
      } else {
        emit(
          TransactionOperationFailure(
            transactions: List.unmodifiable(_cachedTransactions),
            message: _mapErrorToMessage(e),
          ),
        );
      }
    } else {
      emit(
        TransactionOperationFailure(
          transactions: List.unmodifiable(_cachedTransactions),
          message: _mapErrorToMessage(e),
        ),
      );
    }
  }
}
