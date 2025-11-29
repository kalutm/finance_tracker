import 'package:finance_frontend/features/auth/domain/entities/provider_enum.dart';

Map<String, dynamic> fakeAuthUserJson({
  required String uid,
  String email = "test@finance.com",
  Provider provider = Provider.LOCAL,
  bool isVerified = true,
}) {
  return {
    'id': uid,
    'email': email,
    'provider': provider.name,
    'is_verified': isVerified,
  };
}
