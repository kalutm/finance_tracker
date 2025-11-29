import 'dart:convert';
import 'package:finance_frontend/core/network/network_client.dart';
import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:finance_frontend/features/auth/domain/services/auth_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/categories/domain/service/category_service.dart';
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer' as dev_tool show log;

class FinanceAuthService implements AuthService {
  final SecureStorageService secureStorageService;
  final NetworkClient client;
  final AccountService accountService;
  final CategoryService categoryService;
  final TransactionService transactionService;
  final String baseUrl;

  FinanceAuthService({
    required this.secureStorageService,
    required this.client,
    required this.accountService,
    required this.categoryService,
    required this.transactionService,
    required this.baseUrl,
  });

  get authBaseUrl  => "$baseUrl/auth";
  final clientServerId = dotenv.env["GOOGLE_SERVER_CLIENT_ID_WEB"]!;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  bool isExpired(String token) => JwtDecoder.isExpired(token);

  @override
  Future<AuthUser?> getCurrentUser() async {
    String? accessToken = await secureStorageService.readString(
      key: "access_token",
    );
    String? refreshToken = await secureStorageService.readString(
      key: "refresh_token",
    );

    if (accessToken != null) {
      // check if access token is expired or not
      if (isExpired(accessToken)) {
        // access token expired -> check if refresh token is not null
        if (refreshToken != null) {
          // we have refresh token -> check if refresh token is not expired
          if (!isExpired(refreshToken)) {
            // refresh token is not expired -> try to get access token with it
            try {
              final req = RequestModel(
                method: 'POST',
                url: Uri.parse("$authBaseUrl/refresh"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"token": refreshToken}),
              );

              final res = await client.send(req);

              final json = _decode(res.body);
              if (res.statusCode != 200) {
                dev_tool.log("EERROORR, EERROORR: ${json["detail"]}");
                throw CouldnotLoadUser();
              }

              final newAccess = json["acc_jwt"] as String;
              await secureStorageService.saveString(
                key: "access_token",
                value: newAccess,
              );

              return await getUserCridentials(newAccess);
            } on AuthException {
              rethrow;
            }
          }
          // refresh token expired -> delete both tokens and return null -> user have to log in again
          await secureStorageService.deleteAll();
          return null;
        }
        // refresh token null -> delete access token and return null -> user have to log in again
        await secureStorageService.deleteString(key: "access_token");
        return null;
      }
      // access token not expired -> request the user from backend then return it
      try {
        return await getUserCridentials(accessToken);
      } on AuthException {
        rethrow;
      }
    }
    // No tokens stored → return null -> user must log in again
    return null;
  }

  @override
  Future<AuthUser> getUserCridentials(String accessToken) async {
    try {
      final req = RequestModel(
        method: 'GET',
        url: Uri.parse("$authBaseUrl/me"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      final resp = await client.send(req);

      final resBody = _decode(resp.body);
      if (resp.statusCode != 200) {
        dev_tool.log("EERROORR, EERROORR: ${resBody["detail"]}");
        throw CouldnotGetUser();
      }

      final currentUser = AuthUser.fromFinance(resBody);
      return currentUser;
    } on AuthException {
      rethrow;
    }
  }

  @override
  Future<AuthUser> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final req = RequestModel(
        method: 'POST',
        url: Uri.parse("$authBaseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final res = await client.send(req);

      final json = _decode(res.body);
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotLogIn(errorDetail);
      }

      // request successful -> save tokens in secure storage
      final accessToken = json["acc_jwt"] as String;
      final refreshToken = json["ref_jwt"] as String;

      await secureStorageService.saveString(
        key: "access_token",
        value: accessToken,
      );
      await secureStorageService.saveString(
        key: "refresh_token",
        value: refreshToken,
      );

      return await getUserCridentials(accessToken);
    } on AuthException {
      rethrow;
    }
  }

  @override
  Future<AuthUser?> loginWithGoogle() async {
    try {
      await _googleSignIn.initialize(serverClientId: clientServerId);
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw CouldnotLogInWithGoogle();
      }

      final req = RequestModel(
        method: 'POST',
        url: Uri.parse("$authBaseUrl/login/google"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'id_token': idToken}),
      );

      final response = await client.send(req);

      final json = _decode(response.body);
      if (response.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotLogInWithGoogle();
      }
      // request successful -> save token's in secure storage
      // then request user from back end and return it
      final accessToken = json["acc_jwt"] as String;
      final refreshToken = json["ref_jwt"] as String;

      await secureStorageService.saveString(
        key: "access_token",
        value: accessToken,
      );
      await secureStorageService.saveString(
        key: "refresh_token",
        value: refreshToken,
      );

      return await getUserCridentials(accessToken);
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        throw Exception("Login with Google Failed: $e");
      }
      return null;
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final req = RequestModel(
        method: 'POST',
        url: Uri.parse("$authBaseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final res = await client.send(req);

      final json = _decode(res.body);
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotRegister(errorDetail);
      }

      // request successful -> save tokens in secure storage
      final accessToken = json["acc_jwt"] as String;
      final refreshToken = json["ref_jwt"] as String;

      await secureStorageService.saveString(
        key: "access_token",
        value: accessToken,
      );
      await secureStorageService.saveString(
        key: "refresh_token",
        value: refreshToken,
      );

      return await getUserCridentials(accessToken);
    } on AuthException {
      rethrow;
    }
  }

  @override
  Future<void> sendVerificationEmail(String email) async {
    try {
      final req = RequestModel(
        method: 'POST',
        url: Uri.parse("$authBaseUrl/resend-verification"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final res = await client.send(req);

      final json = _decode(res.body);
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotSendEmailVerificatonLink(errorDetail);
      }
    } on AuthException {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    // clear the current user's cache data's
    await accountService.clearCache();
    await categoryService.clearCache();
    await transactionService.clearCache();
    // delete token's
    await secureStorageService.deleteAll();
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      final accessToken = await secureStorageService.readString(
        key: "access_token",
      );
      if (accessToken == null) {
        throw NoUserToDelete();
      }

      final req = RequestModel(
        method: 'DELETE',
        url: Uri.parse("$authBaseUrl/me"),
        headers: {"Authorization": "Bearer $accessToken"},
      );

      final res = await client.send(req);

      final json = _decode(res.body);
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotDeleteUser();
      }

      await secureStorageService.deleteAll();
    } on AuthException {
      rethrow;
    }
  }
}
