class AuthException implements Exception{}

class CouldnotLoadUser implements AuthException{}

class CouldnotGetUser extends AuthException{}

class CouldnotLogInWithGoogle extends AuthException{}

class CouldnotDeleteUser extends AuthException{}

class NoUserToDelete extends AuthException{}

class CouldnotLogIn extends AuthException{
  final String message;
  CouldnotLogIn(this.message);

  @override
  String toString() {
    return message;
  }
}

class CouldnotRegister extends AuthException{
  final String message;
  CouldnotRegister(this.message);

  @override
  String toString() {
    return message;
  }
}

class CouldnotSendEmailVerificatonLink extends AuthException{
  final String message;
  CouldnotSendEmailVerificatonLink(this.message);

  @override
  String toString() {
    return message;
  }
}