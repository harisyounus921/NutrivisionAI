import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardService? dashboardService})
    : _service = dashboardService ?? DashboardService();

  final DashboardService _service;

  DailyData? _daily;
  List<RangeDayData> _range = [];
  bool _isLoading = false;

  DailyData? get daily => _daily;
  List<RangeDayData> get range => _range;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _d('load — GET /dashboard/daily + GET /dashboard/range (parallel)');
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getDaily(),
        _service.getRange(),
      ]);
      _daily = results[0] as DailyData;
      _range = results[1] as List<RangeDayData>;
      _d(
        'load — daily: ${_daily?.calories.toStringAsFixed(0)} kcal, range: ${_range.length} days',
      );
    } catch (e) {
      _d('load — error: $e (keeping stale data)');
    }

    _isLoading = false;
    notifyListeners();
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'MealNudge·Dashboard');
  }
}
