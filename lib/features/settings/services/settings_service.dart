import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyMealRemindersEnabled = 'meal_reminders_enabled';

  Future<bool> loadMealRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMealRemindersEnabled) ?? false;
  }

  Future<void> saveMealRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMealRemindersEnabled, value);
  }
}
