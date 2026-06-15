/// A food and its nutrition values for one standard serving.
///
/// Sourced from a local seed database for now — will be replaced/augmented
/// by a nutrition API (USDA/Edamam/Nutritionix) once the backend is wired up.
class FoodItem {
  const FoodItem({
    required this.name,
    required this.servingDescription,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String name;
  final String servingDescription;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
