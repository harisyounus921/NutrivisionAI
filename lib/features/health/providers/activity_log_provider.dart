import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../models/activity_log.dart';
import '../services/activity_log_service.dart';

class ActivityLogProvider extends ChangeNotifier {
  ActivityLogProvider({ActivityLogService? activityLogService})
      : _activityLogService = activityLogService ?? ActivityLogService();

  final ActivityLogService _activityLogService;

  List<ActivityLog> _logs = [];
  bool _isLoading = false;

  // Latest totals synced from the device (Health Connect / Apple Health). These
  // are NOT stored as ActivityLog entries, so they're kept here and folded into
  // today's totals — otherwise a sync (e.g. 197 steps) would show in the synced
  // banner/summary but the "Today's Steps" card would still read 0.
  int _deviceSteps = 0;
  double _deviceCaloriesBurned = 0;
  DateTime? _deviceDataDate;

  List<ActivityLog> get logs => _logs;
  bool get isLoading => _isLoading;

  List<ActivityLog> get todayLogs =>
      _logs.where((log) => _isSameDay(log.loggedAt, DateTime.now())).toList();

  bool get _deviceDataIsToday =>
      _deviceDataDate != null && _isSameDay(_deviceDataDate!, DateTime.now());

  double get todayCaloriesBurned =>
      _sum(todayLogs, (log) => log.caloriesBurned) +
      (_deviceDataIsToday ? _deviceCaloriesBurned : 0);

  int get todaySteps =>
      todayLogs.fold(0, (total, log) => total + log.steps) +
      (_deviceDataIsToday ? _deviceSteps : 0);

  /// Records the latest device-synced totals so today's steps/burned reflect a
  /// sync even though sync data isn't persisted as [ActivityLog] entries.
  /// [date] defaults to now; data is only counted while it's still today.
  void setDeviceData({
    required int steps,
    required double caloriesBurned,
    DateTime? date,
  }) {
    _deviceSteps = steps;
    _deviceCaloriesBurned = caloriesBurned;
    _deviceDataDate = date ?? DateTime.now();
    _d('setDeviceData — $steps steps, ${caloriesBurned.toStringAsFixed(0)} kcal');
    notifyListeners();
  }

  Future<void> loadLogs() async {
    _d('loadLogs — reading local activity log (SharedPreferences)');
    _isLoading = true;
    notifyListeners();

    try {
      _logs = await _activityLogService.loadLogs();
      _d('loadLogs — loaded ${_logs.length} logs (${todayLogs.length} today, $todaySteps steps)');
    } catch (e) {
      _d('loadLogs — error: $e');
      _logs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(ActivityLog log) async {
    _d('addLog — "${log.activityName}" ${log.caloriesBurned.toStringAsFixed(0)} kcal, ${log.steps} steps');
    _logs = [..._logs, log];
    await _activityLogService.saveLogs(_logs);
    notifyListeners();

    final day = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
    final dayLogs = _logs.where((l) => _isSameDay(l.loggedAt, day)).toList();
    _d('addLog — fire-and-forget POST /health/sync for ${day.toIso8601String().substring(0, 10)}');
    _activityLogService.syncDay(day, dayLogs).ignore();
  }

  Future<void> removeLog(String id) async {
    _d('removeLog — id=$id');
    final removed = _logs.firstWhere((log) => log.id == id);
    _logs = _logs.where((log) => log.id != id).toList();
    await _activityLogService.saveLogs(_logs);
    notifyListeners();

    final day = DateTime(removed.loggedAt.year, removed.loggedAt.month, removed.loggedAt.day);
    final dayLogs = _logs.where((l) => _isSameDay(l.loggedAt, day)).toList();
    _d('removeLog — fire-and-forget POST /health/sync for ${day.toIso8601String().substring(0, 10)}');
    _activityLogService.syncDay(day, dayLogs).ignore();
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Activity');
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _sum(List<ActivityLog> logs, double Function(ActivityLog log) selector) =>
      logs.fold(0, (total, log) => total + selector(log));
}
