import 'package:finance_frontend/features/settings/domain/services/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceSharedPreferencesService implements SharedPreferencesService{
  
  Future<SharedPreferences> get _sharedPreferences async {
    return await SharedPreferences.getInstance();
  } 
  @override
  Future<bool> isDarkMode() async {
    final sharedPref = await _sharedPreferences;
    final isDarkMode = sharedPref.getBool("isDarkMode") ?? true;
    return isDarkMode;
  }

  @override
  Future<void> setDarkMode() async {
    final sharedPref = await _sharedPreferences;
    sharedPref.setBool("isDarkMode", true);
  }

  @override
  Future<void> setLightMode() async {
    final sharedPref = await _sharedPreferences;
    sharedPref.setBool("isDarkMode", false);
  }

}