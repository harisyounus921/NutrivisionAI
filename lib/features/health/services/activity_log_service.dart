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
    final manualSteps = dayLogs.fold(0, (total, log) => total + log.steps);
    final manualCalories = dayLogs.fold<double>(
      0,
      (total, log) => total + log.caloriesBurned,
    );
    final dateStr = _dateKey(date);
    final doc = FirebaseBackend.userCollection(
      FirebaseCollections.healthSummariesPath,
    ).doc(dateStr);
    final existing = (await doc.get()).data() ?? <String, dynamic>{};

    final deviceSteps = _existingDeviceSteps(existing);
    final deviceCalories = _existingDeviceCalories(existing);
    final deviceActiveMinutes = _existingDeviceActiveMinutes(existing);
    final deviceSource =
        existing['deviceSource'] as String? ??
        (existing['source'] == 'apple_health'
            ? 'apple_health'
            : existing['source'] == 'google_fit'
            ? 'health_connect'
            : existing['source'] == 'health_connect'
            ? 'health_connect'
            : null);

    await doc.set({
      'date': dateStr,
      'manualSteps': manualSteps,
      'manualCaloriesBurned': manualCalories,
      'manualActiveMinutes': 0,
      'deviceSteps': deviceSteps,
      'deviceCaloriesBurned': deviceCalories,
      'deviceActiveMinutes': deviceActiveMinutes,
      'steps': manualSteps + deviceSteps,
      'caloriesBurned': manualCalories + deviceCalories,
      'activeMinutes': deviceActiveMinutes,
      'source': _sourceFor(
        manualSteps: manualSteps,
        manualCalories: manualCalories,
        deviceSteps: deviceSteps,
        deviceCalories: deviceCalories,
        deviceSource: deviceSource,
      ),
      'deviceSource': deviceSource,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivityLogs);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _existingDeviceSteps(Map<String, dynamic> data) {
    final device = data['deviceSteps'] as num?;
    if (device != null) return device.toInt();
    return _legacyDeviceSource(data) ? (data['steps'] as num? ?? 0).toInt() : 0;
  }

  double _existingDeviceCalories(Map<String, dynamic> data) {
    final device = data['deviceCaloriesBurned'] as num?;
    if (device != null) return device.toDouble();
    return _legacyDeviceSource(data)
        ? (data['caloriesBurned'] as num? ?? 0).toDouble()
        : 0;
  }

  int _existingDeviceActiveMinutes(Map<String, dynamic> data) {
    final device = data['deviceActiveMinutes'] as num?;
    if (device != null) return device.toInt();
    return _legacyDeviceSource(data)
        ? (data['activeMinutes'] as num? ?? 0).toInt()
        : 0;
  }

  bool _legacyDeviceSource(Map<String, dynamic> data) =>
      data['source'] == 'apple_health' ||
      data['source'] == 'google_fit' ||
      data['source'] == 'health_connect';

  String _sourceFor({
    required int manualSteps,
    required double manualCalories,
    required int deviceSteps,
    required double deviceCalories,
    required String? deviceSource,
  }) {
    final hasManual = manualSteps > 0 || manualCalories > 0;
    final hasDevice = deviceSteps > 0 || deviceCalories > 0;
    if (hasManual && hasDevice) return 'combined';
    if (hasDevice) return deviceSource ?? 'health_connect';
    return 'manual';
  }
}
