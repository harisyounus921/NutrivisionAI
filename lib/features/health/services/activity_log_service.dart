import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';

class ActivityLogService {
  static const _keyActivityLogs = 'activity_logs';

  Future<List<ActivityLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_keyActivityLogs);
    if (stored == null) return [];

    return stored
        .map((entry) => ActivityLog.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLogs(List<ActivityLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = logs.map((log) => jsonEncode(log.toJson())).toList();
    await prefs.setStringList(_keyActivityLogs, encoded);
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivityLogs);
  }
}
