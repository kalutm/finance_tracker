import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_operation_type.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class TransactionFormState extends Equatable {
  const TransactionFormState();
  @override
  List<Object?> get props => [];
}

class TransactionFormInitial extends TransactionFormState {
  const TransactionFormInitial();
} // when the transaction form page/sheet is loading before any operation

class TransactionOperationInProgress extends TransactionFormState {
  const TransactionOperationInProgress();
} // when the service is doing any crud operation

class TransactionOperationSuccess extends TransactionFormState {
  final Transaction transaction;
  final TransactionOperationType operationType;
  const TransactionOperationSuccess(this.transaction, this.operationType);

  @override
  List<Object?> get props => [transaction, operationType];
} // when any Create, Read and Update operation on an Transaction has successfully completed

class CreateTransferTransactionOperationSuccess extends TransactionFormState {
  final Transaction outgoing;
  final Transaction incoming;

  const CreateTransferTransactionOperationSuccess(this.incoming, this.outgoing);

  @override
  List<Object?> get props => [incoming, outgoing];
} // when any create Transfer Transaction has successfully completed

class TransactionDeleteOperationSuccess extends TransactionFormState {
  final String id;
  const TransactionDeleteOperationSuccess(this.id);

  @override
  List<Object?> get props => [id];
} // when a delete Operation on an transaction has successfully completed

class TransactionOperationFailure extends TransactionFormState {
  final String message;
  const TransactionOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
} // when any operation has failed
