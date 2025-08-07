// result_handler.dart


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
  // Lista completă a celor 14 alergeni majori conform UE, cu regex-uri pre-compilate
  static final Map<String, List<RegExp>> allergenVariants = {
    'lapte': [
      RegExp(r'\b(lapte|lactoză|zer|cazeină|lactalbumin|smântână|brânză|iaurt|unt|margarină)\b', caseSensitive: false),
      RegExp(r'\b(milk|lactose|whey|casein|caseinate|cream|cheese|yogurt|butter)\b', caseSensitive: false),
    ],
    'ouă': [
      RegExp(r'\b(ouă|galbenuș|albuș|ovomucoida)\b', caseSensitive: false),
      RegExp(r'\b(eggs?|albumen|yolk|ovomucoid)\b', caseSensitive: false),
    ],
    'pește': [
      RegExp(r'\b(pește|ton|somon|cod|sardine|macrou|hering|anchoa)\b', caseSensitive: false),
      RegExp(r'\b(fish|tuna|salmon|cod|sardines|mackerel|herring)\b', caseSensitive: false),
    ],
    'crustacee': [
      RegExp(r'\b(crustacee|creveți|homar|langustă|crab)\b', caseSensitive: false),
      RegExp(r'\b(crustaceans?|shrimp|prawns?|lobster)\b', caseSensitive: false),
    ],
    'moluște': [
      RegExp(r'\b(moluște|scoici|stridii|caracatiță|calamari)\b', caseSensitive: false),
      RegExp(r'\b(molluscs?|mussels?|oysters?|octopus|squid)\b', caseSensitive: false),
    ],
    'nuci': [
      RegExp(r'\b(nuci|migdale|alune|castane|fistic|pecan|macadamia)\b', caseSensitive: false),
      RegExp(r'\b(nuts?|almonds?|hazelnuts?|chestnuts?|pistachios?|brazil\snuts?|macadamia)\b', caseSensitive: false),
    ],
    'arahide': [
      RegExp(r'\b(arahide|cacahuete)\b', caseSensitive: false),
      RegExp(r'\b(peanuts?|groundnuts?)\b', caseSensitive: false),
    ],
    'soia': [
      RegExp(r'\b(soia|tofu|lecitină\sde\ssoia|proteină\sde\ssoia)\b', caseSensitive: false),
      RegExp(r'\b(soy|soybeans?|tofu|soy\slecithin|soy\sprotein)\b', caseSensitive: false),
    ],
    'grâu': [
      RegExp(r'\b(grâu|faină|gluten|amidon|bulgur|couscous|seitan)\b', caseSensitive: false),
      RegExp(r'\b(wheat|flour|gluten|starch|bulgur|couscous)\b', caseSensitive: false),
    ],
    'secară': [RegExp(r'\b(secară|rye|centeno)\b', caseSensitive: false)],
    'orz': [RegExp(r'\b(orz|barley|malt|malta)\b', caseSensitive: false)],
    'ovăz': [RegExp(r'\b(ovăz|oats?|avena|avoine)\b', caseSensitive: false)],
    'susan': [RegExp(r'\b(susan|tahini|sesamo|ulei\sde\ssusan)\b', caseSensitive: false)],
    'țelină': [RegExp(r'\b(țelină|celery|apio|celeri)\b', caseSensitive: false)],
    'muștar': [RegExp(r'\b(muștar|mustard|mostarda|moutarde)\b', caseSensitive: false)],
    'lupin': [RegExp(r'\b(lupin|lupine|lupini)\b', caseSensitive: false)],
    'dioxid de sulf': [
      RegExp(r'\b(dioxid\sde\ssulf|sulfit|E-?22[0-8])\b', caseSensitive: false),
      RegExp(r'\b(sulfur\sdioxide|sulphites?|E-?22[0-8])\b', caseSensitive: false),
    ],
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

    // Verifică dacă textul conține cuvinte cheie pentru ingrediente
    final hasIngredientContext = _hasIngredientList(lowerText);

    for (final entry in allergenVariants.entries) {
      final allergen = entry.key;
      final variants = entry.value;

      for (final regex in variants) {
        for (final match in regex.allMatches(lowerText)) {
          final foundTerm = match.group(0)!;
          final position = match.start;

          final confidence = _calculateConfidence(lowerText, foundTerm, position, hasIngredientContext);

          // Adaugă doar dacă confidence > 0.4, un prag mai mare pentru precizie
          if (confidence > 0.4) {
            matches.add(AllergenMatch(
              allergen: allergen,
              foundTerm: foundTerm,
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
  bool _hasIngredientList(String text) {
    return text.contains(RegExp(r'ingredien|składniki|compoziție|ingredients|zusammensetzung', caseSensitive: false));
  }

  /// Calculează confidence score pentru o potrivire
  double _calculateConfidence(String text, String term, int position, bool hasIngredientContext) {
    double confidence = 0.5; // Base confidence

    // Boost dacă e în context de ingrediente
    if (hasIngredientContext) {
      confidence += 0.3;
    }

    // Boost pentru termeni mai specifici
    if (term.length > 5) {
      confidence += 0.1;
    }

    // Penalizare pentru termeni foarte scurți și comuni, dacă nu sunt în context de ingrediente
    if (term.length < 4 && !hasIngredientContext) {
      confidence -= 0.3;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Elimină duplicatele (același alergen detectat de mai multe ori)
  List<AllergenMatch> _removeDuplicates(List<AllergenMatch> matches) {
    final Map<String, AllergenMatch> uniqueMatches = {};

    for (final match in matches) {
      if (!uniqueMatches.containsKey(match.allergen)) {
        uniqueMatches[match.allergen] = match;
      }
    }

    return uniqueMatches.values.toList();
  }

  /// Obține toate tipurile de alergeni disponibili
  List<String> get availableAllergens => allergenVariants.keys.toList();
}