import 'package:flutter_test/flutter_test.dart';

import 'package:meal_nudge/core/services/notification_service.dart';
import 'package:meal_nudge/features/settings/providers/settings_provider.dart';
import 'package:meal_nudge/features/settings/services/settings_service.dart';

class _FakeNotifications implements NotificationController {
  _FakeNotifications({this.permissionGranted = true, this.osEnabled = true});

  bool permissionGranted;
  bool osEnabled;

  int requestPermissionCalls = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;

  @override
  Future<bool> areNotificationsEnabled() async => osEnabled;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleMealReminders() async => scheduleCalls++;

  @override
  Future<void> cancelAll() async => cancelCalls++;
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService({this.stored = false});

  bool stored;
  bool? lastSaved;

  @override
  Future<bool> loadMealRemindersEnabled() async => stored;

  @override
  Future<void> saveMealRemindersEnabled(bool value) async {
    lastSaved = value;
    stored = value;
  }
}

void main() {
  group('SettingsProvider.setMealRemindersEnabled', () {
    test(
      'enabling when permission is granted turns on, schedules, and persists',
      () async {
        final notifications = _FakeNotifications(permissionGranted: true);
        final settings = _FakeSettingsService();
        final provider = SettingsProvider(
          settingsService: settings,
          notifications: notifications,
        );

        final applied = await provider.setMealRemindersEnabled(true);

        expect(applied, isTrue);
        expect(provider.mealRemindersEnabled, isTrue);
        expect(notifications.scheduleCalls, 1);
        expect(settings.lastSaved, isTrue);
      },
    );

    test(
      'enabling when permission is denied stays off and does not schedule or persist',
      () async {
        final notifications = _FakeNotifications(permissionGranted: false);
        final settings = _FakeSettingsService();
        final provider = SettingsProvider(
          settingsService: settings,
          notifications: notifications,
        );

        final applied = await provider.setMealRemindersEnabled(true);

        expect(applied, isFalse);
        expect(provider.mealRemindersEnabled, isFalse);
        expect(notifications.scheduleCalls, 0);
        expect(settings.lastSaved, isNull);
      },
    );

    test('disabling cancels reminders and persists false', () async {
      final notifications = _FakeNotifications();
      final settings = _FakeSettingsService(stored: true);
      final provider = SettingsProvider(
        settingsService: settings,
        notifications: notifications,
      );

      final applied = await provider.setMealRemindersEnabled(false);

      expect(applied, isTrue);
      expect(provider.mealRemindersEnabled, isFalse);
      expect(notifications.cancelCalls, 1);
      expect(notifications.requestPermissionCalls, 0);
      expect(settings.lastSaved, isFalse);
    });
  });

  group('SettingsProvider.loadSettings', () {
    test(
      'reschedules reminders when stored on and OS still allows them',
      () async {
        final notifications = _FakeNotifications(osEnabled: true);
        final settings = _FakeSettingsService(stored: true);
        final provider = SettingsProvider(
          settingsService: settings,
          notifications: notifications,
        );

        await provider.loadSettings();

        expect(provider.mealRemindersEnabled, isTrue);
        expect(notifications.scheduleCalls, 1);
      },
    );

    test(
      'clears the preference when stored on but OS permission was revoked',
      () async {
        final notifications = _FakeNotifications(osEnabled: false);
        final settings = _FakeSettingsService(stored: true);
        final provider = SettingsProvider(
          settingsService: settings,
          notifications: notifications,
        );

        await provider.loadSettings();

        expect(provider.mealRemindersEnabled, isFalse);
        expect(notifications.scheduleCalls, 0);
        expect(settings.lastSaved, isFalse);
      },
    );
  });
}
