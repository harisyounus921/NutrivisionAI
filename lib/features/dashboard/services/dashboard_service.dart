import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';

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
  Future<DailyData> getDaily() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final meals =
        await FirebaseBackend.userCollection(FirebaseCollections.mealsPath)
            .where('loggedAt', isGreaterThanOrEqualTo: today.toIso8601String())
            .where('loggedAt', isLessThan: tomorrow.toIso8601String())
            .get();

    final healthDoc = await FirebaseBackend.userCollection(
      FirebaseCollections.healthSummariesPath,
    ).doc(_dateKey(today)).get();
    final health = healthDoc.data() ?? {};

    final totals = meals.docs.fold<Map<String, double>>(
      {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
      (sum, doc) {
        final data = doc.data();
        sum['calories'] =
            sum['calories']! + (data['calories'] as num? ?? 0).toDouble();
        sum['protein'] =
            sum['protein']! + (data['protein'] as num? ?? 0).toDouble();
        sum['carbs'] = sum['carbs']! + (data['carbs'] as num? ?? 0).toDouble();
        sum['fat'] = sum['fat']! + (data['fat'] as num? ?? 0).toDouble();
        return sum;
      },
    );

    final caloriesBurned = (health['caloriesBurned'] as num? ?? 0).toDouble();
    return DailyData.fromJson({
      'totals': totals,
      'goals': {},
      'caloriesBurned': caloriesBurned,
      'netCalories': totals['calories']! - caloriesBurned,
    });
  }

  Future<List<RangeDayData>> getRange() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final meals = await FirebaseBackend.userCollection(
      FirebaseCollections.mealsPath,
    ).where('loggedAt', isGreaterThanOrEqualTo: start.toIso8601String()).get();
    final health = await FirebaseBackend.userCollection(
      FirebaseCollections.healthSummariesPath,
    ).where('date', isGreaterThanOrEqualTo: _dateKey(start)).get();

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final next = day.add(const Duration(days: 1));
      final calories = meals.docs
          .where((doc) {
            final loggedAt = DateTime.tryParse(
              doc.data()['loggedAt'] as String? ?? '',
            );
            return loggedAt != null &&
                !loggedAt.isBefore(day) &&
                loggedAt.isBefore(next);
          })
          .fold<double>(
            0,
            (sum, doc) =>
                sum + (doc.data()['calories'] as num? ?? 0).toDouble(),
          );
      final healthDoc = health.docs
          .where((doc) => doc.id == _dateKey(day))
          .firstOrNull;
      return RangeDayData(
        date: day,
        calories: calories,
        caloriesBurned: (healthDoc?.data()['caloriesBurned'] as num? ?? 0)
            .toDouble(),
      );
    });
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
