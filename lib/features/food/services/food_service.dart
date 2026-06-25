import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';
import '../data/food_database.dart';
import '../models/food_item.dart';
import '../models/recognition_candidate.dart';

class FoodService {
  Future<List<FoodItem>> search(String query) async {
    if (query.trim().length < 2) return [];
    final q = query.trim().toLowerCase();
    final local = foodDatabase
        .where((food) => food.name.toLowerCase().contains(q))
        .toList();
    try {
      final remote = await FirebaseCollections.foods
          .where('searchTerms', arrayContains: q)
          .limit(20)
          .get();
      return [
        ...local,
        ...remote.docs.map(
          (doc) => FoodItem.fromApiJson({...doc.data(), 'id': doc.id}),
        ),
      ];
    } catch (_) {
      return local;
    }
  }

  Future<FoodItem?> lookupBarcode(String barcode) async {
    final doc = await FirebaseCollections.barcodes.doc(barcode).get();
    final data = doc.data();
    return data == null ? null : FoodItem.fromApiJson(data);
  }

  Future<List<RecognitionCandidate>> recognizePhoto(
    List<int> imageBytes, {
    String filename = 'photo.jpg',
  }) async {
    final user = FirebaseBackend.currentUser;
    final storageFilename =
        '${DateTime.now().microsecondsSinceEpoch}_$filename';
    final ref = FirebaseStorage.instance.ref().child(
      FirebaseCollections.foodPhotoStoragePath(user.uid, storageFilename),
    );
    await ref.putData(
      Uint8List.fromList(imageBytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return _recognizeWithGemini(Uint8List.fromList(imageBytes));
  }

  Future<List<RecognitionCandidate>> _recognizeWithGemini(
    Uint8List imageBytes,
  ) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
      systemInstruction: Content.system(
        'You identify visible foods in meal photos for a nutrition tracking app. '
        'Return conservative estimates only. If the image is not food, return an empty foods array.',
      ),
    );

    final response = await model.generateContent(
      [
        Content.multi([
          const TextPart(
            'Identify up to 5 visible foods in this image. For each food, estimate one normal serving and nutrition per serving. '
            'Return only JSON matching the schema.',
          ),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'foods': Schema.array(
              items: Schema.object(
                properties: {
                  'name': Schema.string(),
                  'confidence': Schema.number(),
                  'servingSize': Schema.number(),
                  'servingUnit': Schema.string(),
                  'calories': Schema.number(),
                  'protein': Schema.number(),
                  'carbs': Schema.number(),
                  'fat': Schema.number(),
                },
                optionalProperties: [
                  'confidence',
                  'servingSize',
                  'servingUnit',
                  'calories',
                  'protein',
                  'carbs',
                  'fat',
                ],
              ),
            ),
          },
        ),
      ),
    );

    final text = response.text;
    if (text == null || text.trim().isEmpty) return [];

    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final foods = (decoded['foods'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return foods
        .map(_candidateFromGeminiFood)
        .whereType<RecognitionCandidate>()
        .toList();
  }

  RecognitionCandidate? _candidateFromGeminiFood(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final match = _bestLocalMatch(name);
    final food = FoodItem.fromApiJson({
      'id':
          'gemini_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      'name': name,
      'servingSize': json['servingSize'] as num? ?? 1,
      'servingUnit': json['servingUnit'] as String? ?? 'serving',
      'calories':
          json['calories'] as num? ?? match?.calories ?? _fallbackCalories,
      'protein': json['protein'] as num? ?? match?.proteinG ?? 0,
      'carbs': json['carbs'] as num? ?? match?.carbsG ?? 0,
      'fat': json['fat'] as num? ?? match?.fatG ?? 0,
    });

    return RecognitionCandidate(
      label: name,
      confidence: (json['confidence'] as num? ?? 0.65).toDouble().clamp(0, 1),
      matches: [food, if (match != null && match.name != food.name) match],
    );
  }

  FoodItem? _bestLocalMatch(String name) {
    final normalized = name.toLowerCase();
    for (final food in foodDatabase) {
      final foodName = food.name.toLowerCase();
      if (foodName == normalized ||
          foodName.contains(normalized) ||
          normalized.contains(foodName)) {
        return food;
      }
    }
    return null;
  }
}

const _fallbackCalories = 100;
