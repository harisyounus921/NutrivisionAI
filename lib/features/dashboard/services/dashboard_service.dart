import '../../../core/services/api_client.dart';

class DailyData {
  const DailyData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.caloriesBurned,
    required this.netCalories,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? calorieGoal;
  final double? proteinGoal;
  final double? carbsGoal;
  final double? fatGoal;
  final double caloriesBurned;
  final double netCalories;

  factory DailyData.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final goals = json['goals'] as Map<String, dynamic>? ?? {};
    return DailyData(
      calories: (totals['calories'] as num? ?? 0).toDouble(),
      protein: (totals['protein'] as num? ?? 0).toDouble(),
      carbs: (totals['carbs'] as num? ?? 0).toDouble(),
      fat: (totals['fat'] as num? ?? 0).toDouble(),
      calorieGoal: (goals['calories'] as num?)?.toDouble(),
      proteinGoal: (goals['protein'] as num?)?.toDouble(),
      carbsGoal: (goals['carbs'] as num?)?.toDouble(),
      fatGoal: (goals['fat'] as num?)?.toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
      netCalories: (json['netCalories'] as num? ?? 0).toDouble(),
    );
  }
}

class RangeDayData {
  const RangeDayData({
    required this.date,
    required this.calories,
    required this.caloriesBurned,
  });

  final DateTime date;
  final double calories;
  final double caloriesBurned;

  factory RangeDayData.fromJson(Map<String, dynamic> json) => RangeDayData(
        date: DateTime.parse(json['date'] as String),
        calories: (json['calories'] as num? ?? 0).toDouble(),
        caloriesBurned: (json['caloriesBurned'] as num? ?? 0).toDouble(),
      );
}

class DashboardService {
  DashboardService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<DailyData> getDaily() async {
    final data = await _api.get('/dashboard/daily') as Map<String, dynamic>;
    return DailyData.fromJson(data);
  }

  Future<List<RangeDayData>> getRange() async {
    final data = await _api.get('/dashboard/range') as Map<String, dynamic>;
    final days = (data['days'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return days.map(RangeDayData.fromJson).toList();
  }
}
