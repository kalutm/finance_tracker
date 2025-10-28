import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';

abstract class AccountService {
  Future<List<Account>> getUserAccounts();

  Future<Account> createAccount({AccountCreate create});

  Future<Account> getAccount(String id);

  Future<Account> updateAccount({required String id, AccountPatch patch});

  Future<Account> deactivateAccount(String id);

  Future<void> deleteAccount(String id);

  Future<void> restoreAccount(String id);
}
