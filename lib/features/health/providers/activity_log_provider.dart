import 'package:flutter/foundation.dart';

import '../models/activity_log.dart';
import '../services/activity_log_service.dart';

class ActivityLogProvider extends ChangeNotifier {
  final ActivityLogService _activityLogService = ActivityLogService();

  List<ActivityLog> _logs = [];
  bool _isLoading = false;

  List<ActivityLog> get logs => _logs;
  bool get isLoading => _isLoading;

  List<ActivityLog> get todayLogs => _logs.where((log) => _isSameDay(log.loggedAt, DateTime.now())).toList();

  double get todayCaloriesBurned => _sum(todayLogs, (log) => log.caloriesBurned);
  int get todaySteps => todayLogs.fold(0, (total, log) => total + log.steps);

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    _logs = await _activityLogService.loadLogs();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(ActivityLog log) async {
    _logs = [..._logs, log];
    await _activityLogService.saveLogs(_logs);
    notifyListeners();
  }

  Future<void> removeLog(String id) async {
    _logs = _logs.where((log) => log.id != id).toList();
    await _activityLogService.saveLogs(_logs);
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _sum(List<ActivityLog> logs, double Function(ActivityLog log) selector) {
    return logs.fold(0, (total, log) => total + selector(log));
  }
}
