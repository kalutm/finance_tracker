import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:finance_frontend/features/settings/presentation/cubits/settings_state.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:finance_frontend/features/auth/presentation/views/app_wrapper.dart';
import 'package:finance_frontend/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: _AppBootstrap()));
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Schedule service init/start after first frame so "ref" is available
    Future.microtask(() async {
      //final smsService = ref.read(smsServiceProvider);
      //await smsService.init(); // loads prefs, creates accounts if needed
      //smsService.start(listenInBackground: true); // try realtime listener
      //await smsService.syncInboxOnResume(); // initial inbox sync
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final smsService = ref.read(smsServiceProvider);
      // Fire-and-forget; the method is defensive.
      //smsService.syncInboxOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep your existing Bloc setup and MaterialApp wiring here.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
            create: (context) => ref.read(authCubitProvider)..checkStatus()),
        BlocProvider<SettingsCubit>(
            create: (context) => ref.read(settingsCubitProvider)..checkModeStatus()),
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
            themeMode: (state is SettingsStateLight) ? ThemeMode.light : ThemeMode.dark,
          );
        },
      ),
    );
  }
}
