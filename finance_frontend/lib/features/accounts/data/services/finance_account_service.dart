import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_patch.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';

class FinanceAccountService implements AccountService{
  final FinanceSecureStorageService financeSecureStorageService;

  const FinanceAccountService(this.financeSecureStorageService);
  @override
  Future<Account> createAccount(AccountCreate create) {
    // TODO: implement createAccount
    throw UnimplementedError();
  }

  @override
  Future<Account> deactivateAccount(String id) {
    // TODO: implement deactivateAccount
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(String id) {
    // TODO: implement deleteAccount
    throw UnimplementedError();
  }

  @override
  Future<Account> getAccount(String id) {
    // TODO: implement getAccount
    throw UnimplementedError();
  }

  @override
  Future<List<Account>> getUserAccounts() {
    // TODO: implement getUserAccounts
    throw UnimplementedError();
  }

  @override
  Future<Account> restoreAccount(String id) {
    // TODO: implement restoreAccount
    throw UnimplementedError();
  }

  @override
  Future<Account> updateAccount(String id, AccountPatch patch) {
    // TODO: implement updateAccount
    throw UnimplementedError();
  }

}