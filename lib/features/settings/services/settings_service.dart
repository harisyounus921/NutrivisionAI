import '../../../core/services/api_client.dart';

class SettingsService {
  SettingsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<bool> loadMealRemindersEnabled() async {
    try {
      final data = await _api.get('/settings/reminders') as Map<String, dynamic>?;
      return data?['remindersEnabled'] as bool? ?? false;
    } on ApiException {
      return false;
    }
  }

  Future<void> saveMealRemindersEnabled(bool value) async {
    await _api.put('/settings/reminders', body: {'remindersEnabled': value});
  }
}
