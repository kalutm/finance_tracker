import 'package:finance_frontend/features/auth/domain/entities/sign_in_account.dart';
import 'package:finance_frontend/features/auth/domain/services/sign_in_with_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService implements SignInWithService {
  final String clientServerId;
  final GoogleSignIn googleSignIn;
  GoogleSignInService({
    required this.clientServerId,
    required this.googleSignIn,
  });
  @override
  Future<SignInAccount> getAccount() async {
    await googleSignIn.initialize(serverClientId: clientServerId);
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    final signInAccount = SignInAccount(
      email: googleUser.email,
      idToken: idToken,
    );

    return signInAccount;
  }
}
