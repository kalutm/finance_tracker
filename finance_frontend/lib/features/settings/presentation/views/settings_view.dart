import 'package:finance_frontend/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings")
      ),
      body: SwitchListTile(
            title: const Text('Dark Mode'),
            value: context.read<SettingsCubit>().darkMode,
            onChanged: (dark) => context.read<SettingsCubit>().changeTheme(),
            secondary: Icon(context.read<SettingsCubit>().darkMode ? Icons.brightness_2 : Icons.brightness_7),
          ),
    );
  }
}