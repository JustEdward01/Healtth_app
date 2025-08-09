// lib/services/negative_context_detector.dart
import '../services/user_service.dart';
import '../services/eu_allergen_dictionary_service.dart';
class EUResultHandler {
  final EUAllergenDictionaryService _allergenService = EUAllergenDictionaryService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _allergenService.initialize();
    _isInitialized = true;
  }

  Future<dynamic> analyzeSafety(String text) async {}

  // MOVE THIS METHOD HERE (from NegativeContextAwareAllergenDetector):
Future<List<String>> findAllergensSimple(String text) async {
  if (!_isInitialized) await initialize();
  
  print('🔍 TEXT ORIGINAL: "$text"');
  
  final matches = await _allergenService.detectAllergens(
    text: text, 
    targetLanguages: ['ro', 'en', 'de', 'fr']
  );
  
  print('🔍 MATCHES GĂSITE: ${matches.length}');
  for (var match in matches) {
    print('   - Cheie: ${match.allergenKey}');
    print('   - Termen găsit: "${match.foundTerm}"');
    print('   - Confidence: ${match.confidence}');
  }
  
  final userAllergens = UserService().currentUser?.selectedAllergens ?? [];
  print('🔍 ALERGENI USER: $userAllergens');
  
  final relevant = matches.where((match) => 
    userAllergens.contains(match.allergenKey)
  ).toList();  // ✅ .toList() rezolvă eroarea
  
  print('🔍 MATCHES RELEVANTE: ${relevant.length}');
  for (var match in relevant) {
    print('   - Relevant: ${match.allergenKey} -> ${match.allergenData.nameRO}');
  }
  
  return relevant.map((match) => match.allergenData.nameRO).toList();
}
}