import 'dart:io';
import 'dart:developer' as developer;
import '../models/allergen/allergen_match.dart';

class AllergenDetectionService {
  static final _instance = AllergenDetectionService._internal();
  factory AllergenDetectionService() => _instance;
  AllergenDetectionService._internal();
  
  // Cache pentru rezultate (final pentru a evita warning-ul)
  final Map<String, AllergenDetectionResult> _resultCache = <String, AllergenDetectionResult>{};
  
  void initialize() {
    developer.log('🔍 Dictionary-Based Allergen Detection Service initialized', name: 'HybridService');
  }

  Future<AllergenDetectionResult> detectAllergens({
    required File imageFile,
    required List<String> userAllergens,
    String targetLanguage = 'ro',
    double confidenceThreshold = 0.6,
  }) async {
    final startTime = DateTime.now();
    try {
      // 1. OCR local (simulat pentru demo rapid)
      final ocrText = await _performOCR(imageFile);
     
      // 2. Combinare rezultate doar cu OCR
      final result = _combineResults(
        ocrText,
        userAllergens, 
        startTime,
      );
      
      developer.log('✅ Detection completed in ${DateTime.now().difference(startTime).inMilliseconds}ms', 
                   name: 'HybridService');
      
      return result;
      
    } catch (e, stackTrace) {
      developer.log('❌ Error in hybrid detection: $e', 
                   name: 'HybridService', 
                   error: e, 
                   stackTrace: stackTrace);
      return _fallbackResult(userAllergens, startTime, error: e.toString());
    }
  }

  Future<String> _performOCR(File imageFile) async {
    // Implementare OCR simplificată pentru demo
    // În implementarea reală, aici va fi Google ML Kit
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simulează diferite texte bazate pe numele fișierului pentru testare
    final fileName = imageFile.path.toLowerCase();
    if (fileName.contains('biscuiti') || fileName.contains('cookie')) {
      return "făină de grâu, zahăr, unt, ouă, lapte praf, cacao, lecitină de soia";
    } else if (fileName.contains('lapte') || fileName.contains('milk')) {
      return "lapte integral, vitamina D3, stabilizatori";
    } else if (fileName.contains('paine') || fileName.contains('bread')) {
      return "făină de grâu, apă, drojdie, sare, zahăr, gluten";
    } else {
      return "lapte praf, zahăr, cacao, lecitină de soia, aromă vanilie, făină de grâu, nuci";
    }
  }

  AllergenDetectionResult _combineResults(
    String ocrText, 
    List<String> userAllergens,
    DateTime startTime,
  ) {
    // Detectare doar prin dicționar - eliminăm BERT
    final detectedAllergens = _simpleOcrDetection(ocrText, userAllergens);

    final overallConfidence = detectedAllergens.isNotEmpty 
        ? detectedAllergens.map((e) => e.confidence).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Metadata obligatoriu
    final metadata = {
      'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
      'ocr_text_length': ocrText.length,
      'user_allergens': userAllergens,
      'detection_methods': ['DICTIONARY'],
      'confidence_threshold': 0.6,
      'timestamp': DateTime.now().toIso8601String(),
      'total_allergens_found': detectedAllergens.length,
      'dangerous_allergens': detectedAllergens.where((a) => a.isDangerous).length,
    };

    return AllergenDetectionResult(
      detectedAllergens: detectedAllergens,
      overallConfidence: overallConfidence,
      methodConfidences: {
        'OCR': 0.8,
        'DICTIONARY': 0.9,
      },
      primaryText: ocrText,
      metadata: metadata,
    );
  }

  List<AllergenMatch> _simpleOcrDetection(String text, List<String> userAllergens) {
    final matches = <AllergenMatch>[];
    final lowerText = text.toLowerCase();

    // Database extins de alergeni cu variante multilingve îmbunătățit
    final allergenPatterns = {
      // Lapte - extins cu mai multe variante
      'lapte': [
        'lapte', 'lactoza', 'smantana', 'unt', 'branza', 'cazeina', 'zer', 'cream', 'milk',
        'lapte praf', 'milk powder', 'dairy', 'lactose', 'butter', 'cheese', 'casein', 'whey',
        'milch', 'lait', 'latte', 'leche', 'mleko', 'tej', 'lapte integral', 'lapte degresat'
      ],
      // Gluten - extins cu forme tehnice
      'gluten': [
        'gluten', 'grau', 'faina', 'amidon', 'malt', 'orz', 'secara', 'wheat', 'flour',
        'faina de grau', 'wheat flour', 'gluten vital', 'vital wheat gluten', 'seitan',
        'bulgur', 'couscous', 'farro', 'spelt', 'einkorn', 'emmer', 'triticale',
        'weizen', 'blé', 'frumento', 'trigo', 'pszenica', 'búza'
      ],
      // Soia - cu toate formele procesate
      'soia': [
        'soia', 'lecitina', 'protein de soia', 'soy', 'soya', 'lecithin',
        'lecitina de soia', 'soy lecithin', 'soy protein', 'tofu', 'tempeh', 'miso',
        'soybean', 'soja', 'soja lecithin', 'isolat proteic din soia', 'texturat soia'
      ],
      // Ouă - toate formele
      'oua': [
        'oua', 'ou', 'albumen', 'galbenus', 'lecitina din oua', 'egg', 'eggs',
        'albumin', 'yolk', 'egg lecithin', 'ovum', 'ovo', 'ei', 'oeuf', 'uovo',
        'huevo', 'jajko', 'tojás', 'ou intreg', 'ou de gaina', 'egg white', 'egg yolk'
      ],
      // Nuci - toate tipurile
      'nuci': [
        'nuci', 'alune', 'migdale', 'fistic', 'caju', 'nuts', 'almonds', 'hazelnuts',
        'walnuts', 'pecans', 'cashews', 'pistachios', 'tree nuts', 'nuci caju',
        'nuci braziliene', 'nuci macadamia', 'pine nuts', 'nuci de pin',
        'nüsse', 'noix', 'noci', 'nueces', 'orzechy', 'diófélék'
      ],
      // Pește - toate speciile comune
      'peste': [
        'peste', 'ton', 'somon', 'cod', 'fish', 'salmon', 'tuna', 'mackerel',
        'sardine', 'hering', 'anchovy', 'cod liver oil', 'ulei de ficat de cod',
        'fisch', 'poisson', 'pesce', 'pescado', 'ryba', 'hal',
        'dorada', 'sea bass', 'trout', 'pastrav'
      ],
      // Crustacee - toate tipurile
      'crustacee': [
        'crustacee', 'creveti', 'raci', 'crab', 'shrimp', 'lobster', 'langosta',
        'crawfish', 'prawns', 'crayfish', 'krill', 'langostino',
        'krebstiere', 'crustacés', 'crostacei', 'crustáceos', 'skorupiaki', 'rákfélék'
      ],
      // Susan - toate formele
      'susan': [
        'susan', 'seminte de susan', 'tahini', 'sesame', 'sesame seeds',
        'sesame oil', 'ulei de susan', 'pasta de susan', 'sesam',
        'sésame', 'sesamo', 'sésamo', 'sezam', 'szezám'
      ],
      // Țelină - toate formele
      'telina': [
        'telina', 'celery', 'celery salt', 'sare de telina', 'celery root',
        'sellerie', 'céleri', 'sedano', 'apio', 'seler', 'zeller'
      ],
      // Muștar - toate formele
      'mustar': [
        'mustar', 'mustard', 'seminte de mustar', 'mustard seeds', 'mustar dijon',
        'senf', 'moutarde', 'senape', 'mostaza', 'musztarda', 'mustár'
      ],
      // Lupin - toate formele
      'lupin': [
        'lupin', 'lupine', 'lupin flour', 'faina de lupin', 'lupini',
        'lupin beans', 'boabe de lupin'
      ],
      // Moluște - toate tipurile
      'moluste': [
        'moluste', 'scoici', 'midii', 'melci', 'mollusks', 'mussels', 'clams',
        'oysters', 'snails', 'scallops', 'squid', 'calamari', 'octopus',
        'weichtiere', 'mollusques', 'molluschi', 'moluscos', 'mięczaki', 'puhatestűek'
      ]
    };

    // Cuvinte de context negativ îmbunătățite
    final negativeContextWords = [
      'fara', 'without', 'free', 'nu contine', 'does not contain',
      'exempt de', 'exempt from', 'lipsa', 'absent', 'zero',
      'frei', 'sans', 'senza', 'sin', 'bez', 'nélkül',
      'gluten-free', 'lactose-free', 'dairy-free', 'nut-free'
    ];

    // Verifică contextul negativ
    final hasNegativeContext = negativeContextWords.any((word) => 
        lowerText.contains(word.toLowerCase()));

    for (var entry in allergenPatterns.entries) {
      final allergen = entry.key;
      
      for (var pattern in entry.value) {
        final lowerPattern = pattern.toLowerCase();
        if (lowerText.contains(lowerPattern)) {
          // Verifică dacă este cuvânt întreg
          if (_isWholeWord(lowerText, lowerPattern)) {
            // Calculează confidence bazat pe lungimea pattern-ului și context
            final confidence = _calculateOcrConfidence(
              text: lowerText, 
              pattern: lowerPattern, 
              allergen: allergen,
              userAllergens: userAllergens,
              hasNegativeContext: hasNegativeContext,
            );
            
            matches.add(AllergenMatch(
              allergen: allergen,
              foundTerm: pattern,
              confidence: confidence.clamp(0.0, 1.0),
              method: 'DICTIONARY', // Schimbat din 'BERT' la 'DICTIONARY'
              position: lowerText.indexOf(lowerPattern),
              context: {
                'is_user_allergen': userAllergens.contains(allergen),
                'pattern_length': lowerPattern.length,
                'found_at_position': lowerText.indexOf(lowerPattern),
                'has_negative_context': hasNegativeContext,
              },
            ));
            break; // Nu căuta alte variante pentru același alergen
          }
        }
      }
    }

    // Sortează după confidence descendent
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Elimină duplicatele pentru același alergen
    final Map<String, AllergenMatch> uniqueMatches = {};
    for (var match in matches) {
      if (!uniqueMatches.containsKey(match.allergen) || 
          uniqueMatches[match.allergen]!.confidence < match.confidence) {
        uniqueMatches[match.allergen] = match;
      }
    }
    
    return uniqueMatches.values.toList();
  }

  bool _isWholeWord(String text, String pattern) {
    final index = text.indexOf(pattern);
    if (index == -1) return false;
    
    // Verifică caracterul dinaintea pattern-ului
    if (index > 0) {
      final prevChar = text[index - 1];
      if (RegExp(r'[a-zA-ZăâîșțĂÂÎȘȚ0-9]').hasMatch(prevChar)) {
        return false;
      }
    }
    
    // Verifică caracterul de după pattern
    final endIndex = index + pattern.length;
    if (endIndex < text.length) {
      final nextChar = text[endIndex];
      if (RegExp(r'[a-zA-ZăâîșțĂÂÎȘȚ0-9]').hasMatch(nextChar)) {
        return false;
      }
    }
    
    return true;
  }

  double _calculateOcrConfidence({
    required String text,
    required String pattern, 
    required String allergen,
    required List<String> userAllergens,
    required bool hasNegativeContext,
  }) {
    double baseConfidence = 0.75;
    
    // Boost pentru termeni mai lungi (mai specifici)
    if (pattern.length >= 8) {
      baseConfidence += 0.15;
    } else if (pattern.length >= 5) {
      baseConfidence += 0.1;
    }
    
    // Boost pentru alergeni prioritari
    const priorityAllergens = ['lapte', 'gluten', 'oua', 'nuci'];
    if (priorityAllergens.contains(allergen)) {
      baseConfidence += 0.05;
    }
    
    // Boost pentru alergenii utilizatorului
    if (userAllergens.contains(allergen)) {
      baseConfidence += 0.1;
    }
    
    // Penalizare pentru context negativ
    if (hasNegativeContext) {
      baseConfidence -= 0.4;
    }
    
    // Boost pentru context pozitiv
    if (_hasPositiveContext(text, pattern)) {
      baseConfidence += 0.1;
    }
    
    // Penalizare pentru termeni foarte scurti (posibile false positive)
    if (pattern.length <= 3) {
      baseConfidence -= 0.2;
    }
    
    return baseConfidence.clamp(0.1, 0.95);
  }

  bool _hasPositiveContext(String text, String pattern) {
    const positiveWords = [
      'ingrediente', 'contine', 'ingredients', 'contains',
      'poate contine', 'may contain', 'traces of', 'urme de',
      'zutaten', 'ingrédients', 'ingredienti', 'ingredientes'
    ];
    
    final patternIndex = text.indexOf(pattern);
    if (patternIndex == -1) return false;
    
    // Verifică într-o fereastră de 50 de caractere în jurul pattern-ului
    final start = (patternIndex - 50).clamp(0, text.length);
    final end = (patternIndex + pattern.length + 50).clamp(0, text.length);
    final context = text.substring(start, end);
    
    return positiveWords.any((word) => context.contains(word));
  }

  AllergenDetectionResult _fallbackResult(
    List<String> userAllergens, 
    DateTime startTime, 
    {String error = 'Unknown error'}
  ) {
    final metadata = {
      'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
      'error': error,
      'fallback_mode': true,
      'user_allergens': userAllergens,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return AllergenDetectionResult(
      detectedAllergens: [],
      overallConfidence: 0.0,
      methodConfidences: {'DICTIONARY': 0.0},
      primaryText: 'Eroare la procesare: $error',
      metadata: metadata,
    );
  }

  /// Cache pentru rezultatele recente
  void clearCache() {
    _resultCache.clear();
    developer.log('Detection cache cleared', name: 'HybridService');
  }

  /// Statistici cache
  Map<String, dynamic> getCacheStats() {
    return {
      'cache_size': _resultCache.length,
      'cache_keys': _resultCache.keys.toList(),
    };
  }
}