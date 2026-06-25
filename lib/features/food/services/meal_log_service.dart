import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';
import '../models/meal_log.dart';

class MealLogService {
  Future<List<MealLog>> loadLogs() async {
    final from = DateTime.now().subtract(const Duration(days: 7));
    final fromStr = DateTime(from.year, from.month, from.day).toIso8601String();
    final snapshot =
        await FirebaseBackend.userCollection(FirebaseCollections.mealsPath)
            .where('loggedAt', isGreaterThanOrEqualTo: fromStr)
            .orderBy('loggedAt', descending: true)
            .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MealLog.fromApiJson({...data, 'id': doc.id});
    }).toList();
  }

  Future<MealLog> addLog(MealLog log, {String? foodItemId}) async {
    final body = log.toApiCreateBody(foodItemId: foodItemId);
    final doc = await FirebaseBackend.userCollection(
      FirebaseCollections.mealsPath,
    ).add({...body, 'createdAt': DateTime.now().toIso8601String()});
    return MealLog.fromApiJson({...body, 'id': doc.id});
  }

  Future<void> deleteLog(String id) async {
    await FirebaseBackend.userCollection(
      FirebaseCollections.mealsPath,
    ).doc(id).delete();
  }

  Future<void> clearLogs() async {
    final snapshot = await FirebaseBackend.userCollection(
      FirebaseCollections.mealsPath,
    ).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
