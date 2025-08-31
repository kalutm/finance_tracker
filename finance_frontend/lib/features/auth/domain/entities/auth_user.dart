class AuthUser {
  String uid;
  String email;
  bool isVerified;
  
  AuthUser({required this.uid, required this.email, this.isVerified = false});
  
  factory AuthUser.fromFinance(Map<String, dynamic> json){
    return AuthUser(uid: json["id"], email: json["email"], isVerified: json["is_verified"]);
  }
  
  Map<String, dynamic> toFinance(AuthUser user){
    return {"id": user.uid, "email": user.email, "is_verified": user.isVerified};
  }

}
