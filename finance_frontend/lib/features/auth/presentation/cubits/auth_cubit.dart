import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:finance_frontend/features/auth/domain/services/auth_service.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService financeAuthService;
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;

  AuthCubit(this.financeAuthService) : super(AuthInitial());

  Future<void> checkStatus() async {
    try {
      emit(AuthLoading());

      final currentUser = await financeAuthService.getCurrentUser();

      if (currentUser != null){
        _currentUser = currentUser;
        if(currentUser.isVerified){
          emit(Authenticated(currentUser));
        } else{
          if(currentUser.provider.name == "LOCAL" || currentUser.provider.name == "LOCAL_GOOGLE"){
            emit(AuthNeedsVerification(currentUser.email));
          } else{
            emit(Authenticated(currentUser));
          }
        }
      } else {
        emit(Unauthenticated());
      }
      
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());

      final user = await financeAuthService.loginWithEmailAndPassword(email, password);
      _currentUser = user;

      emit(Authenticated(user));
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      emit(AuthLoading());

      final user = await financeAuthService.loginWithGoogle();
      _currentUser = user;

      if(user != null){
        emit(Authenticated(user));
      } else{
        emit(Unauthenticated());
      }
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }

  Future<void> register(String email, String password) async {
    try {
      emit(AuthLoading());

      final user = await financeAuthService.registerWithEmailAndPassword(email, password);
      _currentUser = user;

      emit(AuthNeedsVerification(user.email));
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      emit(AuthLoading());
      final user = _currentUser;

      if(user != null){
        await financeAuthService.sendVerificationEmail(user.email);
        emit(AuthNeedsVerification(user.email));
      } else{
        throw CouldnotSendEmailVerificatonLink("User not found please register before you verify.");
      }
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }

  Future<void> logOut() async {
    emit(AuthLoading());
    final user = _currentUser;

    if(user == null){
      emit(AuthError(Exception("Couldnot logout: no user found")));
      emit(Unauthenticated());
    } else{
      await financeAuthService.logout();
      emit(Unauthenticated());
    }
  }

  Future<void> deleteCurrentUser() async {
    try {
      emit(AuthLoading());
      final user = _currentUser;
      if(user == null){
        throw NoUserToDelete();
      } else {
        await financeAuthService.deleteCurrentUser();
        emit(Unauthenticated());
      }
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }
}