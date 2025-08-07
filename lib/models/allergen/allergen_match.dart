// lib/models/allergen/allergen_match.dart

class AllergenMatch {
  final String allergen;
  final String foundTerm;
  final double confidence;
  final String method; // Doar 'OCR' sau 'DICTIONARY' acum
  final int position;
  final Map<String, dynamic> context;

  AllergenMatch({
    required this.allergen,
    required this.foundTerm,
    required this.confidence,
    required this.method,
    required this.position,
    this.context = const {},
  });

  // Getter pentru a determina dacă este periculos
  bool get isDangerous => confidence > 0.7 && method == 'DICTIONARY';

  // Getter pentru severitate
  String get severityLevel {
    if (confidence >= 0.9) return 'CRITICAL';
    if (confidence >= 0.7) return 'HIGH';
    if (confidence >= 0.5) return 'MEDIUM';
    return 'LOW';
  }

  // Getter pentru culoarea UI
  String get riskColor {
    switch (severityLevel) {
      case 'CRITICAL':
        return '#D32F2F'; // Red 700
      case 'HIGH':
        return '#F57C00'; // Orange 700
      case 'MEDIUM':
        return '#FBC02D'; // Yellow 700
      default:
        return '#388E3C'; // Green 700
    }
  }

  // Validează dacă metoda este suportată
  bool get isValidMethod => ['OCR', 'DICTIONARY'].contains(method);

  // Factory constructor din JSON
  factory AllergenMatch.fromJson(Map<String, dynamic> json) {
    return AllergenMatch(
      allergen: json['allergen'] ?? '',
      foundTerm: json['foundTerm'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      method: json['method'] ?? 'DICTIONARY',
      position: json['position'] ?? 0,
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }

  // Convertire la JSON
  Map<String, dynamic> toJson() {
    return {
      'allergen': allergen,
      'foundTerm': foundTerm,
      'confidence': confidence,
      'method': method,
      'position': position,
      'context': context,
    };
  }

  // toString pentru debugging
  @override
  String toString() {
    return 'AllergenMatch(allergen: $allergen, foundTerm: $foundTerm, '
           'confidence: ${confidence.toStringAsFixed(2)}, method: $method)';
  }

  // Equality override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllergenMatch &&
           other.allergen == allergen &&
           other.foundTerm == foundTerm &&
           other.method == method;
  }

  @override
  int get hashCode => allergen.hashCode ^ foundTerm.hashCode ^ method.hashCode;
}

class AllergenDetectionResult {
  final List<AllergenMatch> detectedAllergens;
  final double overallConfidence;
  final Map<String, double> methodConfidences;
  final String primaryText;
  final Map<String, dynamic> metadata;

  AllergenDetectionResult({
    required this.detectedAllergens,
    required this.overallConfidence,
    required this.methodConfidences,
    required this.primaryText,
    required this.metadata,
  });

  // Getter pentru alergenii critici
  List<AllergenMatch> get criticalAllergens => 
      detectedAllergens.where((a) => a.severityLevel == 'CRITICAL').toList();

  // Getter pentru alergenii cu risc înalt
  List<AllergenMatch> get highRiskAllergens => 
      detectedAllergens.where((a) => a.severityLevel == 'HIGH').toList();

  // Verifică dacă produsul este sigur pentru utilizator
  bool isSafeFor(List<String> userAllergens) {
    return !detectedAllergens.any((match) => 
        userAllergens.contains(match.allergen) && match.confidence > 0.6);
  }

  // Obține lista de alergeni detectați ca string-uri
  List<String> get allergenNames => 
      detectedAllergens.map((a) => a.allergen).toSet().toList();

  // Obține confidence score-ul mediu
  double get averageConfidence {
    if (detectedAllergens.isEmpty) return 0.0;
    final sum = detectedAllergens.fold<double>(0, (sum, a) => sum + a.confidence);
    return sum / detectedAllergens.length;
  }

  // Factory constructor din JSON
  factory AllergenDetectionResult.fromJson(Map<String, dynamic> json) {
    return AllergenDetectionResult(
      detectedAllergens: (json['detectedAllergens'] as List<dynamic>)
          .map((item) => AllergenMatch.fromJson(item))
          .toList(),
      overallConfidence: (json['overallConfidence'] ?? 0.0).toDouble(),
      methodConfidences: Map<String, double>.from(json['methodConfidences'] ?? {}),
      primaryText: json['primaryText'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Convertire la JSON
  Map<String, dynamic> toJson() {
    return {
      'detectedAllergens': detectedAllergens.map((a) => a.toJson()).toList(),
      'overallConfidence': overallConfidence,
      'methodConfidences': methodConfidences,
      'primaryText': primaryText,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'AllergenDetectionResult(allergens: ${allergenNames.join(', ')}, '
           'confidence: ${overallConfidence.toStringAsFixed(2)})';
  }
}