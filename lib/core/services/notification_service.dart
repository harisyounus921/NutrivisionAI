import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    await _configureLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create the Android notification channel explicitly on startup so it
    // appears in system notification settings before the first notification fires.
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

    _log('init — ready, local tz: ${tz.local.name}');
  }

  /// Sets tz.local to the device's actual IANA timezone (e.g. "Asia/Karachi").
  /// Without this, tz.local defaults to UTC and notifications fire at the wrong
  /// local time (e.g. 8 AM UTC = 1 PM Pakistan time).
  static Future<void> _configureLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _log('timezone → ${info.identifier}');
    } catch (e) {
      _log('timezone detection failed: $e — defaulting to UTC');
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
        // If notifications are already enabled at the OS level, treat as
        // granted. requestNotificationsPermission() returns null (→ false here)
        // when there is no system dialog to show because permission is already
        // granted, which would otherwise be misread as "denied".
        final alreadyEnabled = await android.areNotificationsEnabled() ?? false;
        if (alreadyEnabled) {
          _log('requestPermission Android → already enabled');
          return true;
        }
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

/// Injectable seam over [NotificationService]'s static API so callers like
/// [SettingsProvider] can be unit-tested without the platform plugin.
/// Production code uses [defaultNotificationController].
abstract class NotificationController {
  Future<bool> areNotificationsEnabled();
  Future<bool> requestPermission();
  Future<void> scheduleMealReminders();
  Future<void> cancelAll();
}

class _DefaultNotificationController implements NotificationController {
  const _DefaultNotificationController();

  @override
  Future<bool> areNotificationsEnabled() =>
      NotificationService.areNotificationsEnabled();

  @override
  Future<bool> requestPermission() => NotificationService.requestPermission();

  @override
  Future<void> scheduleMealReminders() =>
      NotificationService.scheduleMealReminders();

  @override
  Future<void> cancelAll() => NotificationService.cancelAll();
}

const NotificationController defaultNotificationController =
    _DefaultNotificationController();
