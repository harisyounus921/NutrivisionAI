import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_exception.dart';
import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';

class SettingsService {
  Future<bool> loadMealRemindersEnabled() async {
    try {
      final doc = await FirebaseBackend.userDoc()
          .collection(FirebaseCollections.privatePath)
          .doc(FirebaseCollections.settingsDocument)
          .get();
      final data = doc.data();
      return data?['remindersEnabled'] as bool? ?? false;
    } on ApiException {
      return false;
    }
  }

  Future<void> saveMealRemindersEnabled(bool value) async {
    await FirebaseBackend.userDoc()
        .collection(FirebaseCollections.privatePath)
        .doc(FirebaseCollections.settingsDocument)
        .set({
          'remindersEnabled': value,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }
}
