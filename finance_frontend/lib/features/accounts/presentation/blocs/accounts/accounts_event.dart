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

class AccountCreatedInForm extends AccountsEvent {
  final Account account;
  const AccountCreatedInForm(this.account);

  @override
  List<Object?> get props => [account];
} // when a user has created a new account in form

class AccountUpdatedInForm extends AccountsEvent {
  final Account account;
  const AccountUpdatedInForm(this.account);

  @override
  List<Object?> get props => [account];
} // when the has updated an account in form

class AccountDeactivatedInForm extends AccountsEvent {
  final Account account;
  const AccountDeactivatedInForm(this.account);

  @override
  List<Object?> get props => [account];
} // when the user has soft deleted an account in form

class AccountRestoredInForm extends AccountsEvent {
  final Account account;
  const AccountRestoredInForm(this.account);

  @override
  List<Object?> get props => [account];
} // when the user has restored an account in form

class AccountDeletedInForm extends AccountsEvent {
  final String id;
  const AccountDeletedInForm(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to hard delete an account 
