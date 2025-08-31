import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';

abstract class AuthService {
  Future<AuthUser?> getCurrentUser();
  Future<AuthUser?> loginWithEmailAndPassword(String email, String password);
  Future<AuthUser?> loginWithGoogle(String email);
  Future<AuthUser?> registerWithEmailAndPassword(String email, String password);
  Future<void> sendVerificationEmail(String email);
  Future<void> deleteCurrentUser(String token);
  Future<void> logout();
}