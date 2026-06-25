import 'dart:typed_data';

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
    return [];
  }
}
