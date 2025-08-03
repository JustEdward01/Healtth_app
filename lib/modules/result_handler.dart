/// Model pentru rezultatul detectării alergenilor
class AllergenMatch {
  final String allergen;
  final String foundTerm;
  final double confidence;
  final int position;

  AllergenMatch({
    required this.allergen,
    required this.foundTerm,
    required this.confidence,
    required this.position,
  });
}

class ResultHandler {
  // Lista completă a celor 14 alergeni majori conform UE
  static const Map<String, List<String>> allergenVariants = {
    'lapte': [
      'lapte', 'milk', 'latte', 'leche', 'lait',
      'lactoza', 'lactose', 'zer', 'whey', 'cazeina', 'casein',
      'smântână', 'cream', 'brânză', 'cheese', 'iaurt', 'yogurt',
      'unt', 'butter', 'margarina'
    ],
    'ouă': [
      'ouă', 'eggs', 'egg', 'oua', 'ou',
      'albumen', 'gălbenuş', 'yolk', 'lecitina', 'lecithin',
      'ovomucoida', 'ovomucoid'
    ],
    'pește': [
      'pește', 'fish', 'peste', 'pesce',
      'ton', 'tuna', 'somon', 'salmon', 'cod', 'bacalau',
      'sardine', 'macrou', 'hering', 'anchoa'
    ],
    'crustacee': [
      'crustacee', 'crustaceans', 'crab', 'lobster',
      'creveti', 'shrimp', 'prawns', 'langusta',
      'homard', 'gamberi'
    ],
    'moluște': [
      'moluște', 'molluscs', 'scoici', 'mussels',
      'stridii', 'oysters', 'caracatita', 'octopus',
      'calamari', 'squid'
    ],
    'nuci': [
      'nuci', 'nuts', 'migdale', 'almonds', 'almond',
      'castane', 'chestnuts', 'fistic', 'pistachios', 'pistachio',
      'alune', 'hazelnuts', 'hazelnut', 'pecan',
      'nuci braziliene', 'brazil nuts', 'nuci macadamia', 'macadamia'
    ],
    'arahide': [
      'arahide', 'peanuts', 'peanut', 'groundnuts',
      'cacahuete', 'amendoim'
    ],
    'soia': [
      'soia', 'soy', 'soja', 'tofu',
      'lecitina de soia', 'soy lecithin',
      'proteine de soia', 'soy protein'
    ],
    'grâu': [
      'grâu', 'wheat', 'faina', 'flour',
      'gluten', 'amidon', 'starch',
      'bulgur', 'couscous', 'seitan'
    ],
    'secară': [
      'secară', 'rye', 'centeno'
    ],
    'orz': [
      'orz', 'barley', 'malt', 'malta',
      'extract de malt', 'malt extract'
    ],
    'ovăz': [
      'ovăz', 'oats', 'avena', 'avoine'
    ],
    'susan': [
      'susan', 'sesame', 'tahini', 'sesamo',
      'ulei de susan', 'sesame oil'
    ],
    'țelină': [
      'țelină', 'celery', 'apio', 'celeri'
    ],
    'muștar': [
      'muștar', 'mustard', 'mostarda', 'moutarde'
    ],
    'lupin': [
      'lupin', 'lupine', 'lupini'
    ],
    'dioxid de sulf': [
      'dioxid de sulf', 'sulfur dioxide', 'sulphur dioxide',
      'sulfiti', 'sulfites', 'e220', 'e221', 'e222', 'e223', 'e224', 'e225', 'e226', 'e227', 'e228'
    ]
  };

  /// Detectează alergeni cu compatibilitate cu versiunea ta originală
  List<String> findAllergens(String text) {
    final matches = findAllergensDetailed(text);
    return matches.map((match) => match.allergen).toSet().toList();
  }

  /// Detectează alergeni cu informații detaliate
  List<AllergenMatch> findAllergensDetailed(String text) {
    final List<AllergenMatch> matches = [];
    final lowerText = text.toLowerCase();
    
    // Curăță textul de caractere speciale pentru căutare mai precisă
    final cleanedText = _cleanTextForSearch(lowerText);
    
    for (final entry in allergenVariants.entries) {
      final allergen = entry.key;
      final variants = entry.value;
      
      for (final variant in variants) {
        final foundPositions = _findAllOccurrences(cleanedText, variant.toLowerCase());
        
        for (final position in foundPositions) {
          final confidence = _calculateConfidence(cleanedText, variant.toLowerCase(), position);
          
          // Adaugă doar dacă confidence > 0.3 pentru a evita false positive
          if (confidence > 0.3) {
            matches.add(AllergenMatch(
              allergen: allergen,
              foundTerm: variant,
              confidence: confidence,
              position: position,
            ));
          }
        }
      }
    }
    
    // Sortează după confidence și elimină duplicatele
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return _removeDuplicates(matches);
  }

  /// Verifică dacă textul pare să conțină o listă de ingrediente
  bool hasIngredientList(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains(RegExp(r'ingredient|składniki|ingrediente|composition'));
  }

  /// Obține statistici despre detectarea alergenilor
  Map<String, dynamic> getDetectionStats(String text) {
    final matches = findAllergensDetailed(text);
    final uniqueAllergens = matches.map((m) => m.allergen).toSet();
    
    return {
      'totalMatches': matches.length,
      'uniqueAllergens': uniqueAllergens.length,
      'allergensList': uniqueAllergens.toList(),
      'averageConfidence': matches.isEmpty 
          ? 0.0 
          : matches.map((m) => m.confidence).reduce((a, b) => a + b) / matches.length,
      'hasIngredients': hasIngredientList(text),
      'textLength': text.length,
    };
  }

  /// Curăță textul pentru căutare mai precisă
  String _cleanTextForSearch(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Înlocuiește punctuația cu spații
        .replaceAll(RegExp(r'\s+'), ' ')     // Înlocuiește spații multiple
        .trim();
  }

  /// Găsește toate aparițiile unui termen în text
  List<int> _findAllOccurrences(String text, String term) {
    final List<int> occurrences = [];
    int index = text.indexOf(term);
    
    while (index != -1) {
      // Verifică dacă e cuvânt întreg (nu parte din alt cuvânt)
      bool isWholeWord = true;
      
      if (index > 0 && RegExp(r'\w').hasMatch(text[index - 1])) {
        isWholeWord = false;
      }
      
      if (index + term.length < text.length && 
          RegExp(r'\w').hasMatch(text[index + term.length])) {
        isWholeWord = false;
      }
      
      if (isWholeWord) {
        occurrences.add(index);
      }
      
      index = text.indexOf(term, index + 1);
    }
    
    return occurrences;
  }

  /// Calculează confidence score pentru o potrivire
  double _calculateConfidence(String text, String term, int position) {
    double confidence = 0.5; // Base confidence
    
    // Boost dacă e în context de ingrediente
    final contextBefore = text.substring(
      (position - 50).clamp(0, text.length), 
      position
    );
    final contextAfter = text.substring(
      position, 
      (position + 50).clamp(0, text.length)
    );
    
    if (contextBefore.contains(RegExp(r'ingredient|składniki')) ||
        contextAfter.contains(RegExp(r'ingredient|składniki'))) {
      confidence += 0.3;
    }
    
    // Boost pentru termeni mai specifici
    if (term.length > 4) {
      confidence += 0.1;
    }
    
    // Penalizare pentru termeni foarte comuni care pot fi false positive
    if (['ou', 'unt', 'lapte'].contains(term) && term.length < 4) {
      confidence -= 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Elimină duplicatele (același alergen detectat de mai multe ori)
  List<AllergenMatch> _removeDuplicates(List<AllergenMatch> matches) {
    final Map<String, AllergenMatch> uniqueMatches = {};
    
    for (final match in matches) {
      if (!uniqueMatches.containsKey(match.allergen) ||
          uniqueMatches[match.allergen]!.confidence < match.confidence) {
        uniqueMatches[match.allergen] = match;
      }
    }
    
    return uniqueMatches.values.toList();
  }

  /// Obține toate tipurile de alergeni disponibili
  List<String> get availableAllergens => allergenVariants.keys.toList();
}