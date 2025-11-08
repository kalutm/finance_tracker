import 'dart:developer' as developer;
import 'dart:io';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/exceptions/account_exceptions.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_event.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/accounts/accounts_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountService accountService;

  List<Account> _cachedAccounts = [];

  AccountsBloc(this.accountService) : super(const AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts, transformer: droppable());
    on<RefreshAccounts>(_onRefreshAccounts, transformer: droppable());
    on<AccountCreatedInForm>(_onCreatedAccount);
    on<AccountUpdatedInForm>(_onUpdatedAccount);
    on<AccountDeactivatedInForm>(_onDeactivatedAccount);
    on<AccountRestoredInForm>(_onRestoredAccount);
    on<AccountDeletedInForm>(_onDeletedAccount);

    add(LoadAccounts());
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(const AccountsLoading());
    try {
      final accounts = await accountService.getUserAccounts();
      _cachedAccounts = accounts;
      emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e), _cachedAccounts));
    }
  }

  Future<void> _onRefreshAccounts(
    RefreshAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
    try {
      final accounts = await accountService.getUserAccounts();
      _cachedAccounts = accounts;
      emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
    } catch (e, st) {
      developer.log('LoadAccounts error', error: e, stackTrace: st);
      emit(AccountOperationFailure(_mapErrorToMessage(e), _cachedAccounts));
    }
  }

  Future<void> _onCreatedAccount(
    AccountCreatedInForm event,
    Emitter<AccountsState> emit,
  ) async {
    final updated = List<Account>.from(_cachedAccounts);
    updated.insert(0, event.account);
    _cachedAccounts = updated;
    emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
  }

  Future<void> _onUpdatedAccount(
    AccountUpdatedInForm event,
    Emitter<AccountsState> emit,
  ) async {
    final index = _cachedAccounts.indexWhere((a) => a.id == event.account.id);
    if (index != -1) {
      final updated = List<Account>.from(_cachedAccounts);
      updated[index] = event.account;
      _cachedAccounts = updated;
      emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
    }
  }

  Future<void> _onDeactivatedAccount(
    AccountDeactivatedInForm event,
    Emitter<AccountsState> emit,
  ) async {
    final index = _cachedAccounts.indexWhere((a) => a.id == event.account.id);
    if (index != -1) {
      final updated = List<Account>.from(_cachedAccounts);
      updated[index] = event.account;
      _cachedAccounts = updated;
      emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
    }
  }

  Future<void> _onRestoredAccount(
    AccountRestoredInForm event,
    Emitter<AccountsState> emit,
  ) async {
    final index = _cachedAccounts.indexWhere((a) => a.id == event.account.id);
    if (index != -1) {
      final updated = List<Account>.from(_cachedAccounts);
      updated[index] = event.account;
      _cachedAccounts = updated;
      emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
    }
  }

  Future<void> _onDeletedAccount(
    AccountDeletedInForm event,
    Emitter<AccountsState> emit,
  ) async {
    final updated = List<Account>.from(_cachedAccounts);
    updated.removeWhere((a) => a.id == event.id);
    _cachedAccounts = updated;
    emit(AccountsLoaded(List.unmodifiable(_cachedAccounts)));
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotFetchAccounts) return 'Couldnot fetch accounts, please try reloading the page';
    if(e is SocketException) return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
    
  }
}
