import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AuthUser user;
  Authenticated(this.user);
}

class AuthNeedsVerification extends AuthState {
  final String email;
  AuthNeedsVerification(this.email);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final Exception exception;
  AuthError(this.exception);
}