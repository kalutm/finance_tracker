import 'dart:io';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_operation_type.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_event.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  final TransactionService service;

  TransactionFormBloc(this.service) : super(TransactionFormInitial()) {
    on<CreateTransaction>(_onCreate);
    on<CreateTransferTransaction>(_onCreateTransfer);
    on<GetTransaction>(_onGet);
    on<UpdateTransaction>(_onUpdate);
    on<DeleteTransferTransaction>(_onDeleteTransfer);
    on<DeleteTransaction>(_onDelete);
  }

  Future<void> _onCreate(
    CreateTransaction event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      emit(TransactionOperationInProgress());
      final transaction = await service.createTransaction(event.create);
      emit(
        TransactionOperationSuccess(
          transaction,
          TransactionOperationType.create,
        ),
      );
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onGet(
    GetTransaction event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      emit(TransactionOperationInProgress());
      final transaction = await service.getTransaction(event.id);
      emit(
        TransactionOperationSuccess(transaction, TransactionOperationType.read),
      );
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onUpdate(
    UpdateTransaction event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      emit(TransactionOperationInProgress());
      final transaction = await service.updateTransaction(
        event.id,
        event.patch,
      );
      emit(
        TransactionOperationSuccess(
          transaction,
          TransactionOperationType.update,
        ),
      );
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onCreateTransfer(
    CreateTransferTransaction event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      emit(TransactionOperationInProgress());
      final (outgoing, incoming) = await service.createTransferTransaction(
        event.create,
      );
      emit(CreateTransferTransactionOperationSuccess(outgoing, incoming));
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onDeleteTransfer(
    DeleteTransferTransaction event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      emit(TransactionOperationInProgress());
      await service.deleteTransferTransaction(event.transferGroupId);
      emit(TransferTransactionDeleteOperationSuccess(event.transferGroupId));
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onDelete(
    DeleteTransaction event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      emit(TransactionOperationInProgress());
      await service.deleteTransaction(event.id);
      emit(TransactionDeleteOperationSuccess(event.id));
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotCreateTransaction)
      return 'Couldnot create transaction, please try again later';
    if (e is AccountBalanceTnsufficient)
      return 'Account balance insufficient, please recharge your account before expending';
    if (e is InvalidInputtedAmount)
      return 'Invalid Amount, please enter a value greater than Zero';
    if (e is CouldnotCreateTransferTransaction)
      return 'Couldnot create a the transfer transaction, please try again later';
    if (e is CouldnotGetTransaction)
      return 'Couldnot get transaction or Transaction not found';
    if (e is CouldnotUpdateTransaction)
      return 'Couldnot Update transaction or Transaction not found, please try again';
    if (e is CannotUpdateTransferTransactions)
      return "Can't Update a Transfer Transaction";
    if (e is CouldnotDeleteTransaction)
      return 'Couldnot Delete transaction or Transaction not found, please try again';
    if (e is InvalidTransferTransaction)
      return 'The transaction is invalid, Couldnot delete it';
    if (e is CouldnotDeleteTransferTransaction)
      return 'Couldnot Delete the transfer transaction, please try again later';
    if (e is SocketException)
      return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
  }
}
