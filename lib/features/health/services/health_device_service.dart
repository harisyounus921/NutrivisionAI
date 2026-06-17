import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum HealthConnectAvailability { available, notInstalled, notSupported }

class HealthDeviceService {
  static final _health = Health();
  static const _prefsKey = 'health_permissions_granted';

  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static Future<void> configure() async {
    if (Platform.isAndroid) {
      await _health.configure();
      _log('configure — Health Connect configured');
    }
  }

  /// Returns true if the user already granted permissions in a previous session.
  /// Avoids showing the Health Connect dialog on every app restart.
  static Future<bool> wasPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> _savePermissionGranted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /// Android only: checks whether Health Connect is installed and ready.
  static Future<HealthConnectAvailability> checkAndroidAvailability() async {
    if (!Platform.isAndroid) return HealthConnectAvailability.available;
    try {
      final status = await _health.getHealthConnectSdkStatus();
      _log('healthConnectSdkStatus → ${status?.name}');
      if (status == HealthConnectSdkStatus.sdkAvailable) {
        return HealthConnectAvailability.available;
      }
      if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        return HealthConnectAvailability.notInstalled;
      }
      return HealthConnectAvailability.notSupported;
    } catch (e) {
      _log('checkAndroidAvailability error: $e');
      return HealthConnectAvailability.notInstalled;
    }
  }

  /// Opens Health Connect so the user can manage permissions.
  static Future<void> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _health.installHealthConnect();
    } catch (e) {
      _log('openHealthConnectSettings error: $e');
    }
  }

  /// Opens Health Connect install page on Play Store.
  static Future<void> installOrOpenHealthConnect() async {
    if (!Platform.isAndroid) return;
    try {
      await _health.installHealthConnect();
    } catch (e) {
      _log('installOrOpenHealthConnect error: $e');
    }
  }

  /// Requests read permissions from Health Connect / Apple Health.
  /// Saves the result so we never show the dialog again once granted.
  static Future<bool> requestPermissions() async {
    try {
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();
      final granted = await _health.requestAuthorization(_types, permissions: permissions);
      _log('requestPermissions → $granted');
      if (granted) {
        await _savePermissionGranted(true);
      }
      return granted;
    } catch (e) {
      _log('requestPermissions error: $e');
      return false;
    }
  }

  /// Clears the stored permission flag (e.g. when the user revokes from system settings).
  static Future<void> clearPermissionCache() async {
    await _savePermissionGranted(false);
  }

  // ── Last sync persistence ──────────────────────────────────────────────────

  static const _lastSyncTimeKey = 'health_last_sync_time';
  static const _lastSyncResultKey = 'health_last_sync_result';

  static Future<void> saveLastSync({required String result}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimeKey, DateTime.now().toIso8601String());
    await prefs.setString(_lastSyncResultKey, result);
  }

  static Future<({DateTime? time, String? result})> loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastSyncTimeKey);
    final result = prefs.getString(_lastSyncResultKey);
    final time = timeStr != null ? DateTime.tryParse(timeStr) : null;
    return (time: time, result: result);
  }

  static Future<void> clearLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncTimeKey);
    await prefs.remove(_lastSyncResultKey);
  }

  /// Reads today's steps, calories burned, and active minutes from the device.
  /// Returns null if the read fails (e.g. permissions revoked).
  static Future<DeviceHealthData?> readToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final steps = await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;

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
      final activeMinutes = calories > 0 ? (calories / 3.5).round() : 0;

      final result = DeviceHealthData(
        steps: steps,
        caloriesBurned: calories,
        activeMinutes: activeMinutes,
      );
      _log('readToday — steps: $steps, cal: ${calories.toStringAsFixed(0)}, active: ${activeMinutes}min');
      return result;
    } catch (e) {
      _log('readToday error: $e');
      // If read fails, the permission may have been revoked — clear the cache
      await _savePermissionGranted(false);
      return null;
    }
  }

  static void _log(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·HealthSync');
  }
}
