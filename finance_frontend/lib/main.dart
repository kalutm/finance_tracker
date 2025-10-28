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