import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_client.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  ActivityLogService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const _keyActivityLogs = 'activity_logs';

  final ApiClient _api;

  Future<List<ActivityLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_keyActivityLogs);
    if (stored == null) return [];
    return stored
        .map((e) => ActivityLog.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLogs(List<ActivityLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = logs.map((log) => jsonEncode(log.toJson())).toList();
    await prefs.setStringList(_keyActivityLogs, encoded);
  }

  /// Syncs the day's aggregated activity totals to the backend.
  Future<void> syncDay(DateTime date, List<ActivityLog> dayLogs) async {
    final steps = dayLogs.fold(0, (sum, log) => sum + log.steps);
    final calories = dayLogs.fold<double>(0, (sum, log) => sum + log.caloriesBurned);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _api.post('/health/sync', body: {
      'date': dateStr,
      'steps': steps,
      'caloriesBurned': calories,
      'source': 'manual',
    });
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivityLogs);
  }
}
