// lib/models/allergen/hybrid_detection_result.dart
import 'allergen_match.dart';

class HybridDetectionResult {
  final List<AllergenMatch> detectedAllergens;
  final double overallConfidence;
  final Map<String, double> methodConfidences;
  final String primaryText;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  HybridDetectionResult({
    required this.detectedAllergens,
    required this.overallConfidence,
    required this.methodConfidences,
    required this.primaryText,
    required this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // JSON serialization pentru cache
  Map<String, dynamic> toJson() => {
    'detectedAllergens': detectedAllergens.map((e) => e.toJson()).toList(),
    'overallConfidence': overallConfidence,
    'methodConfidences': methodConfidences,
    'primaryText': primaryText,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HybridDetectionResult.fromJson(Map<String, dynamic> json) => 
    HybridDetectionResult(
      detectedAllergens: (json['detectedAllergens'] as List)
          .map((e) => AllergenMatch.fromJson(e))
          .toList(),
      overallConfidence: json['overallConfidence'],
      methodConfidences: Map<String, double>.from(json['methodConfidences']),
      primaryText: json['primaryText'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
    );

  bool get hasAllergens => detectedAllergens.isNotEmpty;
  bool get isHighConfidence => overallConfidence >= 0.8;
}