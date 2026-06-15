import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_log.dart';

class MealLogService {
  static const _keyMealLogs = 'meal_logs';

  Future<List<MealLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_keyMealLogs);
    if (stored == null) return [];

    return stored
        .map((entry) => MealLog.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLogs(List<MealLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = logs.map((log) => jsonEncode(log.toJson())).toList();
    await prefs.setStringList(_keyMealLogs, encoded);
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMealLogs);
  }
}
