import 'package:finance_frontend/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:finance_frontend/features/settings/presentation/cubits/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocSelector<SettingsCubit, SettingsState, bool>(
        selector: (state) => state is SettingsStateDark,
        builder: (context, isDarkMode) {
          return SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (_) => context.read<SettingsCubit>().changeTheme(),
            secondary: Icon(
              isDarkMode ? Icons.brightness_2 : Icons.brightness_7,
            ),
          );
        },
      ),
    );
  }
}
