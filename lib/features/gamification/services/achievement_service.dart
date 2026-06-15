import '../../food/models/meal_log.dart';
import '../../health/models/activity_log.dart';
import '../../profile/models/user_profile.dart';
import '../data/achievement_database.dart';
import '../models/achievement.dart';

/// Progress toward a single [Achievement], computed from the user's logs.
class AchievementProgress {
  const AchievementProgress({required this.achievement, required this.progress, required this.isUnlocked});

  final Achievement achievement;
  final int progress;
  final bool isUnlocked;
}

/// Snapshot of the user's streaks and badge progress (UC-10), derived
/// entirely from meal logs, activity logs, and the user's profile — no
/// separate gamification persistence is needed.
class GamificationSummary {
  const GamificationSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.achievements,
  });

  final int currentStreak;
  final int longestStreak;
  final List<AchievementProgress> achievements;

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;
}

class AchievementService {
  GamificationSummary evaluate({
    required List<MealLog> mealLogs,
    required List<ActivityLog> activityLogs,
    required UserProfile? profile,
  }) {
    final loggedDays = _loggedDays(mealLogs);
    final currentStreak = _currentStreak(loggedDays);
    final longestStreak = _longestStreak(loggedDays);
    final daysGoalHit = profile == null ? 0 : _daysGoalHit(mealLogs, loggedDays, profile.dailyCalorieGoal);

    final achievements = achievementDatabase.map((achievement) {
      final progress = switch (achievement.type) {
        AchievementType.mealCount => mealLogs.length,
        AchievementType.activityCount => activityLogs.length,
        AchievementType.streak => longestStreak,
        AchievementType.goalHit => daysGoalHit,
      };
      return AchievementProgress(
        achievement: achievement,
        progress: progress,
        isUnlocked: progress >= achievement.target,
      );
    }).toList();

    return GamificationSummary(currentStreak: currentStreak, longestStreak: longestStreak, achievements: achievements);
  }

  Set<DateTime> _loggedDays(List<MealLog> logs) {
    return logs.map((log) => _dateOnly(log.loggedAt)).toSet();
  }

  int _currentStreak(Set<DateTime> loggedDays) {
    var day = _dateOnly(DateTime.now());
    if (!loggedDays.contains(day)) {
      day = day.subtract(const Duration(days: 1));
      if (!loggedDays.contains(day)) return 0;
    }

    var streak = 0;
    while (loggedDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak(Set<DateTime> loggedDays) {
    var longest = 0;
    for (final day in loggedDays) {
      if (loggedDays.contains(day.subtract(const Duration(days: 1)))) continue;

      var length = 0;
      var current = day;
      while (loggedDays.contains(current)) {
        length++;
        current = current.add(const Duration(days: 1));
      }
      if (length > longest) longest = length;
    }
    return longest;
  }

  int _daysGoalHit(List<MealLog> logs, Set<DateTime> loggedDays, int goal) {
    var count = 0;
    for (final day in loggedDays) {
      final total = logs
          .where((log) => _dateOnly(log.loggedAt) == day)
          .fold<double>(0, (sum, log) => sum + log.calories);
      if (total >= goal * 0.9 && total <= goal * 1.1) count++;
    }
    return count;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
