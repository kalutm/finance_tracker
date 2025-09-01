import 'package:finance_frontend/features/auth/data/services/finance_auth_service.dart';
import 'package:finance_frontend/features/auth/data/services/finance_secure_storage_service.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:finance_frontend/features/auth/presentation/views/app_wrapper.dart';
import 'package:finance_frontend/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const FinanceTracker());
}

class FinanceTracker extends StatelessWidget {
  const FinanceTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create:
          (context) =>
              AuthCubit(FinanceAuthService(FinanceSecureStorageService()))
                ..checkStatus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppWrapper(),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
      ),
    );
  }
}

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   late final TextEditingController _emailController;
//   late final TextEditingController _passwordController;
//   late final GoogleSignIn googleSignIn;
//   late final String clientServerId;

//   @override
//   void initState() {
//     _emailController = TextEditingController();
//     _passwordController = TextEditingController();
//     googleSignIn = GoogleSignIn.instance;
//     clientServerId = dotenv.env["GOOGLE_SERVER_CLIENT_ID_WEB"]!;
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> sendData() async {
//     final baseUrl = dotenv.env["API_BASE_URL_MOBILE"];

//     try {
//       final uri = Uri.parse("$baseUrl/register");
//       final res = await http.post(
//         uri,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "email": _emailController.text,
//           "password": _passwordController.text,
//         }),
//       );
//       print("REFRESH TOKEN HERE YOU GO ${jsonDecode(res.body)["ref_jwt"]}");
//     } catch (e) {
//       print(e.toString());
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Testing")),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         //mainAxisSize: MainAxisSize.min,
//         children: [
//           TextField(
//             controller: _emailController,
//             decoration: InputDecoration(
//               labelText: "Email",
//               helperText: "Enter email",
//             ),
//             autocorrect: false,
//             keyboardType: TextInputType.emailAddress,
//           ),
//           TextField(
//             controller: _passwordController,
//             decoration: InputDecoration(
//               labelText: "Password",
//               helperText: "Enter Password",
//             ),
//             autocorrect: false,
//             keyboardType: TextInputType.visiblePassword,
//           ),
//           TextButton(
//             onPressed: () async {
//               await sendData();
//             },
//             child: Text("register"),
//           ),
//           GoogleSignInButton(serverClientId: clientServerId),
//         ],
//       ),
//     );
//   }
// }
