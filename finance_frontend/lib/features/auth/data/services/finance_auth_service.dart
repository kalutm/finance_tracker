import 'dart:convert';

import 'package:finance_frontend/features/auth/domain/entities/auth_user.dart';
import 'package:finance_frontend/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:finance_frontend/features/auth/domain/services/auth_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer' as dev_tool show log;

class FinanceAuthService implements AuthService {
  final SecureStorageService secureStorageService;

  FinanceAuthService(this.secureStorageService);

  final baseUrl = dotenv.env["API_BASE_URL_MOBILE"];

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
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                Uri.parse("$baseUrl/refresh"),
                body: {"refresh_token": refreshToken},
              );

              if (res.statusCode != 200) {
                dev_tool.log(
                  "EERROORR, EERROORR: ${jsonDecode(res.body)["detail"]}",
                );
                throw CouldnotGetUser();
              }

              final newAccess = jsonDecode(res.body)["acc_jwt"] as String;
              await secureStorageService.saveString(
                key: "access_token",
                value: newAccess,
              );

              final resp = await http.get(
                Uri.parse("$baseUrl/me"),
                headers: {
                  "Authorization": newAccess,
                  "Content-Type": "application/json",
                },
              );

              if (resp.statusCode != 200) {
                dev_tool.log(
                  "EERROORR, EERROORR: ${jsonDecode(resp.body)["detail"]}",
                );
                throw CouldnotGetUser();
              }

              final user = jsonDecode(resp.body) as Map<String, dynamic>;
              final currentUser = AuthUser.fromFinance(user);
              return currentUser;
            } on AuthException catch (_) {
              rethrow;
            } catch (e) {
              throw Exception("Could not get user: $e");
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
        final resp = await http.get(
        Uri.parse("$baseUrl/me"),
        headers: {
          "Authorization": accessToken,
          "Content-Type": "application/json",
        },
      );

      if (resp.statusCode != 200) {
        dev_tool.log("EERROORR, EERROORR: ${jsonDecode(resp.body)["detail"]}");
        throw CouldnotGetUser();
      }

      final user = jsonDecode(resp.body) as Map<String, dynamic>;
      final currentUser = AuthUser.fromFinance(user);
      return currentUser;
      } on AuthException catch(_){
        rethrow;
      } catch (e) {
        throw Exception("Could not get user: $e");
      }
    }
    // No tokens stored → return null -> user must log in again
    return null;
  }

  @override
  Future<AuthUser?> loginWithEmailAndPassword(String email, String password) {
    // TODO: implement loginWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> loginWithGoogle(String email) {
    // TODO: implement loginWithGoogle
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> registerWithEmailAndPassword(
    String email,
    String password,
  ) {
    // TODO: implement registerWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future<void> sendVerificationEmail(String email) {
    // TODO: implement sendVerificationEmail
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCurrentUser(String token) {
    // TODO: implement logout
    throw UnimplementedError();
  }
}
