import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for meal-reminder scheduling.
/// Call [init] once at app startup (before runApp), then call
/// [scheduleMealReminders] / [cancelAll] based on the user's preference.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'nutrivision_meal_reminders';
  static const _channelName = 'Meal Reminders';
  static const _channelDesc = 'Daily reminders to log your meals';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(sound: 'default'),
  );

  // Default reminder times: breakfast, lunch, dinner
  static const _reminderTimes = [
    _ReminderTime(8, 0, 0, 'Breakfast time!', "Don't forget to log your breakfast."),
    _ReminderTime(13, 0, 1, 'Lunch time!', 'Log your lunch to stay on track.'),
    _ReminderTime(19, 0, 2, 'Dinner time!', 'Log your dinner and check your daily progress.'),
  ];

  static Future<void> init() async {
    tz.initializeTimeZones();
    // Use device local offset to pick the closest IANA timezone
    _setLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create the Android notification channel explicitly on startup.
    // Without this, the "Meal Reminders" category never appears in the system
    // notification settings until the first notification fires.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    _log('init — plugin initialized, local tz: ${tz.local.name}');
  }

  /// Best-effort local timezone detection without flutter_timezone package.
  /// Maps the device's UTC offset to a representative IANA timezone so that
  /// notifications fire at the correct local time.
  static void _setLocalTimezone() {
    try {
      final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      // Walk all known zones and pick the first one with a matching current offset.
      for (final loc in tz.timeZoneDatabase.locations.values) {
        final tzNow = tz.TZDateTime.now(loc);
        if (tzNow.timeZoneOffset.inMinutes == offsetMinutes) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (_) {
      // Falls through to UTC default — notifications will still be scheduled,
      // just relative to UTC rather than local time.
    }
  }

  /// Returns true if the OS has notifications enabled for this app
  /// (without prompting the user).
  static Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    // iOS — assume enabled if we got here (no silent check API)
    return true;
  }

  /// Requests OS-level notification permission (iOS prompt / Android 13+ prompt).
  /// Returns true if permission was granted.
  /// Returns false if already permanently denied — caller should redirect to Settings.
  static Future<bool> requestPermission() async {
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final result = await ios.requestPermissions(alert: true, badge: true, sound: true);
        _log('requestPermission iOS → $result');
        return result ?? false;
      }

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final result = await android.requestNotificationsPermission();
        _log('requestPermission Android → $result');
        return result ?? false;
      }

      // Platform not resolved — assume granted (e.g. Android < 13 where no
      // runtime permission is needed).
      return true;
    } catch (e) {
      _log('requestPermission error: $e');
      return false;
    }
  }

  /// Schedules the three daily meal-reminder notifications.
  /// Tries exact scheduling first; falls back to inexact if the device does not
  /// allow exact alarms (Android 12 requires the user to grant SCHEDULE_EXACT_ALARM
  /// in Special App Access — throwing PlatformException if not granted).
  static Future<void> scheduleMealReminders() async {
    await cancelAll();
    for (final r in _reminderTimes) {
      final scheduledDate = _nextInstanceOf(r.hour, r.minute);
      bool scheduled = false;

      // Attempt 1: exact alarm (fires precisely at the scheduled time)
      try {
        await _plugin.zonedSchedule(
          r.id,
          r.title,
          r.body,
          scheduledDate,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduled = true;
        _log('scheduled (exact): ${r.title} → $scheduledDate');
      } on PlatformException catch (e) {
        _log('exact alarm not permitted (${e.code}), falling back to inexact');
      } catch (e) {
        _log('exact alarm error: $e, falling back to inexact');
      }

      // Attempt 2: inexact alarm (fires approximately at the scheduled time —
      // works on all API levels without special permissions)
      if (!scheduled) {
        try {
          await _plugin.zonedSchedule(
            r.id,
            r.title,
            r.body,
            scheduledDate,
            _details,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          _log('scheduled (inexact): ${r.title} → $scheduledDate');
        } catch (e) {
          _log('inexact alarm error: $e');
          rethrow;
        }
      }
    }
  }

  /// Cancels all scheduled notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _log('cancelAll — all reminders cancelled');
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static void _log(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Notify');
  }
}

class _ReminderTime {
  const _ReminderTime(this.hour, this.minute, this.id, this.title, this.body);
  final int hour;
  final int minute;
  final int id;
  final String title;
  final String body;
}
