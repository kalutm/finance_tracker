import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:finance_frontend/features/auth/domain/services/auth_service.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService financeAuthService;
  AuthCubit(this.financeAuthService) : super(AuthInitial());

  Future<void> checkStatus() async {
    try {
      emit(AuthLoading());

      final currentUser = await financeAuthService.getCurrentUser();

      if (currentUser != null){
        if(currentUser.isVerified){
          emit(Authenticated(currentUser));
        } else{
          emit(AuthNeedsVerification());
        }
      } else {
        emit(Unauthenticated());
      }
      
    } on Exception catch (e) {
      emit(AuthError(e));
      emit(Unauthenticated());
    }
  }
}