import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../../../core/services/notification_service.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  bool _mealRemindersEnabled = false;
  bool _isLoading = false;

  bool get mealRemindersEnabled => _mealRemindersEnabled;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _d('loadSettings');
    _isLoading = true;
    notifyListeners();

    _mealRemindersEnabled = await _settingsService.loadMealRemindersEnabled();
    _d('loadSettings — reminders enabled: $_mealRemindersEnabled');

    // Reschedule on load in case the OS cleared them after reboot
    if (_mealRemindersEnabled) {
      await NotificationService.scheduleMealReminders();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setMealRemindersEnabled(bool value) async {
    _d('setMealRemindersEnabled → $value');

    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        _d('setMealRemindersEnabled — permission denied, not enabling');
        return;
      }
      await NotificationService.scheduleMealReminders();
    } else {
      await NotificationService.cancelAll();
    }

    _mealRemindersEnabled = value;
    notifyListeners();
    await _settingsService.saveMealRemindersEnabled(value);
    _d('setMealRemindersEnabled — saved: $value');
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Settings');
  }
}
