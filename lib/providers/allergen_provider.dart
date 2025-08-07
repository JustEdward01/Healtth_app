import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/allergen/allergen_match.dart'; // Updated import
import '../services/hybrid_detection_service.dart'; // Păstrează numele, dar e curățat

class AllergenProvider with ChangeNotifier {
  final AllergenDetectionService _service = AllergenDetectionService(); // Updated class name
  
  bool _isScanning = false;
  AllergenDetectionResult? _lastResult; // Updated type
  List<String> _userAllergens = ['lapte', 'gluten', 'soia'];
  
  // Error handling
  String? _lastError;
  
  // Statistics
  int _totalScans = 0;
  int _allergensDetected = 0;

  // Getters
  bool get isScanning => _isScanning;
  AllergenDetectionResult? get lastResult => _lastResult; // Updated type
  List<String> get userAllergens => _userAllergens;
  String? get lastError => _lastError;
  int get totalScans => _totalScans;
  int get allergensDetected => _allergensDetected;

  // Check if last result has dangerous allergens for user
  bool get hasUserAllergens {
    if (_lastResult == null) return false;
    return _lastResult!.detectedAllergens.any(
      (match) => _userAllergens.contains(match.allergen) && match.confidence > 0.6
    );
  }

  // Get high-confidence allergens
  List<AllergenMatch> get highConfidenceAllergens {
    if (_lastResult == null) return [];
    return _lastResult!.detectedAllergens.where(
      (match) => match.confidence >= 0.8
    ).toList();
  }

  void setUserAllergens(List<String> allergens) {
    _userAllergens = allergens;
    notifyListeners();
  }

  void addUserAllergen(String allergen) {
    if (!_userAllergens.contains(allergen)) {
      _userAllergens.add(allergen);
      notifyListeners();
    }
  }

  void removeUserAllergen(String allergen) {
    _userAllergens.remove(allergen);
    notifyListeners();
  }

  Future<AllergenDetectionResult> scanImage(File imageFile) async {
    _isScanning = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _service.detectAllergens(
        imageFile: imageFile,
        userAllergens: _userAllergens,
        confidenceThreshold: 0.6, // Dictionary threshold
      );

      _lastResult = result;
      _totalScans++;
      _allergensDetected += result.detectedAllergens.length;
      
      return result;
    } catch (e) {
      _lastError = 'Eroare la scanare: ${e.toString()}';
      // Return empty result on error
      _lastResult = AllergenDetectionResult(
        detectedAllergens: [],
        overallConfidence: 0.0,
        methodConfidences: {'DICTIONARY': 0.0},
        primaryText: 'Eroare la procesare',
        metadata: {
          'error': true,
          'error_message': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return _lastResult!;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // Clear last result and error
  void clearLastResult() {
    _lastResult = null;
    _lastError = null;
    notifyListeners();
  }

  // Get safety status for product
  ProductSafetyStatus getSafetyStatus() {
    if (_lastResult == null) return ProductSafetyStatus.unknown;
    
    final userAllergenMatches = _lastResult!.detectedAllergens.where(
      (match) => _userAllergens.contains(match.allergen) && match.confidence > 0.6
    ).toList();

    if (userAllergenMatches.isEmpty) {
      return ProductSafetyStatus.safe;
    } else if (userAllergenMatches.any((m) => m.confidence >= 0.9)) {
      return ProductSafetyStatus.dangerous;
    } else {
      return ProductSafetyStatus.warning;
    }
  }

  // Get formatted result summary
  String getResultSummary() {
    if (_lastResult == null) return 'Nu există rezultate';
    
    final detected = _lastResult!.detectedAllergens;
    if (detected.isEmpty) {
      return 'Nu s-au detectat alergeni';
    }
    
    final allergenNames = detected.map((a) => a.allergen).toSet().join(', ');
    return 'Detectați: $allergenNames';
  }

  // Reset statistics
  void resetStatistics() {
    _totalScans = 0;
    _allergensDetected = 0;
    notifyListeners();
  }

  // Get detection methods used
  List<String> getUsedMethods() {
    if (_lastResult == null) return [];
    return _lastResult!.methodConfidences.keys.toList();
  }

  // Check if product is safe for specific allergen
  bool isSafeForAllergen(String allergen) {
    if (_lastResult == null) return true;
    return !_lastResult!.detectedAllergens.any(
      (match) => match.allergen == allergen && match.confidence > 0.6
    );
  }
}

// Enum for product safety status
enum ProductSafetyStatus {
  safe,     // Verde - produsul e sigur
  warning,  // Galben - posibili alergeni cu confidence mediu
  dangerous, // Roșu - alergeni periculoși cu confidence înalt
  unknown   // Gri - nu există rezultate
}

// Extension pentru culori UI
extension ProductSafetyStatusExtension on ProductSafetyStatus {
  String get displayName {
    switch (this) {
      case ProductSafetyStatus.safe:
        return 'Sigur';
      case ProductSafetyStatus.warning:
        return 'Atenție';
      case ProductSafetyStatus.dangerous:
        return 'Pericol';
      case ProductSafetyStatus.unknown:
        return 'Necunoscut';
    }
  }

  String get colorCode {
    switch (this) {
      case ProductSafetyStatus.safe:
        return '#4CAF50'; // Green
      case ProductSafetyStatus.warning:
        return '#FF9800'; // Orange
      case ProductSafetyStatus.dangerous:
        return '#F44336'; // Red
      case ProductSafetyStatus.unknown:
        return '#9E9E9E'; // Grey
    }
  }
}