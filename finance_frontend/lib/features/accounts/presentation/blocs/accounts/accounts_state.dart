import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class AccountsState extends Equatable {
  const AccountsState();
  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {
  const AccountsInitial();
} // when the accounts page is loading before any operation

class AccountsLoading extends AccountsState {
  const AccountsLoading();
} // when the service is loading current user's accounts (List<Account>)

class AccountsLoaded extends AccountsState {
  final List<Account> accounts;
  const AccountsLoaded(this.accounts);

  @override
  List<Object?> get props => [accounts];
} // when the service has finished loading the current user's accounts (List<Account>)

class AccountOperationFailure extends AccountsState {
  final String message;
  const AccountOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
} // when any operation has failed
