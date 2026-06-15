import 'package:flutter/foundation.dart';

import '../models/meal_log.dart';
import '../services/meal_log_service.dart';

class MealLogProvider extends ChangeNotifier {
  final MealLogService _mealLogService = MealLogService();

  List<MealLog> _logs = [];
  bool _isLoading = false;

  List<MealLog> get logs => _logs;
  bool get isLoading => _isLoading;

  List<MealLog> get todayLogs => _logs.where((log) => _isSameDay(log.loggedAt, DateTime.now())).toList();

  double get todayCalories => _sum(todayLogs, (log) => log.calories);
  double get todayProtein => _sum(todayLogs, (log) => log.proteinG);
  double get todayCarbs => _sum(todayLogs, (log) => log.carbsG);
  double get todayFat => _sum(todayLogs, (log) => log.fatG);

  /// Total calories per day for the last 7 days (oldest to newest, including today).
  List<(DateTime day, double calories)> get last7DaysCalories {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return List.generate(7, (index) {
      final day = startOfToday.subtract(Duration(days: 6 - index));
      final dayLogs = _logs.where((log) => _isSameDay(log.loggedAt, day)).toList();
      return (day, _sum(dayLogs, (log) => log.calories));
    });
  }

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    _logs = await _mealLogService.loadLogs();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(MealLog log) async {
    _logs = [..._logs, log];
    await _mealLogService.saveLogs(_logs);
    notifyListeners();
  }

  Future<void> removeLog(String id) async {
    _logs = _logs.where((log) => log.id != id).toList();
    await _mealLogService.saveLogs(_logs);
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _sum(List<MealLog> logs, double Function(MealLog log) selector) {
    return logs.fold(0, (total, log) => total + selector(log));
  }
}
