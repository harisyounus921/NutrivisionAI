import '../../../core/services/api_client.dart';
import '../models/user_profile.dart';

extension _ActivityLevelApi on ActivityLevel {
  String get apiValue => switch (this) {
        ActivityLevel.sedentary => 'sedentary',
        ActivityLevel.light => 'light',
        ActivityLevel.moderate => 'moderate',
        ActivityLevel.active => 'active',
        ActivityLevel.veryActive => 'very_active',
      };
}

ActivityLevel _activityFromApi(String v) => switch (v) {
      'very_active' => ActivityLevel.veryActive,
      _ => ActivityLevel.values.byName(v),
    };

extension _DietGoalApi on DietGoal {
  String get apiValue => switch (this) {
        DietGoal.lose => 'weight_loss',
        DietGoal.maintain => 'maintenance',
        DietGoal.gain => 'muscle_gain',
      };
}

DietGoal _goalFromApi(String v) => switch (v) {
      'weight_loss' => DietGoal.lose,
      'maintenance' => DietGoal.maintain,
      'muscle_gain' => DietGoal.gain,
      _ => DietGoal.maintain,
    };

extension _DietaryPrefApi on DietaryPreference {
  List<String> get apiList => switch (this) {
        DietaryPreference.none => [],
        DietaryPreference.vegetarian => ['vegetarian'],
        DietaryPreference.halal => ['halal'],
        DietaryPreference.glutenFree => ['gluten-free'],
      };
}

DietaryPreference _prefFromApiList(List<dynamic> list) {
  if (list.contains('vegetarian')) return DietaryPreference.vegetarian;
  if (list.contains('halal')) return DietaryPreference.halal;
  if (list.contains('gluten-free')) return DietaryPreference.glutenFree;
  return DietaryPreference.none;
}

class ProfileService {
  ProfileService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<UserProfile?> loadProfile() async {
    try {
      final data = await _api.get('/profile') as Map<String, dynamic>?;
      if (data == null) return null;

      final age = data['age'];
      final gender = data['gender'];
      final heightCm = data['heightCm'];
      final weightKg = data['weightKg'];
      final activityLevel = data['activityLevel'];
      final goal = data['goal'];

      if (age == null || gender == null || heightCm == null || weightKg == null) {
        return null;
      }

      return UserProfile(
        age: (age as num).toInt(),
        gender: Gender.values.byName(gender as String),
        heightCm: (heightCm as num).toDouble(),
        weightKg: (weightKg as num).toDouble(),
        activityLevel: _activityFromApi(activityLevel as String? ?? 'sedentary'),
        goal: _goalFromApi(goal as String? ?? 'maintenance'),
        dietaryPreference: _prefFromApiList(
          (data['dietaryPreferences'] as List<dynamic>?) ?? [],
        ),
        allergies: ((data['allergies'] as List<dynamic>?) ?? []).cast<String>(),
      );
    } on ApiException {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _api.put('/profile', body: {
      'age': profile.age,
      'gender': profile.gender.name,
      'heightCm': profile.heightCm,
      'weightKg': profile.weightKg,
      'activityLevel': profile.activityLevel.apiValue,
      'goal': profile.goal.apiValue,
      'dietaryPreferences': profile.dietaryPreference.apiList,
      'allergies': profile.allergies,
    });
  }

  Future<void> clearProfile() async {
  }
}
