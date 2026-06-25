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
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await FirebaseBackend.userCollection(
      FirebaseCollections.healthSummariesPath,
    ).doc(dateStr).set({
      'date': dateStr,
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'activeMinutes': activeMinutes,
      'source': Platform.isIOS ? 'apple_health' : 'google_fit',
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<HealthSummaryDay>> getSummary({int days = 7}) async {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final fromStr =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';

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
}
