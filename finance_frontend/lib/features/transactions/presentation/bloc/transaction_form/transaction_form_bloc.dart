import 'dart:io';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_operation_type.dart';
import 'package:finance_frontend/features/transactions/domain/exceptions/transaction_exceptions.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/add_transaction.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/add_transfer_transaction.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/delete_transaction.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/delete_transfer_transaction.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/get_transaction.dart';
import 'package:finance_frontend/features/transactions/domain/use_cases/update_transaction.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_event.dart';
import 'package:finance_frontend/features/transactions/presentation/bloc/transaction_form/transaction_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  final CreateTransactionUc createTransactionUc;
  final CreateTransferTransactionUc createTransferTransactionUc;
  final GetTransactionUc getTransactionUc;
  final UpdateTransactionUc updateTransactionUc;
  final DeleteTransactionUc deleteTransactionUc;
  final DeleteTransferTransactionUc deleteTransferTransactionUc;

  TransactionFormBloc({
    required this.createTransactionUc,
    required this.createTransferTransactionUc,
    required this.getTransactionUc,
    required this.updateTransactionUc,
    required this.deleteTransactionUc,
    required this.deleteTransferTransactionUc,
  }) : super(TransactionFormInitial()) {
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
      final transaction = await createTransactionUc.call(event.create);
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
      final transaction = await getTransactionUc.call(event.id);
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
      final transaction = await updateTransactionUc.call(event.id, event.patch);
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
      final (outgoing, incoming) = await createTransferTransactionUc.call(
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
      await deleteTransferTransactionUc.call(event.transferGroupId);
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
      await deleteTransactionUc.call(event.id);
      emit(TransactionDeleteOperationSuccess(event.id));
    } catch (e) {
      emit(TransactionOperationFailure(_mapErrorToMessage(e)));
    }
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotCreateTransaction) return 'Couldnot create transaction, please try again later';
    if (e is AccountBalanceTnsufficient) return 'Account balance insufficient, please recharge your account before expending';
    if (e is InvalidInputtedAmount) return 'Invalid Amount, please enter a value greater than Zero';
    if (e is CouldnotCreateTransferTransaction) return 'Couldnot create a the transfer transaction, please try again later';
    if (e is CouldnotGetTransaction) return 'Couldnot get transaction or Transaction not found';
    if (e is CouldnotUpdateTransaction) return 'Couldnot Update transaction or Transaction not found, please try again';
    if (e is CannotUpdateTransferTransactions) return "Can't Update a Transfer Transaction";
    if (e is CouldnotDeleteTransaction) return 'Couldnot Delete transaction or Transaction not found, please try again';
    if (e is InvalidTransferTransaction) return 'The transaction is invalid, Couldnot delete it';
    if (e is CouldnotDeleteTransferTransaction) return 'Couldnot Delete the transfer transaction, please try again later';
    if (e is SocketException) return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
  }
}
