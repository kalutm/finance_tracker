import 'package:equatable/equatable.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class AccountFormEvent extends Equatable {
  const AccountFormEvent();
  @override
  List<Object?> get props => [];
} 

class CreateAccount extends AccountFormEvent {
  final AccountCreate create;
  const CreateAccount(this.create);

  @override
  List<Object?> get props => [create];
} // when a user wants to create a new account

class GetAccount extends AccountFormEvent {
  final String id;
  const GetAccount(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to fetch a single account

class UpdateAccount extends AccountFormEvent {
  final String id;
  final AccountPatch patch;
  const UpdateAccount(this.id, this.patch);

  @override
  List<Object?> get props => [id, patch];
} // when the user wants to modify an account

class DeactivateAccount extends AccountFormEvent {
  final String id;
  const DeactivateAccount(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to soft delete an account 

class RestoreAccount extends AccountFormEvent {
  final String id;
  const RestoreAccount(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to restore the soft deleted accoutn

class DeleteAccount extends AccountFormEvent {
  final String id;
  const DeleteAccount(this.id);

  @override
  List<Object?> get props => [id];
} // when the user wants to hard delete an account 
