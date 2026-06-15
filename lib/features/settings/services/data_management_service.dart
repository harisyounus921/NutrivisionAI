import '../../coach/services/chat_service.dart';
import '../../food/services/meal_log_service.dart';
import '../../health/services/activity_log_service.dart';
import '../../profile/services/profile_service.dart';

/// Data export/deletion for FR-15 (UC-12): gathers everything stored locally
/// into a single JSON-able map, or wipes the per-feature logs and chat
/// history. Profile and session are left to [ProfileProvider.clearProfile]
/// and [AuthProvider.logout] respectively, which already manage their own
/// in-memory state.
class DataManagementService {
  DataManagementService({
    ProfileService? profileService,
    MealLogService? mealLogService,
    ActivityLogService? activityLogService,
    ChatService? chatService,
  })  : _profileService = profileService ?? ProfileService(),
        _mealLogService = mealLogService ?? MealLogService(),
        _activityLogService = activityLogService ?? ActivityLogService(),
        _chatService = chatService ?? ChatService();

  final ProfileService _profileService;
  final MealLogService _mealLogService;
  final ActivityLogService _activityLogService;
  final ChatService _chatService;

  Future<Map<String, dynamic>> exportAll() async {
    final profile = await _profileService.loadProfile();
    final mealLogs = await _mealLogService.loadLogs();
    final activityLogs = await _activityLogService.loadLogs();
    final chatMessages = await _chatService.loadMessages();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'mealLogs': mealLogs.map((log) => log.toJson()).toList(),
      'activityLogs': activityLogs.map((log) => log.toJson()).toList(),
      'chatMessages': chatMessages.map((message) => message.toJson()).toList(),
    };
  }

  Future<void> deleteAll() async {
    await _mealLogService.clearLogs();
    await _activityLogService.clearLogs();
    await _chatService.clearMessages();
  }
}
