import '../../../core/services/app_exception.dart';
import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';
import '../../coach/services/chat_service.dart';
import '../../health/services/activity_log_service.dart';
import '../../food/services/meal_log_service.dart';

class DataManagementService {
  Future<Map<String, dynamic>> exportAll() async {
    try {
      final user = FirebaseBackend.currentUser;
      final meals = await FirebaseBackend.userCollection(
        FirebaseCollections.mealsPath,
      ).get();
      final health = await FirebaseBackend.userCollection(
        FirebaseCollections.healthSummariesPath,
      ).get();
      final settings = await FirebaseBackend.userDoc()
          .collection(FirebaseCollections.privatePath)
          .doc(FirebaseCollections.settingsDocument)
          .get();
      final profile = await FirebaseBackend.userDoc()
          .collection(FirebaseCollections.privatePath)
          .doc(FirebaseCollections.profileDocument)
          .get();
      final data = {
        'user': {'id': user.uid, 'email': user.email},
        'profile': profile.data(),
        'settings': settings.data(),
        'meals': meals.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList(),
        'healthSummaries': health.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList(),
      };
      return {'exportedAt': DateTime.now().toIso8601String(), ...data};
    } on ApiException {
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'error': 'Export failed',
      };
    }
  }

  Future<void> deleteAll() async {
    await _deleteCollection(FirebaseCollections.mealsPath);
    await _deleteCollection(FirebaseCollections.healthSummariesPath);
    await _deleteCollection(FirebaseCollections.conversationsPath);
    await FirebaseBackend.userDoc()
        .collection(FirebaseCollections.privatePath)
        .doc(FirebaseCollections.settingsDocument)
        .delete();
    await FirebaseBackend.userDoc()
        .collection(FirebaseCollections.privatePath)
        .doc(FirebaseCollections.profileDocument)
        .delete();
    await MealLogService().clearLogs();
    await ActivityLogService().clearLogs();
    await ChatService().clearMessages();
    await FirebaseBackend.currentUser.delete();
  }

  Future<void> _deleteCollection(String path) async {
    final snapshot = await FirebaseBackend.userCollection(path).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
