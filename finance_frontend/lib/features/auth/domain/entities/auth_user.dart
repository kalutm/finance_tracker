import 'package:finance_frontend/features/auth/domain/entities/provider_enum.dart';

class AuthUser {
  final String uid;
  final String email;
  final bool isVerified;
  final Provider provider;

  const AuthUser({
    required this.uid,
    required this.email,
    this.isVerified = false,
    required this.provider,
  });

  factory AuthUser.fromFinance(Map<String, dynamic> json) {
    return AuthUser(
      uid: json["id"],
      email: json["email"],
      isVerified: json["is_verified"],
      provider: Provider.values.byName(json["provider"] as String),
    );
  }

  Map<String, dynamic> toFinance(AuthUser user) {
    return {
      "id": user.uid,
      "email": user.email,
      "is_verified": user.isVerified,
      "provider": user.provider.name,
    };
  }
}
