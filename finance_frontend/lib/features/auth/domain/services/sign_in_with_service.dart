import 'package:finance_frontend/features/auth/domain/entities/sign_in_account.dart';

abstract class SignInWithService {
  Future<SignInAccount> getAccount();
}