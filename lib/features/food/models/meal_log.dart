enum MealSource { manual, photo, barcode }

extension MealSourceLabel on MealSource {
  String get label => switch (this) {
        MealSource.manual => 'Manual',
        MealSource.photo => 'Photo',
        MealSource.barcode => 'Barcode',
      };
}

/// A single logged meal entry, with totals already scaled by [servings].
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
