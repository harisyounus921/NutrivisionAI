import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../../../core/services/notification_service.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    SettingsService? settingsService,
    NotificationController? notifications,
  }) : _settingsService = settingsService ?? SettingsService(),
       _notifications = notifications ?? defaultNotificationController;

  final SettingsService _settingsService;
  final NotificationController _notifications;

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
      final stillGranted = await _notifications.areNotificationsEnabled();
      if (stillGranted) {
        await _notifications.scheduleMealReminders();
        _d('loadSettings — notifications active, reminders rescheduled');
      } else {
        _mealRemindersEnabled = false;
        await _settingsService.saveMealRemindersEnabled(false);
        _d('loadSettings — OS permission revoked, preference cleared');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setMealRemindersEnabled(bool value) async {
    _d('setMealRemindersEnabled → $value');
    try {
      if (value) {
        final granted = await _notifications.requestPermission();
        if (!granted) {
          _d('setMealRemindersEnabled — OS permission denied');
          return false;
        }
        await _notifications.scheduleMealReminders();
      } else {
        await _notifications.cancelAll();
      }

      _mealRemindersEnabled = value;
      notifyListeners();
      await _settingsService.saveMealRemindersEnabled(value);
      _d('setMealRemindersEnabled — saved: $value');
      return true;
    } catch (e) {
      _d('setMealRemindersEnabled error: $e');
      return false;
    }
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'MealNudge·Settings');
  }
}
