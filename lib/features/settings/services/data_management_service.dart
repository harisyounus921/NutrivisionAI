import '../../../core/services/api_client.dart';
import '../../coach/services/chat_service.dart';
import '../../health/services/activity_log_service.dart';
import '../../food/services/meal_log_service.dart';

class DataManagementService {
  DataManagementService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> exportAll() async {
    try {
      final data = await _api.get('/settings/export');
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        ...?(data as Map<String, dynamic>?),
      };
    } on ApiException {
      return {'exportedAt': DateTime.now().toIso8601String(), 'error': 'Export failed'};
    }
  }

  Future<void> deleteAll() async {
    await _api.delete('/settings/account');
    await MealLogService().clearLogs();
    await ActivityLogService().clearLogs();
    await ChatService().clearMessages();
  }
}
