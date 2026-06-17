import 'dart:io';

import '../../../core/services/api_client.dart';

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

  factory HealthSummaryDay.fromJson(Map<String, dynamic> json) => HealthSummaryDay(
        date: DateTime.parse(json['date'] as String),
        steps: json['steps'] as int? ?? 0,
        caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
        activeMinutes: json['activeMinutes'] as int? ?? 0,
        source: json['source'] as String? ?? 'manual',
      );
}

class HealthApiService {
  HealthApiService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<void> syncHealthData({
    required DateTime date,
    required int steps,
    required double caloriesBurned,
    required int activeMinutes,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _api.post('/health/sync', body: {
      'date': dateStr,
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'activeMinutes': activeMinutes,
      'source': Platform.isIOS ? 'apple_health' : 'google_fit',
    });
  }

  Future<List<HealthSummaryDay>> getSummary({int days = 7}) async {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';

    final data = await _api.get('/health/summary', query: {'from': fromStr}) as Map<String, dynamic>;
    final logs = (data['logs'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return logs.map(HealthSummaryDay.fromJson).toList();
  }
}
