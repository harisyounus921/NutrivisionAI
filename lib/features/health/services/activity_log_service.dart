import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  static const _keyActivityLogs = 'activity_logs';

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

  Future<void> syncDay(DateTime date, List<ActivityLog> dayLogs) async {
    final steps = dayLogs.fold(0, (total, log) => total + log.steps);
    final calories = dayLogs.fold<double>(
      0,
      (total, log) => total + log.caloriesBurned,
    );
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await FirebaseBackend.userCollection(
      FirebaseCollections.healthSummariesPath,
    ).doc(dateStr).set({
      'date': dateStr,
      'steps': steps,
      'caloriesBurned': calories,
      'source': 'manual',
      'activeMinutes': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivityLogs);
  }
}
