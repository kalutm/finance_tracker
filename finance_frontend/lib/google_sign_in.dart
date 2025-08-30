import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

// Your backend's login endpoint
final baseUrl = dotenv.env["API_BASE_URL_MOBILE"];
final backendUrl = '$baseUrl/login/google';

// Access the singleton instance of GoogleSignIn
final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

Future<void> signInWithGoogle(String serverClientId) async {
  try {
    // 1. Initialize the instance with the serverClientId
    await _googleSignIn.initialize(serverClientId: serverClientId);

    // 2. Trigger the Google Sign-in flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

    if (googleUser == null) {
      // User cancelled the sign-in
      return;
    }

    // 3. Get the ID token from the user
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    print(idToken);

    if (idToken == null) {
      // Something went wrong, no ID token available
      return;
    }

    // 4. Send the ID token to your custom backend
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'id_token': idToken,
      }),
    );

    // 5. Handle the backend's response
    if (response.statusCode == 200) {
      // Login successful!
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('Login successful! User: ${data['email']}');
      // You can now save the backend's token and navigate the user.
    } else {
      // Backend returned an error
      print('Backend error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Google sign-in failed: $e');
  }
}

class GoogleSignInButton extends StatelessWidget {
  final String serverClientId;

  const GoogleSignInButton({super.key, required this.serverClientId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => signInWithGoogle(serverClientId),
      child: const Text('Sign in with Google'),
    );
  }
}