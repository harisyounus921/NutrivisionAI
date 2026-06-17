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
    _d('loadSettings — stored preference: $_mealRemindersEnabled');

    if (_mealRemindersEnabled) {
      // Verify the OS permission is still granted (user may have revoked it in Settings)
      final stillGranted = await NotificationService.areNotificationsEnabled();
      if (stillGranted) {
        await NotificationService.scheduleMealReminders();
        _d('loadSettings — notifications active, reminders rescheduled');
      } else {
        // Permission was revoked — clear the stored preference to match reality
        _mealRemindersEnabled = false;
        await _settingsService.saveMealRemindersEnabled(false);
        _d('loadSettings — OS permission revoked, preference cleared');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Enables or disables meal reminders.
  /// Returns [true] if the change was applied.
  /// Returns [false] if the OS permission was denied — caller should prompt user to open Settings.
  Future<bool> setMealRemindersEnabled(bool value) async {
    _d('setMealRemindersEnabled → $value');

    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        _d('setMealRemindersEnabled — OS permission denied');
        return false;
      }
      await NotificationService.scheduleMealReminders();
    } else {
      await NotificationService.cancelAll();
    }

    _mealRemindersEnabled = value;
    notifyListeners();
    await _settingsService.saveMealRemindersEnabled(value);
    _d('setMealRemindersEnabled — saved: $value');
    return true;
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Settings');
  }
}
