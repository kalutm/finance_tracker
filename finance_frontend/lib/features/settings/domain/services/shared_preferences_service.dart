abstract class SharedPreferencesService {
  Future<void> setDarkMode();
  Future<bool> isDarkMode();
  Future<void> setLightMode();
}