enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum DietGoal { lose, maintain, gain }

enum DietaryPreference { none, vegetarian, halal, glutenFree }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
      };
}

extension ActivityLevelLabel on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary (little or no exercise)',
        ActivityLevel.light => 'Light (1-3 days/week)',
        ActivityLevel.moderate => 'Moderate (3-5 days/week)',
        ActivityLevel.active => 'Active (6-7 days/week)',
        ActivityLevel.veryActive => 'Very active (hard exercise / physical job)',
      };

  /// Multiplier applied to BMR to estimate total daily energy expenditure.
  double get multiplier => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };
}

extension DietGoalLabel on DietGoal {
  String get label => switch (this) {
        DietGoal.lose => 'Lose weight',
        DietGoal.maintain => 'Maintain weight',
        DietGoal.gain => 'Gain muscle',
      };

  /// Daily calorie adjustment applied on top of TDEE for this goal.
  int get calorieAdjustment => switch (this) {
        DietGoal.lose => -500,
        DietGoal.maintain => 0,
        DietGoal.gain => 500,
      };
}

extension DietaryPreferenceLabel on DietaryPreference {
  String get label => switch (this) {
        DietaryPreference.none => 'No restrictions',
        DietaryPreference.vegetarian => 'Vegetarian',
        DietaryPreference.halal => 'Halal',
        DietaryPreference.glutenFree => 'Gluten-free',
      };
}

class UserProfile {
  const UserProfile({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.dietaryPreference,
    this.allergies = const [],
  });

  final int age;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final DietGoal goal;
  final DietaryPreference dietaryPreference;
  final List<String> allergies;

  /// Basal Metabolic Rate via the Mifflin-St Jeor equation.
  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  /// Total Daily Energy Expenditure: BMR adjusted for activity level.
  double get tdee => bmr * activityLevel.multiplier;

  /// Suggested daily calorie target based on TDEE and the user's goal.
  int get dailyCalorieGoal => (tdee + goal.calorieAdjustment).round();

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender.name,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel.name,
        'goal': goal.name,
        'dietaryPreference': dietaryPreference.name,
        'allergies': allergies,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        age: json['age'] as int,
        gender: Gender.values.byName(json['gender'] as String),
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        activityLevel: ActivityLevel.values.byName(json['activityLevel'] as String),
        goal: DietGoal.values.byName(json['goal'] as String),
        dietaryPreference: DietaryPreference.values.byName(json['dietaryPreference'] as String),
        allergies: (json['allergies'] as List<dynamic>).cast<String>(),
      );
}
