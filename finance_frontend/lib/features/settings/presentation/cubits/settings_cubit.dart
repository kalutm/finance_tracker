import 'package:finance_frontend/features/settings/presentation/cubits/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this.darkMode) : super(SettingsStateDark());

  bool darkMode;

  void changeTheme(){
    final isDarkMode = darkMode;
    darkMode = !isDarkMode;
    emit(isDarkMode ? SettingsStateLight() : SettingsStateDark());
  }
}