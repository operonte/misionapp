import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyOnboardingDone = 'onboarding_done';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<bool> isOnboardingDone() async {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    await _prefs.setBool(_keyOnboardingDone, value);
  }
}
