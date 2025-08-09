import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class EUAllergenDictionaryService {
 Map<String, dynamic>? _jsonData;
 Map<String, EUAllergenData>? _allergenDatabase;
 bool _isInitialized = false;

 bool get isInitialized => _isInitialized;
 Map<String, EUAllergenData>? get allergenDatabase => _allergenDatabase;

 Future<void> initialize() async {
   if (_isInitialized) return;
   
   // Încarcă JSON-ul
   final jsonString = await rootBundle.loadString('assets/complete_eu_allergen_dictionary.json');
   _jsonData = jsonDecode(jsonString);
   
   _allergenDatabase = _buildFromJson();
   _isInitialized = true;
   debugPrint('🗂️ EU Allergen Dictionary initialized with ${_allergenDatabase!.length} allergens');
 }

Map<String, EUAllergenData> _buildFromJson() {
  final database = <String, EUAllergenData>{};
  
  // FIX: În loc de forEach, folosește for-in
  final entries = _jsonData!.entries.toList();
  for (final entry in entries) {
    final key = entry.key;
    final data = entry.value;
    
    database[key] = EUAllergenData(
      euCode: _getEuCode(key),
      nameRO: _getRomanianName(data),
      nameEN: _getEnglishName(data),
      category: data['category'],
      riskLevel: data['risk_level'] ?? 'medium',
      isHighRisk: data['risk_level'] == 'high',
      euRegulation: data['eu_regulation'] ?? 'EU 1169/2011 Annex II',
      patterns: _buildPatterns(data),
    );
  }
  
  return database;
}

Map<String, List<String>> _buildPatterns(Map<String, dynamic> data) {
  final patterns = <String, List<String>>{};
  
  // FIX pentru primary_names
  if (data['primary_names'] != null) {
    final primaryEntries = (data['primary_names'] as Map).entries.toList();
    for (final entry in primaryEntries) {
      patterns[entry.key] = List<String>.from(entry.value);
    }
  }
  
  // FIX pentru derivatives
  if (data['derivatives'] != null) {
    final derivativeEntries = (data['derivatives'] as Map).entries.toList();
    for (final entry in derivativeEntries) {
      patterns[entry.key] = (patterns[entry.key] ?? [])..addAll(List<String>.from(entry.value));
    }
  }
  
  // FIX pentru technical_names
  if (data['technical_names'] != null) {
    final technicalEntries = (data['technical_names'] as Map).entries.toList();
    for (final entry in technicalEntries) {
      patterns[entry.key] = (patterns[entry.key] ?? [])..addAll(List<String>.from(entry.value));
    }
  }
  
  return patterns;
}

 String _getEuCode(String key) {
   final codes = {
     'cereals_gluten': 'A',
     'crustaceans': 'B', 
     'eggs': 'C',
     'fish': 'D',
     'peanuts': 'E',
     'soybeans': 'F',
     'milk': 'G',
     'tree_nuts': 'H',
     'celery': 'I',
     'mustard': 'J',
     'sesame': 'K',
     'sulphites': 'L',
     'lupin': 'M',
     'molluscs': 'N'
   };
   return codes[key] ?? 'X';
 }

 String _getRomanianName(Map<String, dynamic> data) {
   final roNames = data['primary_names']?['ro'] as List?;
   if (roNames != null && roNames.isNotEmpty) {
     return roNames.first.toString();
   }
   return _getEnglishName(data); // fallback
 }

 String _getEnglishName(Map<String, dynamic> data) {
   final enNames = data['primary_names']?['en'] as List?;
   if (enNames != null && enNames.isNotEmpty) {
     return enNames.first.toString();
   }
   return 'Unknown';
 }

 /// Detectează alergenii în text pentru limbile specificate
Future<List<EUAllergenMatch>> detectAllergens({
  required String text,
  required List<String> targetLanguages,  // Păstrează parametrul dar nu-l mai folosi
  double confidenceThreshold = 0.6,
}) async {
  if (!_isInitialized || _allergenDatabase == null) {
    await initialize();
  }

  final matches = <EUAllergenMatch>[];
  final lowerText = text.toLowerCase();

  final entries = _allergenDatabase!.entries.toList();
  
  for (final entry in entries) {
    final allergenKey = entry.key;
    final allergenData = entry.value;

    // CAUTĂ ÎN TOATE LIMBILE DISPONIBILE, NU DOAR targetLanguages
    final allLanguages = allergenData.patterns.keys.toList();
    
    for (final language in allLanguages) {
      final patterns = allergenData.patterns[language] ?? [];
      final patternList = List<String>.from(patterns);
      
      for (final pattern in patternList) {
        final regex = RegExp(r'\b' + RegExp.escape(pattern.toLowerCase()) + r'\b');
        final regexMatches = regex.allMatches(lowerText).toList();

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