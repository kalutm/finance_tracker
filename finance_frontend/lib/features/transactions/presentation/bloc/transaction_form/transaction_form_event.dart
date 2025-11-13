import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_update.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transfer_transaction_create.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class TransactionFormEvent extends Equatable {
  const TransactionFormEvent();
  @override
  List<Object?> get props => [];
}

class CreateTransaction extends TransactionFormEvent {
  final TransactionCreate create;
  const CreateTransaction(this.create);

  @override
  List<Object?> get props => [create];
} // when a user wants to create a new Transaction (Income and Expense)

class CreateTransferTransaction extends TransactionFormEvent {
  final TransferTransactionCreate create;
  const CreateTransferTransaction(this.create);

  @override
  List<Object?> get props => [create];
} // when a user wants to create a new Transaciton (Transfer)

class GetTransaction extends TransactionFormEvent {
  final String id;
  const GetTransaction(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to fetch a single Transaction

class UpdateTransaction extends TransactionFormEvent {
  final String id;
  final TransactionPatch patch;
  const UpdateTransaction(this.id, this.patch);

  @override
  List<Object?> get props => [id, patch];
} // when the user wants to modify an Transaction

class DeleteTransferTransaction extends TransactionFormEvent {
  final String transferGroupId;
  const DeleteTransferTransaction(this.transferGroupId);

  @override
  List<Object?> get props => [transferGroupId];
} // when the user wants to delete a Transfer Transaction

class DeleteTransaction extends TransactionFormEvent {
  final String id;
  const DeleteTransaction(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to hard delete an Transaction
