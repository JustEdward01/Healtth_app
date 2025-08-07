class HybridDetectionResult {
  final List<AllergenMatch> detectedAllergens;
  final double overallConfidence;
  final Map<String, double> methodConfidences;
  final String primaryText;
  final DateTime timestamp;

  HybridDetectionResult({
    required this.detectedAllergens,
    required this.overallConfidence,
    required this.methodConfidences,
    required this.primaryText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasAllergens => detectedAllergens.isNotEmpty;
  bool get isHighConfidence => overallConfidence >= 0.8;
}

class AllergenMatch {
  final String allergen;
  final String foundTerm;
  final double confidence;
  final String detectionMethod;

  AllergenMatch({
    required this.allergen,
    required this.foundTerm,
    required this.confidence,
    required this.detectionMethod,
  });

  bool get isDangerous => confidence >= 0.7;
}