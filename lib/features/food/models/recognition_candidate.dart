import 'food_item.dart';

/// One detected food label from POST /food/recognize.
/// The backend returns: [{label, confidence, matches:[FoodItem, ...]}]
class RecognitionCandidate {
  const RecognitionCandidate({
    required this.label,
    required this.confidence,
    required this.matches,
  });

  final String label;
  final double confidence; // 0.0 – 1.0
  final List<FoodItem> matches;

  FoodItem? get bestMatch => matches.isEmpty ? null : matches.first;

  factory RecognitionCandidate.fromJson(Map<String, dynamic> json) {
    final rawMatches = (json['matches'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(FoodItem.fromApiJson)
        .toList();
    return RecognitionCandidate(
      label: json['label'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      matches: rawMatches,
    );
  }
}
