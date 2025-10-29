import 'package:finance_frontend/features/accounts/data/services/finance_account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_event.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/account_form/account_form_state.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/entities/operation_type_enum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountFormBloc extends Bloc<AccountFormEvent, AccountFormState> {
  final FinanceAccountService service;

  AccountFormBloc(this.service) : super(AccountFormInitial()) {
    on<CreateAccount>(_onCreate);
    on<GetAccount>(_onGet);
    on<UpdateAccount>(_onUpdate);
    on<DeactivateAccount>(_onDeactivate);
    on<RestoreAccount>(_onRestore);
    on<DeleteAccount>(_onDelete);

  }

  Future<void> _onCreate(
    CreateAccount event,
    Emitter<AccountFormState> emit,
  ) async {
    try {
      emit(AccountOperationInProgress());
      final account = await service.createAccount(event.create);
      emit(AccountOperationSuccess(account, AccountOperationType.create));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onGet(
    GetAccount event,
    Emitter<AccountFormState> emit,
  ) async {
    try {
      emit(AccountOperationInProgress());
      final account = await service.getAccount(event.id);
      emit(AccountOperationSuccess(account, AccountOperationType.read));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onUpdate(
    UpdateAccount event,
    Emitter<AccountFormState> emit,
  ) async {
    try {
      emit(AccountOperationInProgress());
      final account = await service.updateAccount(event.id, event.patch);
      emit(AccountOperationSuccess(account, AccountOperationType.update));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onDeactivate(
    DeactivateAccount event,
    Emitter<AccountFormState> emit,
  ) async {
    try {
      emit(AccountOperationInProgress());
      final account = await service.deactivateAccount(event.id);
      emit(AccountOperationSuccess(account, AccountOperationType.deactivate));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onRestore(
    RestoreAccount event,
    Emitter<AccountFormState> emit,
  ) async {
    try {
      emit(AccountOperationInProgress());
      final account = await service.restoreAccount(event.id);
      emit(AccountOperationSuccess(account, AccountOperationType.restore));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e)));
    }
  }

  Future<void> _onDelete(
    DeleteAccount event,
    Emitter<AccountFormState> emit,
  ) async {
    try {
      emit(AccountOperationInProgress());
      await service.deleteAccount(event.id);
      emit(AccountDeleteOperationSuccess(event.id));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e)));
    }
  }

  String _mapErrorToMessage(Object e) {
    // TODO: map different exception types to friendly messages or use a Failure class.
    // Example:
    // if (e is NetworkException) return 'No internet connection';
    // if (e is UnauthorizedException) return 'Session expired';
    return e.toString();
  }
}

