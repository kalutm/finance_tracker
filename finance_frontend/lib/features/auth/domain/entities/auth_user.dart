import 'package:finance_frontend/features/auth/domain/entities/provider_enum.dart';

class AuthUser {
  final String uid;
  final String email;
  final bool isVerified;
  final Provider provider;
  
  const AuthUser({required this.uid, required this.email, this.isVerified = false, required this.provider});
  
  factory AuthUser.fromFinance(Map<String, dynamic> json){
    final userProvider = json["provider"] as String;
    final Provider provider;
  
    switch (userProvider) {
      case "LOCAL":
        provider = Provider.LOCAL;
      case "GOOGLE":
        provider = Provider.GOOGLE;
      case "LOCAL_GOOGLE":
        provider = Provider.LOCAL_GOOGLE;
      default:
        provider = Provider.LOCAL;
      
    }

    return AuthUser(uid: json["id"], email: json["email"], isVerified: json["is_verified"], provider: provider);
  }
  
  Map<String, dynamic> toFinance(AuthUser user){
    return {"id": user.uid, "email": user.email, "is_verified": user.isVerified, "provider": user.provider.name};
  }

}
