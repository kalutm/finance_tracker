import 'dart:convert';
import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:finance_frontend/features/auth/domain/services/auth_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer' as dev_tool show log;

class FinanceAuthService implements AuthService {
  final SecureStorageService secureStorageService;

  FinanceAuthService(this.secureStorageService);

  final baseUrl = "${dotenv.env["API_BASE_URL_MOBILE"]}/auth";
  final clientServerId = dotenv.env["GOOGLE_SERVER_CLIENT_ID_WEB"]!;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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
      if (JwtDecoder.isExpired(accessToken)) {
        // access token expired -> check if refresh token is not null
        if (refreshToken != null) {
          // we have refresh token -> check if refresh token is not expired
          if (!JwtDecoder.isExpired(refreshToken)) {
            // refresh token is not expired -> try to get access token with it
            try {
              final res = await http.post(
                Uri.parse("$baseUrl/refresh"),
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode({"refresh_token": refreshToken}),
              );
              
              final json = jsonDecode(res.body) as Map<String, dynamic>;
              if (res.statusCode != 200) {
                dev_tool.log(
                  "EERROORR, EERROORR: ${json["detail"]}",
                );
                throw CouldnotLoadUser();
              }

              final newAccess = json["acc_jwt"] as String;
              await secureStorageService.saveString(
                key: "access_token",
                value: newAccess,
              );

              return await _getUserCridentials(newAccess);

            } on AuthException catch (_) {
              rethrow;
            } catch (e) {
              throw Exception("Could not Load user: $e");
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
        return await _getUserCridentials(accessToken);
      } on AuthException catch(_){
        rethrow;
      } catch(e){
        throw Exception("Couldnot Load user: $e");
      }
      
    }
    // No tokens stored → return null -> user must log in again
    return null;
  }

  @override
  Future<AuthUser> _getUserCridentials(String accessToken) async {
    try {
        final resp = await http.get(
          Uri.parse("$baseUrl/me"),
          headers: {
            "Authorization": "Bearer $accessToken",
          },
        );

        final resBody = jsonDecode(resp.body) as Map<String, dynamic>;
        if (resp.statusCode != 200) {
          dev_tool.log(
            "EERROORR, EERROORR: ${resBody["detail"]}",
          );
          throw CouldnotGetUser();
        }

        final currentUser = AuthUser.fromFinance(resBody);
        return currentUser;
      } on AuthException catch (_) {
        rethrow;
      } catch (e) {
        throw Exception("Couldnot get User Cridentials: $e");
      }
  }

  @override
  Future<AuthUser> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotLogIn(errorDetail);
      }

      // request successful -> save tokens in secure storage
      final accessToken = json["acc_jwt"] as String;
      final refreshToken = json["ref_jwt"] as String;

      await secureStorageService.saveString(key: "access_token", value: accessToken);
      await secureStorageService.saveString(key: "refresh_token", value: refreshToken);

      return await _getUserCridentials(accessToken);

    } on AuthException catch (_) {
      rethrow;
    } catch(e){
      throw Exception("Login Failed: $e");
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

    final response = await http.post(
      Uri.parse("$baseUrl/login/google"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id_token': idToken,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final errorDetail = json["detail"] as String;
      dev_tool.log("EERROORR, EERROORR: $errorDetail");
      throw CouldnotLogInWithGoogle();
    } 
    // request successful -> save token's in secure storage
    // then request user from back end and return it
    final accessToken = json["acc_jwt"] as String;
    final refreshToken= json["ref_jwt"] as String;

    await secureStorageService.saveString(key: "access_token", value: accessToken);
    await secureStorageService.saveString(key: "refresh_token", value: refreshToken);

    return await _getUserCridentials(accessToken);
    } on AuthException catch (_) {
      rethrow;
    } on GoogleSignInException catch (e){
      if(e.code != GoogleSignInExceptionCode.canceled){
        throw Exception("Login with Google Fialed: $e");
      }
    } catch(e){
      throw Exception("Login with Google Fialed: $e");
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final res = await http.post(
        headers: {"Content-Type": "application/json"},
        Uri.parse("$baseUrl/register"),
        body: jsonEncode({"email": email, "password": password}),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotRegister(errorDetail);
      }

      // request successful -> save tokens in secure storage
      final accessToken = json["acc_jwt"] as String;
      final refreshToken = json["ref_jwt"] as String;

      await secureStorageService.saveString(key: "access_token", value: accessToken);
      await secureStorageService.saveString(key: "refresh_token", value: refreshToken);

      return await _getUserCridentials(accessToken);
    } on AuthException catch (_) {
      rethrow;
    } catch(e){
      throw Exception("Register Failed: $e");
    }
  }

  @override
  Future<void> sendVerificationEmail(String email) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/resend-verification"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotSendEmailVerificatonLink(errorDetail);
      }
    } on AuthException catch (_) {
      rethrow;
    } catch(e) {
      throw Exception("Couldnot send email verification link: $e");
    }
  }

  @override
  Future<void> logout() async {
    await secureStorageService.deleteAll();
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      final accessToken = await secureStorageService.readString(key: "access_token");
      if(accessToken == null){
        throw NoUserToDelete();
      }
      final res = await http.delete(
        Uri.parse("$baseUrl/me"),
        headers: {
            "Authorization": "Bearer $accessToken",
          },
      );

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final errorDetail = json["detail"] as String;
        dev_tool.log("EERROORR, EERROORR: $errorDetail");
        throw CouldnotDeleteUser();
      }

      await secureStorageService.deleteAll();
    } on AuthException catch (_) {
      rethrow;
    } catch(e) {
      throw Exception("Couldnot Delete User: $e");
    }
  }
}
