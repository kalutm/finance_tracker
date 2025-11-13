import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
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
  final Account? account;
  final List<Transaction> transactions;
  const TransactionsLoaded(this.transactions, [this.account]);

  @override
  List<Object?> get props => [transactions, account];
} // when the service has finished loading the current user's transactions (List<Transaction>)

class TransactionOperationFailure extends TransactionsState {
  final List<Transaction> transactions;
  final String message;
  final Account? account;
  const TransactionOperationFailure({required this.message, required this.transactions, this.account});

  @override
  List<Object?> get props => [message, transactions, account];
} // when any operation has failed
