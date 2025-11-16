import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class AccountsEvent extends Equatable {
  const AccountsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAccounts extends AccountsEvent {
  const LoadAccounts();
} // when ever the ui needs to load the current user's accounts (List<Accounts>)

class RefreshAccounts extends AccountsEvent {
  const RefreshAccounts();
} // when ever the ui needs to refresh the current user's accounts (List<Accounts>)

class AccountsUpdated extends AccountsEvent {
  final List<Account> accounts;
  const AccountsUpdated(this.accounts);

  @override
  List<Object?> get props => [accounts];
} // internal event fired when AccountService stream emits new list
