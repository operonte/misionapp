import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyThemeIndex = 'theme_index';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // SharedPreferences caches all values in memory after initialization,
  // so these getters are effectively synchronous.

  bool isOnboardingDone() => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) async {
    await _prefs.setBool(_keyOnboardingDone, value);
  }

  int getThemeIndex() => _prefs.getInt(_keyThemeIndex) ?? 0;

  Future<void> setThemeIndex(int index) async {
    await _prefs.setInt(_keyThemeIndex, index);
  }
}
