import 'dart:async';
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
  StreamSubscription<List<Account>>? _accountsSub;

  AccountsBloc(this.accountService) : super(const AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts, transformer: droppable());
    on<RefreshAccounts>(_onRefreshAccounts, transformer: droppable());
    on<AccountsUpdated>(_onAccountsUpdated);

    // subscribe to service stream and forward to internal event
    _accountsSub = accountService.accountsStream.listen(
      (accounts) => add(AccountsUpdated(accounts)),
      onError: (err, st) {
        // we could map the error to a state if needed
        developer.log('AccountService stream error', error: err, stackTrace: st);
      },
    );

    // triggering initial load
    add(const LoadAccounts());
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(const AccountsLoading());
    try {
      final accounts = await accountService.getUserAccounts();
      emit(AccountsLoaded(List.unmodifiable(accounts)));
    } catch (e) {
      emit(AccountOperationFailure(_mapErrorToMessage(e), const []));
    }
  }

  Future<void> _onRefreshAccounts(
    RefreshAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    // keeping last known UI state while refreshing
    final currentAccounts = state is AccountsLoaded ? (state as AccountsLoaded).accounts : const [] as List<Account>;
    emit(AccountsLoaded(List.unmodifiable(currentAccounts)));
    try {
      final accounts = await accountService.getUserAccounts();
      emit(AccountsLoaded(List.unmodifiable(accounts)));
    } catch (e, st) {
      developer.log('LoadAccounts error', error: e, stackTrace: st);
      emit(AccountOperationFailure(_mapErrorToMessage(e), currentAccounts));
    }
  }

  Future<void> _onAccountsUpdated(
    AccountsUpdated event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoaded(List.unmodifiable(event.accounts)));
  }

  @override
  Future<void> close() {
    _accountsSub?.cancel();
    return super.close();
  }

  String _mapErrorToMessage(Object e) {
    if (e is CouldnotFetchAccounts) return 'Couldnot fetch accounts, please try reloading the page';
    if (e is SocketException) return 'No Internet connection!, please try connecting to the internet';
    return e.toString();
  }
}
