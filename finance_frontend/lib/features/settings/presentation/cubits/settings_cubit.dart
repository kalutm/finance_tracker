import 'package:finance_frontend/features/settings/domain/services/shared_preferences_service.dart';
import 'package:finance_frontend/features/settings/presentation/cubits/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._sharedPreferencesService) : super(SettingsInitial());

  final SharedPreferencesService _sharedPreferencesService;

  late bool darkMode;
  Future<void> checkModeStatus() async {
    final isDarkMode = await _sharedPreferencesService.isDarkMode();
    darkMode = isDarkMode;
    if(isDarkMode) {
      emit(SettingsStateDark());
      } else{
        emit(SettingsStateLight());
      }

  }
  void changeTheme(){
    final isDarkMode = darkMode;
    if(isDarkMode){
      _sharedPreferencesService.setLightMode();
    } else{
      _sharedPreferencesService.setDarkMode();
    }
    darkMode = !isDarkMode;
    emit(isDarkMode ? SettingsStateLight() : SettingsStateDark());
  }
}