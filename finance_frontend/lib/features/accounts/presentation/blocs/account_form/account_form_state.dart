import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/presentation/blocs/entities/operation_type_enum.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class AccountFormState extends Equatable {
  const AccountFormState();
  @override
  List<Object?> get props => [];
}


class AccountFormInitial extends AccountFormState {
  const AccountFormInitial();
} // when the account form page is loading before any operation

class AccountOperationInProgress extends AccountFormState {
  const AccountOperationInProgress();
} // when the service is doing any crud operation

class AccountOperationSuccess extends AccountFormState{
  final Account account;
  final AccountOperationType operationType;
  const AccountOperationSuccess(this.account, this.operationType);

  @override
  List<Object?> get props => [account, operationType];
} // when any Create, Read and Update operation on an Account has successfully completed

class AccountDeleteOperationSuccess extends AccountFormState{
  final String id;
  const AccountDeleteOperationSuccess(this.id);

  @override
  List<Object?> get props => [id];
} // when a delete Operation on an account has successfully completed

class AccountOperationFailure extends AccountFormState {
  final String message;
  const AccountOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
} // when any operation has failed
