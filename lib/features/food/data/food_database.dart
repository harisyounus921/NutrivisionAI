import '../models/food_item.dart';

/// Local seed food database used for manual search/logging until a nutrition
/// API (USDA/Edamam/Nutritionix) is integrated.
const List<FoodItem> foodDatabase = [
  FoodItem(name: 'Apple', servingDescription: '1 medium (182g)', calories: 95, proteinG: 0.5, carbsG: 25, fatG: 0.3),
  FoodItem(name: 'Banana', servingDescription: '1 medium (118g)', calories: 105, proteinG: 1.3, carbsG: 27, fatG: 0.4),
  FoodItem(name: 'Orange', servingDescription: '1 medium (131g)', calories: 62, proteinG: 1.2, carbsG: 15, fatG: 0.2),
  FoodItem(name: 'Boiled Egg', servingDescription: '1 large (50g)', calories: 78, proteinG: 6.3, carbsG: 0.6, fatG: 5.3),
  FoodItem(name: 'Grilled Chicken Breast', servingDescription: '100g', calories: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
  FoodItem(name: 'White Rice (cooked)', servingDescription: '1 cup (158g)', calories: 205, proteinG: 4.3, carbsG: 45, fatG: 0.4),
  FoodItem(name: 'Chicken Biryani', servingDescription: '1 plate (350g)', calories: 450, proteinG: 22, carbsG: 55, fatG: 14),
  FoodItem(name: 'Whole Wheat Roti', servingDescription: '1 piece (40g)', calories: 120, proteinG: 3, carbsG: 18, fatG: 3.5),
  FoodItem(name: 'Lentil Soup (Daal)', servingDescription: '1 bowl (250g)', calories: 230, proteinG: 12, carbsG: 35, fatG: 5),
  FoodItem(name: 'Greek Yogurt', servingDescription: '1 cup (245g)', calories: 150, proteinG: 20, carbsG: 9, fatG: 4),
  FoodItem(name: 'Almonds', servingDescription: '1 oz / 23 nuts (28g)', calories: 164, proteinG: 6, carbsG: 6, fatG: 14),
  FoodItem(name: 'Whole Milk', servingDescription: '1 cup (244g)', calories: 149, proteinG: 8, carbsG: 12, fatG: 8),
  FoodItem(name: 'Mixed Green Salad', servingDescription: '1 bowl (100g)', calories: 20, proteinG: 1.5, carbsG: 4, fatG: 0.2),
  FoodItem(name: 'Beef Burger', servingDescription: '1 burger (250g)', calories: 540, proteinG: 25, carbsG: 40, fatG: 30),
  FoodItem(name: 'Oatmeal', servingDescription: '1 cup cooked (234g)', calories: 158, proteinG: 6, carbsG: 27, fatG: 3),
];
