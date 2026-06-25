import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCollections {
  FirebaseCollections._();

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static const usersPath = 'users';
  static const guestUsersPath = 'guest_users';
  static const contentPath = 'content';
  static const notificationsPath = 'notifications';
  static const chatHeadPath = 'chat_head';
  static const referralsPath = 'refral';
  static const configPath = 'config';
  static const foodsPath = 'foods';
  static const barcodesPath = 'barcodes';

  static const apiKeysDocument = 'api_keys';
  static const appVersionDocument = 'app_version';
  static const mealNudgeLimitsDocument = 'mealnudge_limits';

  static const privatePath = 'private';
  static const profileDocument = 'profile';
  static const settingsDocument = 'settings';
  static const mealsPath = 'meals';
  static const healthSummariesPath = 'healthSummaries';
  static const conversationsPath = 'conversations';
  static const messagesPath = 'messages';

  static CollectionReference<Map<String, dynamic>> get users =>
      db.collection(usersPath);

  static CollectionReference<Map<String, dynamic>> get guestUsers =>
      db.collection(guestUsersPath);

  static CollectionReference<Map<String, dynamic>> get content =>
      db.collection(contentPath);

  static CollectionReference<Map<String, dynamic>> get notifications =>
      db.collection(notificationsPath);

  static CollectionReference<Map<String, dynamic>> get chatHead =>
      db.collection(chatHeadPath);

  static CollectionReference<Map<String, dynamic>> get referrals =>
      db.collection(referralsPath);

  static CollectionReference<Map<String, dynamic>> get config =>
      db.collection(configPath);

  static CollectionReference<Map<String, dynamic>> get foods =>
      db.collection(foodsPath);

  static CollectionReference<Map<String, dynamic>> get barcodes =>
      db.collection(barcodesPath);

  static DocumentReference<Map<String, dynamic>> get apiKeysDoc =>
      config.doc(apiKeysDocument);

  static DocumentReference<Map<String, dynamic>> get appVersionDoc =>
      config.doc(appVersionDocument);

  static DocumentReference<Map<String, dynamic>> get mealNudgeLimitsDoc =>
      config.doc(mealNudgeLimitsDocument);

  static String foodPhotoStoragePath(String userId, String filename) {
    return '$usersPath/$userId/food_photos/$filename';
  }
}
