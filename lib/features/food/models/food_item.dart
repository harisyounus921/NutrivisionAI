class FoodItem {
  const FoodItem({
    this.id,
    required this.name,
    required this.servingDescription,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String? id;
  final String name;
  final String servingDescription;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory FoodItem.fromApiJson(Map<String, dynamic> json) {
    final size = (json['servingSize'] as num?)?.toStringAsFixed(0) ?? '1';
    final unit = json['servingUnit'] as String? ?? 'serving';
    return FoodItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      servingDescription: '$size $unit',
      calories: (json['calories'] as num).toDouble(),
      proteinG: (json['protein'] as num? ?? 0).toDouble(),
      carbsG: (json['carbs'] as num? ?? 0).toDouble(),
      fatG: (json['fat'] as num? ?? 0).toDouble(),
    );
  }
}
