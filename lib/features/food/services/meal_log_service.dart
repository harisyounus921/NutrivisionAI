import '../../../core/services/api_client.dart';
import '../models/meal_log.dart';

class MealLogService {
  MealLogService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Loads meal logs for the last 8 days (covers today + 7-day trend).
  Future<List<MealLog>> loadLogs() async {
    final from = DateTime.now().subtract(const Duration(days: 7));
    final fromStr = DateTime(from.year, from.month, from.day).toIso8601String();

    final data = await _api.get('/meals', query: {'from': fromStr});
    if (data == null) return [];

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MealLog.fromApiJson)
        .toList();
  }

  /// Posts a new meal to the backend and returns the persisted log.
  Future<MealLog> addLog(MealLog log, {String? foodItemId}) async {
    final data = await _api.post(
      '/meals',
      body: log.toApiCreateBody(foodItemId: foodItemId),
    ) as Map<String, dynamic>;

    // Response is { mealLog: {...}, gamification: {...} }
    final mealLogJson = data['mealLog'] as Map<String, dynamic>? ?? data;
    return MealLog.fromApiJson(mealLogJson);
  }

  Future<void> deleteLog(String id) async {
    await _api.delete('/meals/$id');
  }

  Future<void> clearLogs() async {
    // Bulk clear is handled by DELETE /settings/account; no-op here.
  }
}
