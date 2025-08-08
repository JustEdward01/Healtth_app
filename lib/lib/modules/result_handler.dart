// result_handler.dart - ENHANCED VERSION

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
  // Lista completă a celor 14 alergeni majori conform UE, cu regex-uri îmbunătățite
  static final Map<String, List<RegExp>> allergenVariants = {
    'lapte': [
      // Română - toate variantele posibile
      RegExp(r'\b(lapte|lactoza|lactoze|zer|cazeina|lactalbumin|smantana|smântână|branza|brânza|brânză|iaurt|unt|margarina|crema)\b', caseSensitive: false),
      RegExp(r'\b(praf\s+de\s+lapte|lapte\s+praf|lapte\s+integral|lapte\s+degresat)\b', caseSensitive: false),
      // Engleză
      RegExp(r'\b(milk|lactose|whey|casein|caseinate|cream|cheese|yogurt|yoghurt|butter|dairy)\b', caseSensitive: false),
      RegExp(r'\b(milk\s+powder|skimmed\s+milk|whole\s+milk)\b', caseSensitive: false),
      // Germană
      RegExp(r'\b(milch|laktose|molke|kasein|sahne|käse|joghurt|butter)\b', caseSensitive: false),
      // Franceză
      RegExp(r'\b(lait|lactose|petit-lait|caséine|crème|fromage|yaourt|beurre)\b', caseSensitive: false),
    ],
    'oua': [
      // Română - TOATE formele
      RegExp(r'\b(oua|ouă|ou|galbenus|gălbenuș|albus|albuș|ovomucoida|lecitina\s+din\s+oua|lecitina\s+din\s+ouă)\b', caseSensitive: false),
      RegExp(r'\b(ou\s+intreg|ou\s+întreg|ou\s+de\s+gaina|ou\s+de\s+găină)\b', caseSensitive: false),
      // Engleză
      RegExp(r'\b(eggs?|egg|albumen|albumin|yolk|ovomucoid|egg\s+lecithin)\b', caseSensitive: false),
      RegExp(r'\b(whole\s+egg|egg\s+white|egg\s+yolk)\b', caseSensitive: false),
      // Germană
      RegExp(r'\b(eier?|ei|albumin|eigelb|eiweiss|eiweiß)\b', caseSensitive: false),
      // Franceză
      RegExp(r'\b(œufs?|oeuf|albumine|jaune|blanc)\b', caseSensitive: false),
    ],
    'peste': [
      RegExp(r'\b(peste|pești|ton|somon|cod|sardine|macrou|hering|anchoa|pastrav)\b', caseSensitive: false),
      RegExp(r'\b(fish|tuna|salmon|cod|sardines|mackerel|herring|anchovy|trout)\b', caseSensitive: false),
      RegExp(r'\b(fisch|thunfisch|lachs|kabeljau|sardinen|makrele|hering)\b', caseSensitive: false),
      RegExp(r'\b(poisson|thon|saumon|morue|sardines|maquereau|hareng)\b', caseSensitive: false),
    ],
    'crustacee': [
      RegExp(r'\b(crustacee|creveti|creveți|raci|homar|langusta|langustă|crab)\b', caseSensitive: false),
      RegExp(r'\b(crustaceans?|shrimp|prawns?|lobster|crab|crayfish|crawfish)\b', caseSensitive: false),
      RegExp(r'\b(krebstiere|garnelen|hummer|krebs)\b', caseSensitive: false),
      RegExp(r'\b(crustacés|crevettes|homard|crabe)\b', caseSensitive: false),
    ],
    'moluste': [
      RegExp(r'\b(moluste|moluște|scoici|stridii|caracatita|caracatiță|calamari|melci)\b', caseSensitive: false),
      RegExp(r'\b(molluscs?|mollusks?|mussels?|oysters?|octopus|squid|calamari|snails?|scallops)\b', caseSensitive: false),
      RegExp(r'\b(weichtiere|muscheln|austern|tintenfisch|schnecken)\b', caseSensitive: false),
      RegExp(r'\b(mollusques|moules|huîtres|pieuvre|calamar|escargots)\b', caseSensitive: false),
    ],
    'nuci': [
      RegExp(r'\b(nuci|alune|migdale|castane|fistic|caju|pecan|macadamia|braziliene)\b', caseSensitive: false),
      RegExp(r'\b(nuts?|almonds?|hazelnuts?|walnuts?|chestnuts?|pistachios?|cashews?|pecans?)\b', caseSensitive: false),
      RegExp(r'\b(brazil\s+nuts?|macadamia|pine\s+nuts?|nuci\s+de\s+pin)\b', caseSensitive: false),
      RegExp(r'\b(nüsse|mandeln|haselnüsse|walnüsse|kastanien|pistazien)\b', caseSensitive: false),
      RegExp(r'\b(noix|amandes|noisettes|châtaignes|pistaches|noix\s+de\s+cajou)\b', caseSensitive: false),
    ],
    'arahide': [
      RegExp(r'\b(arahide|cacahuete|cacahuète|alune\s+de\s+pamant|alune\s+de\s+pământ)\b', caseSensitive: false),
      RegExp(r'\b(peanuts?|groundnuts?|monkey\s+nuts?)\b', caseSensitive: false),
      RegExp(r'\b(erdnüsse|erdnuss)\b', caseSensitive: false),
      RegExp(r'\b(arachides?|cacahuètes?)\b', caseSensitive: false),
    ],
    'soia': [
      RegExp(r'\b(soia|tofu|lecitina\s+de\s+soia|proteina\s+de\s+soia|proteină\s+de\s+soia)\b', caseSensitive: false),
      RegExp(r'\b(soy|soya|soybeans?|soy\s+lecithin|soy\s+protein|tofu|tempeh|miso)\b', caseSensitive: false),
      RegExp(r'\b(soja|sojalecithin|sojaprotein|sojabohnen)\b', caseSensitive: false),
      RegExp(r'\b(soja|lécithine\s+de\s+soja|protéine\s+de\s+soja)\b', caseSensitive: false),
    ],
    'grau': [
      RegExp(r'\b(grau|grâu|faina|făină|gluten|amidon|bulgur|couscous|seitan)\b', caseSensitive: false),
      RegExp(r'\b(wheat|flour|gluten|starch|bulgur|couscous|seitan|vital\s+wheat\s+gluten)\b', caseSensitive: false),
      RegExp(r'\b(weizen|mehl|gluten|stärke|bulgur)\b', caseSensitive: false),
      RegExp(r'\b(blé|farine|gluten|amidon|boulgour)\b', caseSensitive: false),
    ],
    'secara': [
      RegExp(r'\b(secara|secară|rye|roggen|seigle)\b', caseSensitive: false),
    ],
    'orz': [
      RegExp(r'\b(orz|malt|malta|barley|gerste|orge)\b', caseSensitive: false),
    ],
    'ovaz': [
      RegExp(r'\b(ovaz|ovăz|oats?|avena|hafer|avoine)\b', caseSensitive: false),
    ],
    'susan': [
      RegExp(r'\b(susan|seminte\s+de\s+susan|semințe\s+de\s+susan|tahini|pasta\s+de\s+susan|ulei\s+de\s+susan)\b', caseSensitive: false),
      RegExp(r'\b(sesame|sesame\s+seeds?|sesame\s+oil|tahini)\b', caseSensitive: false),
      RegExp(r'\b(sesam|sesamsamen|sesamöl)\b', caseSensitive: false),
      RegExp(r'\b(sésame|graines\s+de\s+sésame|huile\s+de\s+sésame)\b', caseSensitive: false),
    ],
    'telina': [
      RegExp(r'\b(telina|țelină|celery|sellerie|céleri)\b', caseSensitive: false),
      RegExp(r'\b(celery\s+salt|sare\s+de\s+telina|sare\s+de\s+țelină)\b', caseSensitive: false),
    ],
    'mustar': [
      RegExp(r'\b(mustar|muștar|seminte\s+de\s+mustar|semințe\s+de\s+muștar)\b', caseSensitive: false),
      RegExp(r'\b(mustard|mustard\s+seeds?|dijon\s+mustard)\b', caseSensitive: false),
      RegExp(r'\b(senf|senfsamen|senfkörner)\b', caseSensitive: false),
      RegExp(r'\b(moutarde|graines\s+de\s+moutarde)\b', caseSensitive: false),
    ],
    'lupin': [
      RegExp(r'\b(lupin|lupine|faina\s+de\s+lupin|făină\s+de\s+lupin|lupin\s+beans?|boabe\s+de\s+lupin)\b', caseSensitive: false),
      RegExp(r'\b(lupin\s+flour|lupine\s+flour)\b', caseSensitive: false),
    ],
    'dioxid de sulf': [
      RegExp(r'\b(dioxid\s+de\s+sulf|sulfit|sulfiti|sulfiți|E-?22[0-8])\b', caseSensitive: false),
      RegExp(r'\b(sulfur\s+dioxide|sulphites?|sulfites?|E-?22[0-8])\b', caseSensitive: false),
      RegExp(r'\b(schwefeldioxid|sulfit|E-?22[0-8])\b', caseSensitive: false),
    ],
  };

  /// Detectează alergeni cu compatibilitate cu versiunea ta originală
  List<String> findAllergens(String text) {
    final matches = findAllergensDetailed(text);
    return matches.map((match) => match.allergen).toSet().toList();
  }

  /// Detectează alergeni cu informații detaliate - IMPROVED
  List<AllergenMatch> findAllergensDetailed(String text) {
    final List<AllergenMatch> matches = [];
    final normalizedText = _normalizeText(text.toLowerCase());

    // Verifică dacă textul conține cuvinte cheie pentru ingrediente
    final hasIngredientContext = _hasIngredientList(normalizedText);

    for (final entry in allergenVariants.entries) {
      final allergen = entry.key;
      final variants = entry.value;

      for (final regex in variants) {
        for (final match in regex.allMatches(normalizedText)) {
          final foundTerm = match.group(0)!;
          final position = match.start;

          final confidence = _calculateConfidence(normalizedText, foundTerm, position, hasIngredientContext);

          // Adaugă doar dacă confidence > 0.3, un prag mai mic pentru a prinde mai multe variante
          if (confidence > 0.3) {
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

  /// Normalizează textul pentru matching mai bun
  String _normalizeText(String text) {
    return text
        // Normalizează diacriticele românești
        .replaceAll(RegExp(r'[ăâ]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[șş]'), 's')
        .replaceAll(RegExp(r'[țţ]'), 't')
        // Normalizează diacriticele franceze
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûü]'), 'u')
        .replaceAll(RegExp(r'[œ]'), 'oe')
        .replaceAll(RegExp(r'[ç]'), 'c')
        // Normalizează diacriticele germane
        .replaceAll('ß', 'ss')
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        // Curăță spațiile multiple
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Verifică dacă textul pare să conțină o listă de ingrediente
  bool _hasIngredientList(String text) {
    return text.contains(RegExp(r'ingredien|składniki|compoziție|ingredients|zusammensetzung|ingrédients|contine|conține|contains|enthält|contient', caseSensitive: false));
  }

  /// Calculează confidence score pentru o potrivire - IMPROVED
  double _calculateConfidence(String text, String term, int position, bool hasIngredientContext) {
    double confidence = 0.6; // Base confidence mai mare

    // Boost dacă e în context de ingrediente
    if (hasIngredientContext) {
      confidence += 0.25;
    }

    // Boost pentru termeni mai specifici și lungi
    if (term.length >= 8) {
      confidence += 0.15;
    } else if (term.length >= 5) {
      confidence += 0.10;
    }

    // Verifică context pozitiv în jur
    if (_hasPositiveContext(text, position)) {
      confidence += 0.10;
    }

    // Penalizare pentru context negativ
    if (_hasNegativeContext(text, position)) {
      confidence -= 0.35;
    }

    // Penalizare pentru termeni foarte scurți doar în anumite cazuri
    if (term.length <= 3 && !hasIngredientContext) {
      confidence -= 0.15;
    }

    return confidence.clamp(0.1, 0.95);
  }

  /// Verifică context pozitiv în jurul termenului
  bool _hasPositiveContext(String text, int position) {
    final start = (position - 30).clamp(0, text.length);
    final end = (position + 30).clamp(0, text.length);
    final context = text.substring(start, end);

    const positiveWords = [
      'ingrediente', 'conține', 'contine', 'ingredients', 'contains',
      'poate conține', 'may contain', 'traces of', 'urme de',
      'zutaten', 'enthält', 'ingrédients', 'contient'
    ];

    return positiveWords.any((word) => context.contains(word));
  }

  /// Verifică context negativ în jurul termenului
  bool _hasNegativeContext(String text, int position) {
    final start = (position - 40).clamp(0, text.length);
    final end = (position + 40).clamp(0, text.length);
    final context = text.substring(start, end);

    const negativeWords = [
      'fără', 'fara', 'without', 'free', 'nu conține', 'nu contine', 'does not contain',
      'exempt de', 'exempt from', 'lipsă', 'absent', 'zero',
      'frei', 'sans', 'senza', 'sin', 'bez', 'nélkül',
      'gluten-free', 'lactose-free', 'dairy-free', 'nut-free', 'egg-free'
    ];

    return negativeWords.any((word) => context.contains(word));
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