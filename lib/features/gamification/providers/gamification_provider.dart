import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../services/gamification_service.dart';

class GamificationProvider extends ChangeNotifier {
  GamificationProvider({GamificationService? gamificationService})
      : _service = gamificationService ?? GamificationService();

  final GamificationService _service;

  StreakData? _streak;
  List<BadgeData> _badges = [];
  WeeklySummary? _weeklySummary;
  bool _isLoading = false;

  StreakData? get streak => _streak;
  List<BadgeData> get badges => _badges;
  WeeklySummary? get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _d('load — GET /gamification/streak + /badges + /weekly-summary (parallel)');
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getStreak(),
        _service.getBadges(),
        _service.getWeeklySummary(),
      ]);
      _streak = results[0] as StreakData;
      _badges = results[1] as List<BadgeData>;
      _weeklySummary = results[2] as WeeklySummary;
      final earned = _badges.where((b) => b.earned).length;
      _d('load — streak: ${_streak?.current}d, badges: $earned/${_badges.length} earned');
    } catch (e) {
      _d('load — error: $e (keeping stale data)');
    }

    _isLoading = false;
    notifyListeners();
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'NutriVision·Gamification');
  }
}
