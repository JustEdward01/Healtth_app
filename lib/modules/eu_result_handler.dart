// lib/services/negative_context_detector.dart

import '../services/eu_allergen_dictionary_service.dart';

class NegativeContextAwareAllergenDetector {
  // Cuvinte cheie care indică context negativ
  static const List<String> _negativeKeywords = [
    // Romanian
    'fără', 'nu conține', 'lipsit de', 'exclus', 'exempt de', 'liber de',
    'nu are', 'nu include', 'absent', 'eliminat', 'îndepărtat',
    'fara', 'nu contine', 'lipsit', 'nu mai contine',
    
    // English
    'without', 'free from', 'does not contain', 'no', 'absent',
    'excludes', 'exempt from', 'lacks', 'devoid of', 'minus',
    'allergen free', 'gluten free', 'dairy free', 'nut free',
    'free of', 'contains no', 'zero', 'none',
    
    // Common patterns
    '0%', 'removed', 'eliminated', 'extracted'
  ];

  /// Filtrează alergenii care apar în context negativ
  List<EUAllergenMatch> filterNegativeContext(
    String text,
    List<EUAllergenMatch> matches,
    String Function(EUAllergenMatch) termExtractor,
  ) {
    final filteredMatches = <EUAllergenMatch>[];
    final lowerText = text.toLowerCase();
    
    for (final match in matches) {
      final allergenTerm = termExtractor(match).toLowerCase();
      
      if (!_isInNegativeContext(lowerText, allergenTerm)) {
        filteredMatches.add(match);
      } else {
        print('🚫 Alergen "$allergenTerm" detectat în context negativ și eliminat');
      }
    }
    
    return filteredMatches;
  }

  /// Verifică dacă un termen de alergen apare în context negativ
  bool _isInNegativeContext(String text, String allergenTerm) {
    for (final keyword in _negativeKeywords) {
      // Pattern 1: "keyword + allergen" (ex: "fără gluten")
      final pattern1 = RegExp(
        r'\b' + RegExp.escape(keyword) + r'\s+.*?\b' + RegExp.escape(allergenTerm) + r'\b',
        caseSensitive: false
      );
      
      // Pattern 2: "allergen + free/absent" (ex: "gluten free")
      final pattern2 = RegExp(
        r'\b' + RegExp.escape(allergenTerm) + r'\s+(free|absent|liber|fara|fără)\b',
        caseSensitive: false
      );
      
      // Pattern 3: "no + allergen" (ex: "no dairy")
      final pattern3 = RegExp(
        r'\b(no|nu|fara|fără)\s+' + RegExp.escape(allergenTerm) + r'\b',
        caseSensitive: false
      );
      
      if (pattern1.hasMatch(text) || pattern2.hasMatch(text) || pattern3.hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }

  /// Detectează și filtrează contextul negativ pentru o listă de termeni simpli
  List<String> filterNegativeContextSimple(String text, List<String> allergens) {
    final filteredAllergens = <String>[];
    final lowerText = text.toLowerCase();
    
    for (final allergen in allergens) {
      if (!_isInNegativeContext(lowerText, allergen.toLowerCase())) {
        filteredAllergens.add(allergen);
      }
    }
    
    return filteredAllergens;
  }
}