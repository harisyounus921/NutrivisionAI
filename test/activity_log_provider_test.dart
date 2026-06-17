import 'package:flutter_test/flutter_test.dart';

import 'package:ai_diet/features/health/providers/activity_log_provider.dart';

void main() {
  group('ActivityLogProvider device sync totals', () {
    test('todaySteps reflects synced device steps (no manual logs)', () {
      final provider = ActivityLogProvider();
      expect(provider.todaySteps, 0);

      provider.setDeviceData(steps: 197, caloriesBurned: 0);

      expect(provider.todaySteps, 197);
      expect(provider.todayCaloriesBurned, 0);
    });

    test('todayCaloriesBurned reflects synced device calories', () {
      final provider = ActivityLogProvider();

      provider.setDeviceData(steps: 500, caloriesBurned: 120);

      expect(provider.todaySteps, 500);
      expect(provider.todayCaloriesBurned, 120);
    });

    test('device data from a previous day is not counted as today', () {
      final provider = ActivityLogProvider();

      provider.setDeviceData(
        steps: 9999,
        caloriesBurned: 300,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(provider.todaySteps, 0);
      expect(provider.todayCaloriesBurned, 0);
    });

    test('setDeviceData notifies listeners', () {
      final provider = ActivityLogProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.setDeviceData(steps: 100, caloriesBurned: 10);

      expect(notified, 1);
    });
  });
}
