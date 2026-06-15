import '../../food/data/food_database.dart';
import '../../food/models/food_item.dart';
import '../../profile/models/user_profile.dart';

/// Snapshot of the user's profile and today's logged nutrition, used to
/// personalize the AI coach's replies.
class CoachContext {
  const CoachContext({
    required this.profile,
    required this.todayCalories,
    required this.todayProtein,
    required this.todayCarbs,
    required this.todayFat,
  });

  final UserProfile? profile;
  final double todayCalories;
  final double todayProtein;
  final double todayCarbs;
  final double todayFat;
}

const _meatKeywords = ['chicken', 'beef'];
const _glutenKeywords = ['roti', 'oatmeal'];

/// Generates rule-based replies for the AI diet coach, grounded in the
/// user's profile and today's logged nutrition.
///
/// Stands in for the GPT/Dialogflow-backed coach described in the README
/// until a real conversational AI backend is wired up.
class CoachResponseService {
  String reply(String message, CoachContext context) {
    final text = message.toLowerCase().trim();

    if (text.isEmpty) {
      return "I didn't quite catch that — could you rephrase?";
    }
    if (_matchesAny(text, ['hello', 'hi', 'hey'])) {
      return _greeting(context);
    }
    if (_matchesAny(text, ['thank'])) {
      return "You're welcome! Keep up the great work.";
    }
    if (_matchesAny(text, ['protein'])) {
      return _proteinAdvice(context);
    }
    if (_matchesAny(text, ['carb'])) {
      return _carbsAdvice(context);
    }
    if (_matchesAny(text, ['fat'])) {
      return _fatAdvice(context);
    }
    if (_matchesAny(text, ['suggest', 'recommend', 'should i eat', 'hungry', 'meal idea'])) {
      return _mealSuggestion(context);
    }
    if (_matchesAny(text, ['water', 'hydrat'])) {
      return 'Staying hydrated helps with energy and appetite control. Aim for about '
          '8 cups (2 liters) of water a day, more if you exercise.';
    }
    if (_matchesAny(text, ['calorie', 'progress', 'how am i doing', 'summary', 'today'])) {
      return _progressSummary(context);
    }

    return "I can help with your calorie goal, macros (protein/carbs/fat), and meal "
        'suggestions based on what you\'ve logged today. Try asking things like '
        '"How am I doing today?" or "What should I eat next?"';
  }

  bool _matchesAny(String text, List<String> keywords) => keywords.any(text.contains);

  String _greeting(CoachContext context) {
    final profile = context.profile;
    if (profile == null) {
      return "Hi! I'm your AI diet coach. Set up your profile so I can give you "
          'personalized guidance, then ask me about your progress or what to eat.';
    }
    return "Hi! I'm your AI diet coach. Ask me about your calories, macros, or "
        "what to eat next — I'll tailor it to your ${profile.goal.label.toLowerCase()} goal.";
  }

  String _progressSummary(CoachContext context) {
    final profile = context.profile;
    if (profile == null) {
      return 'Set up your profile to get a daily calorie goal, then I can track your progress.';
    }

    final goal = profile.dailyCalorieGoal;
    final remaining = goal - context.todayCalories;
    final consumed = context.todayCalories.toStringAsFixed(0);

    if (context.todayCalories == 0) {
      return "You haven't logged anything yet today. Your goal is $goal kcal — "
          'log a meal and I can give you tailored feedback.';
    }
    if (remaining > 0) {
      return "You've had $consumed of your $goal kcal goal — about "
          '${remaining.toStringAsFixed(0)} kcal left for the day. '
          'Protein: ${context.todayProtein.toStringAsFixed(0)}g, '
          'Carbs: ${context.todayCarbs.toStringAsFixed(0)}g, '
          'Fat: ${context.todayFat.toStringAsFixed(0)}g.';
    }
    return "You've had $consumed kcal, which is ${(-remaining).toStringAsFixed(0)} kcal "
        "over your $goal kcal goal. Consider a lighter option for your next meal, "
        'like a salad or some fruit.';
  }

  String _proteinAdvice(CoachContext context) {
    final profile = context.profile;
    if (profile == null) {
      return 'Set up your profile so I can estimate a protein target for you.';
    }

    final target = _targetProteinG(profile);
    final current = context.todayProtein;
    if (current >= target) {
      return "Nice! You've had ${current.toStringAsFixed(0)}g of protein today, "
          'meeting your ~${target.toStringAsFixed(0)}g target.';
    }

    final remaining = target - current;
    final suggestions = _suggestFoods(profile, sortBy: _proteinG, take: 2);
    final names = suggestions.map((food) => food.name).join(' or ');
    return "You've had ${current.toStringAsFixed(0)}g of protein, about "
        '${remaining.toStringAsFixed(0)}g short of your ~${target.toStringAsFixed(0)}g target.'
        '${names.isEmpty ? '' : ' Try $names to top it up.'}';
  }

  String _carbsAdvice(CoachContext context) {
    return "You've had ${context.todayCarbs.toStringAsFixed(0)}g of carbs today. "
        "Carbs are your body's main energy source — whole grains like Whole Wheat Roti, "
        'Oatmeal, or White Rice are good steady-energy choices.';
  }

  String _fatAdvice(CoachContext context) {
    return "You've had ${context.todayFat.toStringAsFixed(0)}g of fat today. "
        'Healthy fats from nuts, yogurt, and lean proteins support hormone health — '
        'just watch portion sizes since fat is calorie-dense.';
  }

  String _mealSuggestion(CoachContext context) {
    final profile = context.profile;
    if (profile == null) {
      return 'Set up your profile and log a meal so I can suggest food tailored to your goals.';
    }

    final remainingCalories = profile.dailyCalorieGoal - context.todayCalories;
    if (remainingCalories <= 0) {
      final light = _suggestFoods(profile, sortBy: _calories, take: 2, maxCalories: 150);
      final names = light.map((food) => food.name).join(' or ');
      return "You're at or over your calorie goal for today. If you're still hungry, "
          "${names.isEmpty ? 'try a light, low-calorie option.' : 'something light like $names would fit best.'}";
    }

    final target = _targetProteinG(profile);
    final lowOnProtein = context.todayProtein < target * 0.6;
    final candidates = _suggestFoods(
      profile,
      sortBy: lowOnProtein ? _proteinG : _calories,
      take: 2,
      maxCalories: remainingCalories,
    );

    if (candidates.isEmpty) {
      return "You've got about ${remainingCalories.toStringAsFixed(0)} kcal left today — "
          'a small snack like fruit or yogurt would fit well.';
    }

    final names = candidates.map((food) => food.name).join(' or ');
    final reason = lowOnProtein ? 'boost your protein' : 'fit your remaining calories';
    return "You've got about ${remainingCalories.toStringAsFixed(0)} kcal left today. "
        '$names would be great choices to $reason.';
  }

  double _targetProteinG(UserProfile profile) => profile.weightKg;

  double _proteinG(FoodItem item) => item.proteinG;
  double _calories(FoodItem item) => item.calories;

  List<FoodItem> _suggestFoods(
    UserProfile profile, {
    required double Function(FoodItem item) sortBy,
    required int take,
    double? maxCalories,
  }) {
    var candidates = foodDatabase.where((item) => _isAllowed(item, profile));
    if (maxCalories != null) {
      candidates = candidates.where((item) => item.calories <= maxCalories);
    }
    final sorted = candidates.toList()..sort((a, b) => sortBy(b).compareTo(sortBy(a)));
    return sorted.take(take).toList();
  }

  bool _isAllowed(FoodItem item, UserProfile profile) {
    final name = item.name.toLowerCase();
    for (final allergy in profile.allergies) {
      final trimmed = allergy.trim().toLowerCase();
      if (trimmed.isNotEmpty && name.contains(trimmed)) return false;
    }
    switch (profile.dietaryPreference) {
      case DietaryPreference.vegetarian:
        return !_meatKeywords.any(name.contains);
      case DietaryPreference.glutenFree:
        return !_glutenKeywords.any(name.contains);
      case DietaryPreference.halal:
      case DietaryPreference.none:
        return true;
    }
  }
}
