import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';

class HealthSummaryDay {
  const HealthSummaryDay({
    required this.date,
    required this.steps,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.source,
  });

  final DateTime date;
  final int steps;
  final double caloriesBurned;
  final int activeMinutes;
  final String source;

  factory HealthSummaryDay.fromJson(Map<String, dynamic> json) =>
      HealthSummaryDay(
        date: DateTime.parse(json['date'] as String),
        steps: json['steps'] as int? ?? 0,
        caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
        activeMinutes: json['activeMinutes'] as int? ?? 0,
        source: json['source'] as String? ?? 'manual',
      );
}

class HealthApiService {
  Future<void> syncHealthData({
    required DateTime date,
    required int steps,
    required double caloriesBurned,
    required int activeMinutes,
  }) async {
    final dateStr = _dateKey(date);
    final doc = FirebaseBackend.userCollection(
      FirebaseCollections.healthSummariesPath,
    ).doc(dateStr);
    final existing = (await doc.get()).data() ?? <String, dynamic>{};

    final manualSteps = _existingManualSteps(existing);
    final manualCalories = _existingManualCalories(existing);
    final manualActiveMinutes = _existingManualActiveMinutes(existing);
    final source = Platform.isIOS ? 'apple_health' : 'health_connect';

    await doc.set({
      'date': dateStr,
      'manualSteps': manualSteps,
      'manualCaloriesBurned': manualCalories,
      'manualActiveMinutes': manualActiveMinutes,
      'deviceSteps': steps,
      'deviceCaloriesBurned': caloriesBurned,
      'deviceActiveMinutes': activeMinutes,
      'steps': manualSteps + steps,
      'caloriesBurned': manualCalories + caloriesBurned,
      'activeMinutes': manualActiveMinutes + activeMinutes,
      'source': _sourceFor(
        manualSteps: manualSteps,
        manualCalories: manualCalories,
        deviceSteps: steps,
        deviceCalories: caloriesBurned,
        deviceSource: source,
      ),
      'deviceSource': source,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<HealthSummaryDay>> getSummary({int days = 7}) async {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final fromStr = _dateKey(from);

    final snapshot =
        await FirebaseBackend.userCollection(
              FirebaseCollections.healthSummariesPath,
            )
            .where('date', isGreaterThanOrEqualTo: fromStr)
            .orderBy('date', descending: false)
            .get();
    return snapshot.docs
        .map((doc) => HealthSummaryDay.fromJson(doc.data()))
        .toList();
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _existingManualSteps(Map<String, dynamic> data) {
    final manual = data['manualSteps'] as num?;
    if (manual != null) return manual.toInt();
    return data['source'] == 'manual'
        ? (data['steps'] as num? ?? 0).toInt()
        : 0;
  }

  double _existingManualCalories(Map<String, dynamic> data) {
    final manual = data['manualCaloriesBurned'] as num?;
    if (manual != null) return manual.toDouble();
    return data['source'] == 'manual'
        ? (data['caloriesBurned'] as num? ?? 0).toDouble()
        : 0;
  }

  int _existingManualActiveMinutes(Map<String, dynamic> data) {
    final manual = data['manualActiveMinutes'] as num?;
    if (manual != null) return manual.toInt();
    return data['source'] == 'manual'
        ? (data['activeMinutes'] as num? ?? 0).toInt()
        : 0;
  }

  String _sourceFor({
    required int manualSteps,
    required double manualCalories,
    required int deviceSteps,
    required double deviceCalories,
    required String deviceSource,
  }) {
    final hasManual = manualSteps > 0 || manualCalories > 0;
    final hasDevice = deviceSteps > 0 || deviceCalories > 0;
    if (hasManual && hasDevice) return 'combined';
    if (hasDevice) return deviceSource;
    return 'manual';
  }
}
