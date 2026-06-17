import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Result of a health-data sync from the device sensor (Google Fit / Apple Health).
class DeviceHealthData {
  const DeviceHealthData({
    required this.steps,
    required this.caloriesBurned,
    required this.activeMinutes,
  });

  final int steps;
  final double caloriesBurned;
  final int activeMinutes;
}

/// Reads today's health data from Google Fit (Android) or Apple Health (iOS)
/// using the `health` package.
class HealthDeviceService {
  static final _health = Health();

  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Configures Health Connect on Android (no-op on iOS).
  static Future<void> configure() async {
    if (Platform.isAndroid) {
      await _health.configure();
      _log('configure — Health Connect configured');
    }
  }

  /// Requests read permission for steps and active energy.
  /// Returns true if the user granted access.
  static Future<bool> requestPermissions() async {
    try {
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();
      final granted = await _health.requestAuthorization(_types, permissions: permissions);
      _log('requestPermissions → $granted');
      return granted;
    } catch (e) {
      _log('requestPermissions — error: $e');
      return false;
    }
  }

  /// Checks whether we already have permission without prompting.
  static Future<bool> hasPermissions() async {
    try {
      final result = await _health.hasPermissions(_types);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reads today's steps, calories burned, and active minutes.
  /// Returns null if permissions are not granted or data cannot be read.
  static Future<DeviceHealthData?> readToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      // Steps — convenient helper
      final steps = await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;

      // Calories and active minutes from raw data points
      final points = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      final deduped = _health.removeDuplicates(points);
      final calories = deduped.fold<double>(
        0,
        (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toDouble(),
      );

      // Estimate active minutes: 1 active minute per 3.5 kcal burned (rough MET estimate)
      final activeMinutes = calories > 0 ? (calories / 3.5).round() : 0;

      final result = DeviceHealthData(
        steps: steps,
        caloriesBurned: calories,
        activeMinutes: activeMinutes,
      );
      _log('readToday — steps: $steps, calories: ${calories.toStringAsFixed(0)}, active: ${activeMinutes}min');
      return result;
    } catch (e) {
      _log('readToday — error: $e');
      return null;
    }
  }

  static void _log(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·HealthSync');
  }
}
