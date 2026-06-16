import 'dart:developer' as dev;

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
    _d('loadSettings — GET /settings/reminders');
    _isLoading = true;
    notifyListeners();

    _mealRemindersEnabled = await _settingsService.loadMealRemindersEnabled();
    _d('loadSettings — reminders enabled: $_mealRemindersEnabled');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setMealRemindersEnabled(bool value) async {
    _d('setMealRemindersEnabled — PUT /settings/reminders → $value');
    _mealRemindersEnabled = value;
    notifyListeners();
    await _settingsService.saveMealRemindersEnabled(value);
    _d('setMealRemindersEnabled — saved');
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Settings');
  }
}
