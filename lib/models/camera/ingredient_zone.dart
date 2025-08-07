import 'dart:ui';

class IngredientZone {
  final Rect? rect;
  final double confidence;
  final int wordCount;
  final List<String> detectedIngredients;

  IngredientZone({
    required this.rect,
    required this.confidence,
    required this.wordCount,
    this.detectedIngredients = const [],
  });

  factory IngredientZone.empty() {
    return IngredientZone(
      rect: null,
      confidence: 0.0,
      wordCount: 0,
      detectedIngredients: [],
    );
  }

  bool get hasIngredients => detectedIngredients.isNotEmpty;
  String get ingredientPreview => detectedIngredients.take(3).join(', ');
  bool get isDetected => rect != null && confidence > 0.3;
}

class IngredientCandidate {
  final Rect rect;
  final Rect expandedRect;
  final double score;
  final int wordCount;
  final List<String> detectedIngredients;

  IngredientCandidate({
    required this.rect,
    required this.expandedRect,
    required this.score,
    required this.wordCount,
    required this.detectedIngredients,
  });
}