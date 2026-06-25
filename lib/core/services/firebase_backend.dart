import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_exception.dart';
import 'firebase_collections.dart';

class FirebaseBackend {
  FirebaseBackend._();

  static bool get isConfigured => Firebase.apps.isNotEmpty;

  static FirebaseAuth get auth {
    _ensureConfigured();
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore get db {
    _ensureConfigured();
    return FirebaseFirestore.instance;
  }

  static User get currentUser {
    final user = auth.currentUser;
    if (user == null) {
      throw const ApiException('Please log in again.');
    }
    return user;
  }

  static DocumentReference<Map<String, dynamic>> userDoc([String? uid]) {
    final userId = uid ?? currentUser.uid;
    return FirebaseCollections.users.doc(userId);
  }

  static CollectionReference<Map<String, dynamic>> userCollection(String path) {
    return userDoc().collection(path);
  }

  static void _ensureConfigured() {
    if (!isConfigured) {
      throw const ApiException(
        'Firebase is not configured. Run flutterfire configure and add the generated Firebase files.',
      );
    }
  }
}
