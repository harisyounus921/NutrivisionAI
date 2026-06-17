import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
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

  // Default reminder times: breakfast, lunch, dinner
  static const _reminderTimes = [
    _ReminderTime(8, 0, 0, 'Breakfast time! 🥗', 'Don\'t forget to log your breakfast.'),
    _ReminderTime(13, 0, 1, 'Lunch time! 🥙', 'Log your lunch to stay on track.'),
    _ReminderTime(19, 0, 2, 'Dinner time! 🍽️', 'Log your dinner and check your daily progress.'),
  ];

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _log('init — plugin initialized');
  }

  /// Requests OS-level notification permission (iOS prompt / Android 13+ prompt).
  /// Returns true if permission was granted.
  static Future<bool> requestPermission() async {
    bool granted = false;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(alert: true, badge: true, sound: true);
      granted = result ?? false;
      _log('requestPermission iOS → $granted');
      return granted;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final result = await android.requestNotificationsPermission();
      granted = result ?? false;
      _log('requestPermission Android → $granted');
      return granted;
    }

    return true; // Other platforms
  }

  /// Schedules the three daily meal-reminder notifications.
  /// Each repeats at the same wall-clock time every day.
  static Future<void> scheduleMealReminders() async {
    await cancelAll();
    for (final r in _reminderTimes) {
      final scheduledDate = _nextInstanceOf(r.hour, r.minute);
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        scheduledDate,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(sound: 'default'),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _log('scheduled: ${r.title} at ${r.hour}:${r.minute.toString().padLeft(2, '0')} (next: $scheduledDate)');
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
