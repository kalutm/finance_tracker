import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';

abstract class AuthService {
  // get the user who is logged in on the device if any
  Future<AuthUser?> getCurrentUser();

  // get user cridentials from backend using access token
  Future<AuthUser> getUserCridentials(String accessToken);

  Future<AuthUser> loginWithEmailAndPassword(String email, String password);

  Future<AuthUser?> loginWithGoogle();

  Future<AuthUser> registerWithEmailAndPassword(String email, String password);

  Future<void> sendVerificationEmail(String email);

  Future<void> deleteCurrentUser();

  Future<void> logout();
}
