enum MealSource { manual, photo, barcode }

extension MealSourceLabel on MealSource {
  String get label => switch (this) {
        MealSource.manual => 'Manual',
        MealSource.photo => 'Photo',
        MealSource.barcode => 'Barcode',
      };
}

MealSource _sourceFromApi(String v) => switch (v) {
      'photo' => MealSource.photo,
      'barcode' => MealSource.barcode,
      _ => MealSource.manual,
    };

String _inferMealType() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 15) return 'lunch';
  if (hour >= 15 && hour < 20) return 'dinner';
  return 'snack';
}

class MealLog {
  const MealLog({
    required this.id,
    required this.foodName,
    required this.servingDescription,
    required this.servings,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.loggedAt,
    required this.source,
  });

  final String id;
  final String foodName;
  final String servingDescription;
  final double servings;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime loggedAt;
  final MealSource source;

  Map<String, dynamic> toApiCreateBody({String? foodItemId}) => {
        'foodItemId': ?foodItemId,
        'name': foodName,
        'mealType': _inferMealType(),
        'quantity': servings,
        'servingUnit': 'serving',
        'calories': calories,
        'protein': proteinG,
        'carbs': carbsG,
        'fat': fatG,
        'source': source.name,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory MealLog.fromApiJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num? ?? 1).toDouble();
    final unit = json['servingUnit'] as String? ?? 'serving';
    return MealLog(
      id: json['id'] as String,
      foodName: json['name'] as String,
      servingDescription: '${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 1)} $unit',
      servings: quantity,
      calories: (json['calories'] as num? ?? 0).toDouble(),
      proteinG: (json['protein'] as num? ?? 0).toDouble(),
      carbsG: (json['carbs'] as num? ?? 0).toDouble(),
      fatG: (json['fat'] as num? ?? 0).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      source: _sourceFromApi(json['source'] as String? ?? 'manual'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodName': foodName,
        'servingDescription': servingDescription,
        'servings': servings,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'loggedAt': loggedAt.toIso8601String(),
        'source': source.name,
      };

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
        id: json['id'] as String,
        foodName: json['foodName'] as String,
        servingDescription: json['servingDescription'] as String,
        servings: (json['servings'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
        proteinG: (json['proteinG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        source: MealSource.values.byName(json['source'] as String),
      );
}
