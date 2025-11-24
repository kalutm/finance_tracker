import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:finance_frontend/features/auth/presentation/views/app_wrapper.dart';
import 'package:finance_frontend/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:finance_frontend/features/settings/presentation/cubits/settings_state.dart';
import 'package:finance_frontend/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: FinanceTracker()));
}

class FinanceTracker extends ConsumerWidget {
  const FinanceTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => ref.read(authCubitProvider)..checkStatus(),
        ),
        BlocProvider<SettingsCubit>(
          create:
              (context) => ref.read(settingsCubitProvider)..checkModeStatus(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsInitial) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: AppWrapper(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                (state is SettingsStateLight)
                    ? ThemeMode.light
                    : ThemeMode.dark,
          );
        },
      ),
    );
  }
}
