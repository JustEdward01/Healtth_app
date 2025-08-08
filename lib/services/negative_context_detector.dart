// lib/services/negative_context_detector.dart

import 'package:flutter/material.dart';

/// Service pentru detectarea contextului negativ în jurul alergenilor
/// Exemplu: "fără gluten", "lactose-free", "nu conține lapte"
class NegativeContextAwareAllergenDetector {
  
  /// Verifică rapid dacă un text conține indicatori de context negativ
  bool hasNegativeContext(String text) {
    final lowerText = text.toLowerCase();
    
    // Verifică pentru toate limbile
    for (final patterns in _negativePatterns.values) {
      for (final pattern in patterns) {
        if (lowerText.contains(pattern)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Obține scorul de încredere ajustat pentru context negativ
  double getAdjustedConfidence(String text, String foundTerm, double originalConfidence) {
    if (_hasNegativeContextAround(text, foundTerm)) {
      // Reducere drastică de confidence pentru context negativ
      return originalConfidence * 0.1;
    }
    
    return originalConfidence;
  }

  /// Analizează contextul în detaliu pentru debugging
  ContextAnalysis analyzeContext(String text, String term) {
    final termIndex = text.toLowerCase().indexOf(term.toLowerCase());
    if (termIndex == -1) {
      return ContextAnalysis(
        hasNegativeContext: false,
        foundPatterns: [],
        contextWindow: '',
        confidence: 1.0,
      );
    }

    final start = (termIndex - 50).clamp(0, text.length);
    final end = (termIndex + term.length + 50).clamp(0, text.length);
    final context = text.substring(start, end);
    
    final foundPatterns = <String>[];
    
    // Găsește toate pattern-urile negative în context
    for (final entry in _negativePatterns.entries) {
      for (final pattern in entry.value) {
        if (context.toLowerCase().contains(pattern.toLowerCase())) {
          foundPatterns.add('${entry.key}: $pattern');
        }
      }
    }

    final hasNegative = foundPatterns.isNotEmpty || _hasSpecificFreePatterns(context, term);
    
    return ContextAnalysis(
      hasNegativeContext: hasNegative,
      foundPatterns: foundPatterns,
      contextWindow: context,
      confidence: hasNegative ? 0.1 : 1.0,
    );
  }
}

/// Model pentru analiza detaliată a contextului
class ContextAnalysis {
  final bool hasNegativeContext;
  final List<String> foundPatterns;
  final String contextWindow;
  final double confidence;

  ContextAnalysis({
    required this.hasNegativeContext,
    required this.foundPatterns,
    required this.contextWindow,
    required this.confidence,
  });

  @override
  String toString() {
    return 'ContextAnalysis(negative: $hasNegativeContext, patterns: $foundPatterns, confidence: $confidence)';
  }
} 
   final Map<String, List<String>> _negativePatterns = {
    'ro': [
      'fara', 'fără', 'nu contine', 'nu conține', 'lipsa', 'lipsă',
      'exempt de', 'exempt', 'zero', 'absent', 'fără adaos',
      'nu sunt', 'nu este', 'nu au fost', 'nu a fost'
    ],
    'en': [
      'free', 'without', 'no', 'does not contain', 'absent',
      'exempt from', 'zero', 'not added', 'not contain',
      'dairy-free', 'gluten-free', 'nut-free', 'egg-free'
    ],
    'de': [
      'frei', 'ohne', 'kein', 'enthält nicht', 'glutenfrei',
      'laktosefrei', 'milchfrei', 'eifrei', 'nussfrei'
    ],
    'fr': [
      'sans', 'exempt de', 'ne contient pas', 'absent',
      'sans gluten', 'sans lactose', 'sans lait', 'libre de'
    ],
    'it': [
      'senza', 'privo di', 'non contiene', 'assente',
      'senza glutine', 'senza lattosio', 'senza latte'
    ],
    'es': [
      'sin', 'libre de', 'no contiene', 'ausente',
      'sin gluten', 'sin lactosa', 'sin leche'
    ],
    'hu': [
      'mentes', 'nélkül', 'nem tartalmaz', 'hiányzik',
      'gluténmentes', 'laktózmentes', 'tejmentes'
    ],
    'pl': [
      'bez', 'wolny od', 'nie zawiera', 'brak',
      'bezglutenowy', 'bezmłodzny', 'bez laktozy'
    ],
  };

  /// Filtrează rezultatele eliminând cele cu context negativ
  List<T> filterNegativeContext<T>(
    String text,
    List<T> matches,
    String Function(T) getFoundTerm,
  ) {
    final filteredMatches = <T>[];
    final lowerText = text.toLowerCase();

    for (final match in matches) {
      final foundTerm = getFoundTerm(match);
      
      if (!_hasNegativeContextAround(lowerText, foundTerm)) {
        filteredMatches.add(match);
      } else {
        debugPrint('⚡ Eliminat din cauza contextului negativ: "$foundTerm"');
      }
    }

    return filteredMatches;
  }

  /// Verifică dacă există context negativ în jurul unui termen
  bool _hasNegativeContextAround(String text, String term) {
    final termIndex = text.indexOf(term.toLowerCase());
    if (termIndex == -1) return false;

    // Verifică într-o fereastră de 50 de caractere în ambele direcții
    final start = (termIndex - 50).clamp(0, text.length);
    final end = (termIndex + term.length + 50).clamp(0, text.length);
    final context = text.substring(start, end);

    // Verifică pentru toate limbile
    for (final patterns in _negativePatterns.values) {
      for (final pattern in patterns) {
        if (context.contains(pattern.toLowerCase())) {
          return true;
        }
      }
    }

    // Verifică pentru pattern-uri specifice cum ar fi "X-free"
    if (_hasSpecificFreePatterns(context, term)) {
      return true;
    }

    return false;
  }

  /// Verifică pentru pattern-uri specifice de tipul "X-free"
  bool _hasSpecificFreePatterns(String context, String term) {
    // Pattern-uri de tipul "gluten-free", "dairy-free", etc.
    final freePatterns = [
      '$term-free',
      '$term free',
      'free $term',
      'no $term',
      'without $term',
      'sans $term',
      'ohne $term',
      'senza $term',
      'sin $term',
      'bez $term',
    ];

    for (final pattern in freePatterns) {
      if (context.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  ///