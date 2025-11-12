import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
} 

class LoadTransactions extends TransactionsEvent {
  const LoadTransactions();
} // when ever the ui needs to load the current user's transactions (List<Transaction>)

class RefreshTransactions extends TransactionsEvent {
  const RefreshTransactions();
} // when ever the ui needs to refresh the current user's transactions (List<Transaction>)

class TransactionCreatedInForm extends TransactionsEvent {
  final Transaction transaction;
  const TransactionCreatedInForm(this.transaction);

  @override
  List<Object?> get props => [transaction];
} // when a user has created a new transaction in form

class TransferTransactionCreatedInForm extends TransactionsEvent {
  final Transaction outgoing;
  final Transaction incoming;
  const TransferTransactionCreatedInForm(this.outgoing, this.incoming);

  @override
  List<Object?> get props => [outgoing, incoming];
} // when a user has created a new transfer Transaction in form

class TransactionUpdatedInForm extends TransactionsEvent {
  final Transaction transaction;
  const TransactionUpdatedInForm(this.transaction);

  @override
  List<Object?> get props => [transaction];
} // when the user has updated an transaction in form


class TransactionDeletedInForm extends TransactionsEvent {
  final String id;
  const TransactionDeletedInForm(this.id);

  @override
  List<Object?> get props => [id];
} // when the user has deleted a transaction in form 
