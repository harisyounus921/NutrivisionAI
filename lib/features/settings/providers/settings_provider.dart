import 'package:flutter/foundation.dart';

import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? settingsService}) : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  bool _mealRemindersEnabled = false;
  bool _isLoading = false;

  bool get mealRemindersEnabled => _mealRemindersEnabled;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _mealRemindersEnabled = await _settingsService.loadMealRemindersEnabled();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setMealRemindersEnabled(bool value) async {
    _mealRemindersEnabled = value;
    notifyListeners();
    await _settingsService.saveMealRemindersEnabled(value);
  }
}
