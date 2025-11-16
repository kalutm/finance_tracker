import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_event.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transactions/transactions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionService transactionService;
  StreamSubscription<List<Transaction>>? _txSub;

  List<Transaction> _cachedTransactions = [];

  TransactionsBloc(this.transactionService) : super(const TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions, transformer: droppable());
    on<RefreshTransactions>(_onRefreshTransactions, transformer: droppable());
    on<TransactionsUpdated>(_onTransactionsUpdated);
    on<TransactionFilterChanged>(_onTransactionFilterChanged);

    // subscribe to service stream
    _txSub = transactionService.transactionsStream.listen(
      (txs) => add(TransactionsUpdated(txs)),
      onError: (err, st) {
        developer.log('TransactionService stream error', error: err, stackTrace: st);
      },
    );

    add(const LoadTransactions());
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());
    try {
      final transactions = await transactionService.getUserTransactions();
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
      final transactions = await transactionService.getUserTransactions();
      _cachedTransactions = transactions;
      _emitFilteredTransactionsLoaded(emit, prevState);
    } catch (e, st) {
      developer.log('LoadTransactions error', error: e, stackTrace: st);
      _emitFilteredTransactionOperationFailure(emit, prevState, e);
    }
  }

  Future<void> _onTransactionsUpdated(
    TransactionsUpdated event,
    Emitter<TransactionsState> emit,
  ) async {
    _cachedTransactions = event.transactions;

    // preserve any existing filter from current state
    final prevState = state;
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

  @override
  Future<void> close() {
    _txSub?.cancel();
    return super.close();
  }
}
