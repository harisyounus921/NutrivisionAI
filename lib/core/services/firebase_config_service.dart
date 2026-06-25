import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_collections.dart';

class MealNudgeFirebaseConfig {
  const MealNudgeFirebaseConfig({
    this.openAiApiKey = '',
    this.imagenApiKey = '',
    this.gptEnabled = false,
  });

  final String openAiApiKey;
  final String imagenApiKey;
  final bool gptEnabled;

  bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  bool get hasImagenKey => imagenApiKey.isNotEmpty;
}

class FirebaseConfigService {
  Future<MealNudgeFirebaseConfig> loadApiKeysConfig() async {
    final snapshot = await FirebaseCollections.apiKeysDoc.get();
    final data = snapshot.data();
    if (data == null) return const MealNudgeFirebaseConfig();

    return MealNudgeFirebaseConfig(
      openAiApiKey: data['openai_api_key'] as String? ?? '',
      imagenApiKey: data['imagen_api_key'] as String? ?? '',
      gptEnabled: data['gpt_enable'] == true,
    );
  }

  Future<Map<String, dynamic>?> loadAppVersionConfig() async {
    final snapshot = await FirebaseCollections.appVersionDoc.get();
    return snapshot.data();
  }

  Future<void> ensureDefaultConfigDocs() async {
    await FirebaseCollections.apiKeysDoc.set({
      'openai_api_key': '',
      'imagen_api_key': '',
      'gpt_enable': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseCollections.appVersionDoc.set({
      'android': {
        'min_version': '1.0.0',
        'min_build_number': 1,
        'latest_version': '1.0.0',
        'latest_build_number': 1,
        'force_update': false,
        'update_message':
            'A new version is available. Update now for the best experience.',
        'store_url':
            'https://play.google.com/store/apps/details?id=com.haris.mealnudge',
      },
      'ios': {
        'min_version': '1.0.0',
        'min_build_number': 1,
        'latest_version': '1.0.0',
        'latest_build_number': 1,
        'force_update': false,
        'update_message':
            'A new version is available. Update now for the best experience.',
        'store_url': 'https://apps.apple.com/app/mealnudge',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseCollections.mealNudgeLimitsDoc.set({
      'daily_meal_photo_limit': 20,
      'daily_coach_message_limit': 50,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
