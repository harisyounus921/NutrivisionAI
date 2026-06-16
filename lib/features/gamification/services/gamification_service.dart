import '../../../core/services/api_client.dart';

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
        earnedAt: json['earnedAt'] == null ? null : DateTime.parse(json['earnedAt'] as String),
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

  factory WeeklySummaryDay.fromJson(Map<String, dynamic> json) => WeeklySummaryDay(
        date: DateTime.parse(json['date'] as String),
        calories: (json['calories'] as num? ?? 0).toDouble(),
        calorieGoal: (json['calorieGoal'] as num?)?.toDouble(),
        withinGoal: json['withinGoal'] as bool?,
      );
}

class WeeklySummary {
  const WeeklySummary({required this.days, required this.streak, required this.badges});
  final List<WeeklySummaryDay> days;
  final StreakData streak;
  final List<BadgeData> badges;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
        days: ((json['days'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(WeeklySummaryDay.fromJson)
            .toList(),
        streak: StreakData.fromJson(
          json['streak'] as Map<String, dynamic>? ?? {},
        ),
        badges: ((json['badges'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>()
            .map((b) => BadgeData(
                  id: b['id'] as String? ?? '',
                  code: b['code'] as String? ?? '',
                  name: b['name'] as String? ?? '',
                  description: b['description'] as String?,
                  earned: true,
                ))
            .toList(),
      );
}

class GamificationService {
  GamificationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<StreakData> getStreak() async {
    final data = await _api.get('/gamification/streak') as Map<String, dynamic>;
    return StreakData.fromJson(data);
  }

  Future<List<BadgeData>> getBadges() async {
    final data = await _api.get('/gamification/badges') as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(BadgeData.fromJson).toList();
  }

  Future<WeeklySummary> getWeeklySummary() async {
    final data = await _api.get('/gamification/weekly-summary') as Map<String, dynamic>;
    return WeeklySummary.fromJson(data);
  }
}
