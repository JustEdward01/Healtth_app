// lib/services/eu_allergen_dictionary_service.dart

import 'package:flutter/material.dart';

/// Service pentru gestionarea dicționarului de alergeni conform UE
class EUAllergenDictionaryService {
  Map<String, EUAllergenData>? _allergenDatabase;
  bool _isInitialized = false;

    bool get isInitialized => _isInitialized;
  Map<String, EUAllergenData>? get allergenDatabase => _allergenDatabase;

  /// Inițializează serviciul cu baza de date de alergeni
  Future<void> initialize() async {
    if (_isInitialized) return;

    _allergenDatabase = _buildAllergenDatabase();
    _isInitialized = true;
    debugPrint('🗂️ EU Allergen Dictionary initialized with ${_allergenDatabase!.length} allergens');
  }

  /// Detectează alergenii în text pentru limbile specificate
  Future<List<EUAllergenMatch>> detectAllergens({
    required String text,
    required List<String> targetLanguages,
    double confidenceThreshold = 0.6,
  }) async {
    if (!_isInitialized || _allergenDatabase == null) {
      await initialize();
    }

    final matches = <EUAllergenMatch>[];
    final lowerText = text.toLowerCase();

    for (final entry in _allergenDatabase!.entries) {
      final allergenKey = entry.key;
      final allergenData = entry.value;

      for (final language in targetLanguages) {
        final patterns = allergenData.patterns[language] ?? [];
        
        for (final pattern in patterns) {
          final regex = RegExp(r'\b' + RegExp.escape(pattern.toLowerCase()) + r'\b');
          final regexMatches = regex.allMatches(lowerText);

          for (final match in regexMatches) {
            final confidence = _calculateConfidence(
              text: lowerText,
              foundTerm: pattern,
              allergenData: allergenData,
              language: language,
            );

            if (confidence >= confidenceThreshold) {
              matches.add(EUAllergenMatch(
                allergenKey: allergenKey,
                allergenData: allergenData,
                foundTerm: match.group(0) ?? pattern,
                confidence: confidence,
                language: language,
                position: match.start,
                isHighRisk: allergenData.isHighRisk,
                euCode: allergenData.euCode,
              ));
            }
          }
        }
      }
    }

    // Sortează după confidence și elimină duplicatele
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return _removeDuplicateMatches(matches);
  }

  /// Obține datele pentru un alergen specific
  EUAllergenData? getAllergenData(String allergenKey) {
    return _allergenDatabase?[allergenKey];
  }

  /// Obține numele prietenos pentru un alergen în limba specificată
  String getFriendlyName(String allergenKey, String language) {
    final data = _allergenDatabase?[allergenKey];
    if (data == null) return allergenKey;

    switch (language) {
      case 'ro':
        return data.nameRO;
      case 'en':
        return data.nameEN;
      default:
        return data.nameEN;
    }
  }

  /// Obține lista alergenilor disponibili pentru o limbă
  List<String> getAvailableAllergensForLanguage(String language) {
    if (!_isInitialized || _allergenDatabase == null) return [];
    return _allergenDatabase!.keys.toList();
  }

  /// Calculează confidence-ul pentru o potrivire
  double _calculateConfidence({
    required String text,
    required String foundTerm,
    required EUAllergenData allergenData,
    required String language,
  }) {
    double confidence = 0.7; // Base confidence

    // Boost pentru termeni mai lungi (mai specifici)
    if (foundTerm.length >= 6) {
      confidence += 0.1;
    }

    // Boost pentru alergeni cu risc înalt
    if (allergenData.isHighRisk) {
      confidence += 0.1;
    }

    // Boost pentru context pozitiv (lângă "ingrediente")
    if (_hasPositiveContext(text, foundTerm)) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Verifică contextul pozitiv în jurul termenului
  bool _hasPositiveContext(String text, String term) {
    final termIndex = text.indexOf(term);
    if (termIndex == -1) return false;

    final start = (termIndex - 30).clamp(0, text.length);
    final end = (termIndex + term.length + 30).clamp(0, text.length);
    final context = text.substring(start, end);

    const positiveWords = [
      'ingrediente', 'ingredients', 'contains', 'conține',
      'zutaten', 'enthält', 'ingrédients', 'contient'
    ];

    return positiveWords.any((word) => context.contains(word));
  }

  /// Elimină duplicatele pentru același alergen
  List<EUAllergenMatch> _removeDuplicateMatches(List<EUAllergenMatch> matches) {
    final Map<String, EUAllergenMatch> uniqueMatches = {};

    for (final match in matches) {
      if (!uniqueMatches.containsKey(match.allergenKey) ||
          uniqueMatches[match.allergenKey]!.confidence < match.confidence) {
        uniqueMatches[match.allergenKey] = match;
      }
    }

    return uniqueMatches.values.toList();
  }

  /// Construiește baza de date de alergeni conform UE
  Map<String, EUAllergenData> _buildAllergenDatabase() {
    return {
      'cereals': EUAllergenData(
        euCode: 'A',
        nameRO: 'Cereale cu gluten',
        nameEN: 'Cereals containing gluten',
        category: 'grains',
        riskLevel: 'high',
        isHighRisk: true,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['grau', 'grâu', 'faina', 'făină', 'gluten', 'orz', 'ovaz', 'ovăz', 'secara', 'secară'],
          'en': ['wheat', 'flour', 'gluten', 'barley', 'oats', 'rye', 'spelt'],
          'de': ['weizen', 'mehl', 'gluten', 'gerste', 'hafer', 'roggen'],
          'fr': ['blé', 'farine', 'gluten', 'orge', 'avoine', 'seigle'],
          'it': ['grano', 'farina', 'glutine', 'orzo', 'avena', 'segale'],
          'es': ['trigo', 'harina', 'gluten', 'cebada', 'avena', 'centeno'],
          'hu': ['búza', 'liszt', 'glutén', 'árpa', 'zab', 'rozs'],
          'pl': ['pszenica', 'mąka', 'gluten', 'jęczmień', 'owies', 'żyto'],
        },
      ),

      'crustaceans': EUAllergenData(
        euCode: 'B',
        nameRO: 'Crustacee',
        nameEN: 'Crustaceans',
        category: 'seafood',
        riskLevel: 'high',
        isHighRisk: true,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['crustacee', 'creveti', 'creveți', 'raci', 'homar', 'crab'],
          'en': ['crustaceans', 'shrimp', 'prawns', 'lobster', 'crab', 'crayfish'],
          'de': ['krebstiere', 'garnelen', 'hummer', 'krabbe'],
          'fr': ['crustacés', 'crevettes', 'homard', 'crabe'],
          'it': ['crostacei', 'gamberetti', 'aragosta', 'granchio'],
          'es': ['crustáceos', 'camarones', 'langosta', 'cangrejo'],
          'hu': ['rákfélék', 'garnélarák', 'homár', 'rák'],
          'pl': ['skorupiaki', 'krewetki', 'homar', 'krab'],
        },
      ),

      'eggs': EUAllergenData(
        euCode: 'C',
        nameRO: 'Ouă',
        nameEN: 'Eggs',
        category: 'animal_products',
        riskLevel: 'high',
        isHighRisk: true,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['oua', 'ouă', 'ou', 'galbenus', 'gălbenuș', 'albus', 'albuș'],
          'en': ['eggs', 'egg', 'albumen', 'yolk', 'egg white', 'egg yolk'],
          'de': ['eier', 'ei', 'eigelb', 'eiweiß'],
          'fr': ['œufs', 'oeuf', 'jaune', 'blanc'],
          'it': ['uova', 'uovo', 'tuorlo', 'albume'],
          'es': ['huevos', 'huevo', 'yema', 'clara'],
          'hu': ['tojás', 'tojásfehérje', 'tojássárgája'],
          'pl': ['jaja', 'jajko', 'żółtko', 'białko'],
        },
      ),

      'fish': EUAllergenData(
        euCode: 'D',
        nameRO: 'Pește',
        nameEN: 'Fish',
        category: 'seafood',
        riskLevel: 'medium',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['peste', 'pești', 'ton', 'somon', 'cod', 'sardine'],
          'en': ['fish', 'tuna', 'salmon', 'cod', 'sardines', 'trout'],
          'de': ['fisch', 'thunfisch', 'lachs', 'kabeljau'],
          'fr': ['poisson', 'thon', 'saumon', 'morue'],
          'it': ['pesce', 'tonno', 'salmone', 'merluzzo'],
          'es': ['pescado', 'atún', 'salmón', 'bacalao'],
          'hu': ['hal', 'tonhal', 'lazac', 'tőkehal'],
          'pl': ['ryba', 'tuńczyk', 'łosoś', 'dorsz'],
        },
      ),

      'peanuts': EUAllergenData(
        euCode: 'E',
        nameRO: 'Arahide',
        nameEN: 'Peanuts',
        category: 'nuts_seeds',
        riskLevel: 'high',
        isHighRisk: true,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['arahide', 'alune de pamant', 'alune de pământ'],
          'en': ['peanuts', 'peanut', 'groundnuts'],
          'de': ['erdnüsse', 'erdnuss'],
          'fr': ['arachides', 'cacahuètes'],
          'it': ['arachidi', 'noccioline americane'],
          'es': ['cacahuetes', 'maní'],
          'hu': ['földimogyoró'],
          'pl': ['orzeszki ziemne', 'fistaszki'],
        },
      ),

      'soybeans': EUAllergenData(
        euCode: 'F',
        nameRO: 'Soia',
        nameEN: 'Soybeans',
        category: 'legumes',
        riskLevel: 'medium',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['soia', 'tofu', 'lecitina de soia'],
          'en': ['soy', 'soya', 'soybeans', 'soy lecithin', 'tofu'],
          'de': ['soja', 'sojalecithin', 'tofu'],
          'fr': ['soja', 'lécithine de soja', 'tofu'],
          'it': ['soia', 'lecitina di soia', 'tofu'],
          'es': ['soja', 'lecitina de soja', 'tofu'],
          'hu': ['szója', 'szója lecitin', 'tofu'],
          'pl': ['soja', 'lecytyna sojowa', 'tofu'],
        },
      ),

      'milk': EUAllergenData(
        euCode: 'G',
        nameRO: 'Lapte',
        nameEN: 'Milk',
        category: 'dairy',
        riskLevel: 'high',
        isHighRisk: true,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['lapte', 'lactoza', 'cazeina', 'zer', 'smantana', 'smântână', 'branza', 'brânza', 'unt'],
          'en': ['milk', 'lactose', 'casein', 'whey', 'cream', 'cheese', 'butter', 'dairy'],
          'de': ['milch', 'laktose', 'kasein', 'molke', 'sahne', 'käse', 'butter'],
          'fr': ['lait', 'lactose', 'caséine', 'petit-lait', 'crème', 'fromage', 'beurre'],
          'it': ['latte', 'lattosio', 'caseina', 'siero', 'panna', 'formaggio', 'burro'],
          'es': ['leche', 'lactosa', 'caseína', 'suero', 'nata', 'queso', 'mantequilla'],
          'hu': ['tej', 'laktóz', 'kazein', 'tejsavó', 'sajt', 'vaj'],
          'pl': ['mleko', 'laktoza', 'kazeina', 'serwatka', 'ser', 'masło'],
        },
      ),

      'nuts': EUAllergenData(
        euCode: 'H',
        nameRO: 'Nuci',
        nameEN: 'Tree nuts',
        category: 'nuts_seeds',
        riskLevel: 'high',
        isHighRisk: true,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['nuci', 'alune', 'migdale', 'castane', 'fistic', 'caju'],
          'en': ['nuts', 'almonds', 'hazelnuts', 'walnuts', 'cashews', 'pistachios'],
          'de': ['nüsse', 'mandeln', 'haselnüsse', 'walnüsse'],
          'fr': ['noix', 'amandes', 'noisettes', 'noix de cajou'],
          'it': ['noci', 'mandorle', 'nocciole', 'anacardi'],
          'es': ['nueces', 'almendras', 'avellanas', 'anacardos'],
          'hu': ['dió', 'mandula', 'mogyoró', 'kesudió'],
          'pl': ['orzechy', 'migdały', 'orzechy laskowe', 'nerkowce'],
        },
      ),

      'celery': EUAllergenData(
        euCode: 'I',
        nameRO: 'Țelină',
        nameEN: 'Celery',
        category: 'vegetables',
        riskLevel: 'low',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['telina', 'țelină'],
          'en': ['celery', 'celery salt'],
          'de': ['sellerie', 'selleriesalz'],
          'fr': ['céleri', 'sel de céleri'],
          'it': ['sedano', 'sale di sedano'],
          'es': ['apio', 'sal de apio'],
          'hu': ['zeller', 'zellersó'],
          'pl': ['seler', 'sól selerowa'],
        },
      ),

      'mustard': EUAllergenData(
        euCode: 'J',
        nameRO: 'Muștar',
        nameEN: 'Mustard',
        category: 'spices',
        riskLevel: 'low',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['mustar', 'muștar', 'seminte de mustar'],
          'en': ['mustard', 'mustard seeds'],
          'de': ['senf', 'senfkörner'],
          'fr': ['moutarde', 'graines de moutarde'],
          'it': ['senape', 'semi di senape'],
          'es': ['mostaza', 'semillas de mostaza'],
          'hu': ['mustár', 'mustármag'],
          'pl': ['gorczyca', 'nasiona gorczycy'],
        },
      ),

      'sesame': EUAllergenData(
        euCode: 'K',
        nameRO: 'Susan',
        nameEN: 'Sesame',
        category: 'nuts_seeds',
        riskLevel: 'medium',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['susan', 'seminte de susan', 'tahini'],
          'en': ['sesame', 'sesame seeds', 'tahini'],
          'de': ['sesam', 'sesamsamen', 'tahini'],
          'fr': ['sésame', 'graines de sésame', 'tahini'],
          'it': ['sesamo', 'semi di sesamo', 'tahini'],
          'es': ['sésamo', 'semillas de sésamo', 'tahini'],
          'hu': ['szezám', 'szezámmag', 'tahini'],
          'pl': ['sezam', 'nasiona sezamu', 'tahini'],
        },
      ),

      'sulphites': EUAllergenData(
        euCode: 'L',
        nameRO: 'Sulfiți',
        nameEN: 'Sulphites',
        category: 'additives',
        riskLevel: 'medium',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['sulfiti', 'sulfiți', 'dioxid de sulf', 'E220', 'E221', 'E222'],
          'en': ['sulphites', 'sulfites', 'sulfur dioxide', 'E220', 'E221', 'E222'],
          'de': ['sulfite', 'schwefeldioxid', 'E220', 'E221', 'E222'],
          'fr': ['sulfites', 'dioxyde de soufre', 'E220', 'E221', 'E222'],
          'it': ['solfiti', 'diossido di zolfo', 'E220', 'E221', 'E222'],
          'es': ['sulfitos', 'dióxido de azufre', 'E220', 'E221', 'E222'],
          'hu': ['szulfitok', 'kén-dioxid', 'E220', 'E221', 'E222'],
          'pl': ['siarczyny', 'dwutlenek siarki', 'E220', 'E221', 'E222'],
        },
      ),

      'lupin': EUAllergenData(
        euCode: 'M',
        nameRO: 'Lupin',
        nameEN: 'Lupin',
        category: 'legumes',
        riskLevel: 'low',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['lupin', 'faina de lupin'],
          'en': ['lupin', 'lupine', 'lupin flour'],
          'de': ['lupine', 'lupinenmehl'],
          'fr': ['lupin', 'farine de lupin'],
          'it': ['lupino', 'farina di lupino'],
          'es': ['altramuz', 'harina de altramuz'],
          'hu': ['csillagfürt', 'csillagfürt liszt'],
          'pl': ['łubin', 'mąka z łubinu'],
        },
      ),

      'molluscs': EUAllergenData(
        euCode: 'N',
        nameRO: 'Moluște',
        nameEN: 'Molluscs',
        category: 'seafood',
        riskLevel: 'medium',
        isHighRisk: false,
        euRegulation: 'EU 1169/2011 Annex II',
        patterns: {
          'ro': ['moluste', 'moluște', 'scoici', 'midii', 'caracatita'],
          'en': ['molluscs', 'mollusks', 'mussels', 'oysters', 'squid', 'octopus'],
          'de': ['weichtiere', 'muscheln', 'austern', 'tintenfisch'],
          'fr': ['mollusques', 'moules', 'huîtres', 'calmar', 'pieuvre'],
          'it': ['molluschi', 'cozze', 'ostriche', 'calamari', 'polpo'],
          'es': ['moluscos', 'mejillones', 'ostras', 'calamar', 'pulpo'],
          'hu': ['puhatestűek', 'kagyló', 'osztriga', 'tintahal'],
          'pl': ['mięczaki', 'małże', 'ostrygi', 'kalmary', 'ośmiornica'],
        },
      ),
    };
  }
}

/// Model pentru datele unui alergen conform standardelor UE
class EUAllergenData {
  final String euCode;
  final String nameRO;
  final String nameEN;
  final String category;
  final String riskLevel;
  final bool isHighRisk;
  final String euRegulation;
  final Map<String, List<String>> patterns;

  EUAllergenData({
    required this.euCode,
    required this.nameRO,
    required this.nameEN,
    required this.category,
    required this.riskLevel,
    required this.isHighRisk,
    required this.euRegulation,
    required this.patterns,
  });

  /// Obține toate numele pentru o limbă specificată
  List<String> getAllNamesForLanguage(String language) {
    final names = <String>[];
    
    // Adaugă numele oficial
    if (language == 'ro') {
      names.add(nameRO);
    } else if (language == 'en') {
      names.add(nameEN);
    }
    
    // Adaugă pattern-urile pentru limba respectivă
    final languagePatterns = patterns[language] ?? [];
    names.addAll(languagePatterns);
    
    return names;
  }
}

/// Model pentru o potrivire de alergen detectată
class EUAllergenMatch {
  final String allergenKey;
  final EUAllergenData allergenData;
  final String foundTerm;
  final double confidence;
  final String language;
  final int position;
  final bool isHighRisk;
  final String euCode;

  EUAllergenMatch({
    required this.allergenKey,
    required this.allergenData,
    required this.foundTerm,
    required this.confidence,
    required this.language,
    required this.position,
    required this.isHighRisk,
    required this.euCode,
  });

  @override
  String toString() {
    return 'EUAllergenMatch(${allergenData.nameEN}: "$foundTerm" @${(confidence * 100).toInt()}%)';
  }
}