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
  // derived fingerprint that changes if any visible account field changes
  final String _fingerprint;

  AccountsLoaded(this.accounts)
      : _fingerprint = _computeFingerprint(accounts);

  static String _computeFingerprint(List<Account> accounts) {
    // include fields that should cause UI updates when changed
    // id + balance + active + name cover most relevant visual changes
    return accounts
        .map((a) => '${a.id}:${a.balance}:${a.active}:${a.name}')
        .join('|');
  }

  @override
  List<Object?> get props => [accounts, _fingerprint];
} // when the service has finished loading the current user's accounts (List<Account>)

class AccountOperationFailure extends AccountsState {
  final List<Account> accounts;
  final String message;
  // ensure fingerprint considered here too
  final String _fingerprint;

  AccountOperationFailure(this.message, this.accounts)
      : _fingerprint = AccountsLoaded._computeFingerprint(accounts);

  @override
  List<Object?> get props => [message, accounts, _fingerprint];
} // when any operation has failed
