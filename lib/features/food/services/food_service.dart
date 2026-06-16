import '../../../core/services/api_client.dart';
import '../models/food_item.dart';

class FoodService {
  FoodService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<FoodItem>> search(String query) async {
    if (query.trim().length < 2) return [];

    final data = await _api.get('/food/search', query: {'q': query.trim()});
    if (data == null) return [];

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(FoodItem.fromApiJson)
        .toList();
  }

  Future<FoodItem?> lookupBarcode(String barcode) async {
    final data = await _api.get('/food/barcode/$barcode');
    if (data == null) return null;
    return FoodItem.fromApiJson(data as Map<String, dynamic>);
  }

  Future<List<FoodItem>> recognizePhoto(List<int> imageBytes, {String filename = 'photo.jpg'}) async {
    final data = await _api.postMultipart(
      '/food/recognize',
      fileField: 'image',
      fileBytes: imageBytes,
      filename: filename,
    );
    if (data == null) return [];
    final items = data['items'] as List<dynamic>? ?? [data];
    return items.cast<Map<String, dynamic>>().map(FoodItem.fromApiJson).toList();
  }
}
