import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
} // when the transaction(home) page is loading before any operation

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
} // when the service is loading current user's transactions (List<Transaction>)

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> transactions;
  const TransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
} // when the service has finished loading the current user's transactions (List<Transaction>)

class TransactionOperationFailure extends TransactionsState {
  final List<Transaction> transactions;
  final String message;
  const TransactionOperationFailure(this.message, this.transactions);

  @override
  List<Object?> get props => [message];
} // when any operation has failed
