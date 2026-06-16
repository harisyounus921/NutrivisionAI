import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../models/meal_log.dart';
import '../services/meal_log_service.dart';

class MealLogProvider extends ChangeNotifier {
  MealLogProvider({MealLogService? mealLogService})
      : _mealLogService = mealLogService ?? MealLogService();

  final MealLogService _mealLogService;

  List<MealLog> _logs = [];
  bool _isLoading = false;

  List<MealLog> get logs => _logs;
  bool get isLoading => _isLoading;

  List<MealLog> get todayLogs =>
      _logs.where((log) => _isSameDay(log.loggedAt, DateTime.now())).toList();

  double get todayCalories => _sum(todayLogs, (log) => log.calories);
  double get todayProtein => _sum(todayLogs, (log) => log.proteinG);
  double get todayCarbs => _sum(todayLogs, (log) => log.carbsG);
  double get todayFat => _sum(todayLogs, (log) => log.fatG);

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
    _d('loadLogs — GET /meals (last 7 days)');
    _isLoading = true;
    notifyListeners();

    try {
      _logs = await _mealLogService.loadLogs();
      _d('loadLogs — loaded ${_logs.length} logs (${todayLogs.length} today)');
    } catch (e) {
      _d('loadLogs — error: $e');
      _logs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(MealLog log, {String? foodItemId}) async {
    _d('addLog — POST /meals: "${log.foodName}"  foodItemId=$foodItemId');
    final saved = await _mealLogService.addLog(log, foodItemId: foodItemId);
    _logs = [..._logs, saved];
    _d('addLog — saved with id=${saved.id}');
    notifyListeners();
  }

  Future<void> removeLog(String id) async {
    _d('removeLog — DELETE /meals/$id');
    try {
      await _mealLogService.deleteLog(id);
      _logs = _logs.where((log) => log.id != id).toList();
      _d('removeLog — deleted, ${_logs.length} logs remaining');
      notifyListeners();
    } catch (e) {
      _d('removeLog — error: $e (item kept in list)');
    }
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·MealLog');
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _sum(List<MealLog> logs, double Function(MealLog log) selector) =>
      logs.fold(0, (total, log) => total + selector(log));
}
