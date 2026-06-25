import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';
import '../../food/models/meal_log.dart';
import 'achievement_service.dart';

class StreakData {
  const StreakData({required this.current, required this.longest});
  final int current;
  final int longest;

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
    current: json['currentStreak'] as int? ?? 0,
    longest: json['longestStreak'] as int? ?? 0,
  );
}

class BadgeData {
  const BadgeData({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.earned,
    this.earnedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool earned;
  final DateTime? earnedAt;

  factory BadgeData.fromJson(Map<String, dynamic> json) => BadgeData(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    earned: json['earned'] as bool? ?? false,
    earnedAt: json['earnedAt'] == null
        ? null
        : DateTime.parse(json['earnedAt'] as String),
  );
}

class WeeklySummaryDay {
  const WeeklySummaryDay({
    required this.date,
    required this.calories,
    required this.calorieGoal,
    required this.withinGoal,
  });

  final DateTime date;
  final double calories;
  final double? calorieGoal;
  final bool? withinGoal;

  factory WeeklySummaryDay.fromJson(Map<String, dynamic> json) =>
      WeeklySummaryDay(
        date: DateTime.parse(json['date'] as String),
        calories: (json['calories'] as num? ?? 0).toDouble(),
        calorieGoal: (json['calorieGoal'] as num?)?.toDouble(),
        withinGoal: json['withinGoal'] as bool?,
      );
}

class WeeklySummary {
  const WeeklySummary({
    required this.days,
    required this.streak,
    required this.badges,
  });
  final List<WeeklySummaryDay> days;
  final StreakData streak;
  final List<BadgeData> badges;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
    days: ((json['days'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(WeeklySummaryDay.fromJson)
        .toList(),
    streak: StreakData.fromJson(json['streak'] as Map<String, dynamic>? ?? {}),
    badges: ((json['badges'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (b) => BadgeData(
            id: b['id'] as String? ?? '',
            code: b['code'] as String? ?? '',
            name: b['name'] as String? ?? '',
            description: b['description'] as String?,
            earned: true,
          ),
        )
        .toList(),
  );
}

class GamificationService {
  final _achievementService = AchievementService();

  Future<StreakData> getStreak() async {
    final logs = await _loadMealLogs();
    final summary = _achievementService.evaluate(
      mealLogs: logs,
      activityLogs: const [],
      profile: null,
    );
    return StreakData(
      current: summary.currentStreak,
      longest: summary.longestStreak,
    );
  }

  Future<List<BadgeData>> getBadges() async {
    final logs = await _loadMealLogs();
    final summary = _achievementService.evaluate(
      mealLogs: logs,
      activityLogs: const [],
      profile: null,
    );
    return summary.achievements.map((progress) {
      final achievement = progress.achievement;
      return BadgeData(
        id: achievement.id,
        code: achievement.id,
        name: achievement.title,
        description: achievement.description,
        earned: progress.isUnlocked,
      );
    }).toList();
  }

  Future<WeeklySummary> getWeeklySummary() async {
    final logs = await _loadMealLogs();
    final streak = await getStreak();
    final badges = (await getBadges()).where((badge) => badge.earned).toList();
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final days = List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final total = logs
          .where((log) => _sameDay(log.loggedAt, day))
          .fold<double>(0, (sum, log) => sum + log.calories);
      return WeeklySummaryDay(
        date: day,
        calories: total,
        calorieGoal: null,
        withinGoal: null,
      );
    });
    return WeeklySummary(days: days, streak: streak, badges: badges);
  }

  Future<List<MealLog>> _loadMealLogs() async {
    final from = DateTime.now().subtract(const Duration(days: 30));
    final snapshot = await FirebaseBackend.userCollection(
      FirebaseCollections.mealsPath,
    ).where('loggedAt', isGreaterThanOrEqualTo: from.toIso8601String()).get();
    return snapshot.docs
        .map((doc) => MealLog.fromApiJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
