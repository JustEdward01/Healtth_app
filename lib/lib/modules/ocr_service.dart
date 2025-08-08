// ocr_service.dart

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/user_service.dart';
import '../services/ocr_text_sorter.dart';

/// Model pentru rezultatul OCR cu informații detaliate și filtrare pe limbă
class OcrResult {
  final String text;
  final List<TextBlock> blocks;
  final double confidence;
  final bool hasText;
  final String? error;
  final String? languageDetected;
  final String? originalText; // Pentru debug

  OcrResult({
    required this.text,
    required this.blocks,
    required this.confidence,
    required this.hasText,
    this.error,
    this.languageDetected,
    this.originalText,
  });
}

class OcrService {
  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;
  final UserService _userService = UserService();
  final OcrTextSorter _textSorter = OcrTextSorter();

  // Pattern-uri pentru detectarea limbilor
  static final Map<String, Set<String>> _languagePatterns = {
    'ro': {'ă', 'â', 'î', 'ș', 'ț', 'în', 'de', 'cu', 'la', 'pe', 'si', 'sau', 'ingrediente', 'conține'},
    'en': {'the', 'and', 'or', 'with', 'from', 'contains', 'may', 'wheat', 'ingredients'},
    'de': {'und', 'oder', 'mit', 'von', 'enthält', 'kann', 'weizen', 'zutaten', 'ß'},
    'fr': {'et', 'ou', 'avec', 'de', 'contient', 'peut', 'blé', 'ingrédients', 'é', 'è', 'ç'},
    'it': {'e', 'o', 'con', 'di', 'contiene', 'può', 'grano', 'ingredienti', 'à', 'è', 'ù'},
    'es': {'y', 'o', 'con', 'de', 'contiene', 'puede', 'trigo', 'ingredientes', 'ñ', 'á', 'é'},
    'hu': {'és', 'vagy', 'val', 'ból', 'tartalmaz', 'lehet', 'búza', 'összetevők', 'ő', 'ű'},
    'pl': {'i', 'lub', 'z', 'od', 'zawiera', 'może', 'pszenica', 'składniki', 'ą', 'ę', 'ł'},
    'ru': {'и', 'или', 'с', 'от', 'содержит', 'может', 'пшеница', 'состав', 'ы', 'э', 'я'},
    'tr': {'ve', 'veya', 'ile', 'den', 'içerir', 'olabilir', 'buğday', 'içindekiler', 'ğ', 'ş', 'ı'},
  };

  static final Map<String, RegExp> _diacriticsRegex = {
    'ro': RegExp(r'[ăâîșț]'),
    'de': RegExp(r'[ßäöü]'),
    'fr': RegExp(r'[àâäéèêëïîôöùûüÿç]'),
    'it': RegExp(r'[àèéìíîòóùú]'),
    'es': RegExp(r'[áéíóúüñ]'),
    'hu': RegExp(r'[áéíóöőúüű]'),
    'pl': RegExp(r'[ąćęłńóśźż]'),
    'ru': RegExp(r'[ёъьэюя]'),
    'tr': RegExp(r'[çğıöşü]'),
  };

  /// Inițializează serviciul cu configurări pentru limba română și engleză
  Future<void> initialize({TextRecognitionScript script = TextRecognitionScript.latin}) async {
    if (!_isInitialized) {
      _textRecognizer = TextRecognizer(script: script);
      _isInitialized = true;
    }
  }

  /// Extrage text simplu din imagine cu filtrare pe limba utilizatorului
  Future<String> extractText(File imageFile) async {
    try {
      final result = await extractTextWithLanguageFilter(imageFile);
      return result.text;
    } catch (e) {
      throw Exception('Eroare la extragerea textului: $e');
    }
  }

  /// Extrage text cu filtrare pe limba utilizatorului
  Future<OcrResult> extractTextWithLanguageFilter(File imageFile) async {
    try {
      await initialize();

      if (!await imageFile.exists()) {
        throw Exception('Fișierul imagine nu există');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return OcrResult(
          text: '',
          blocks: [],
          confidence: 0.0,
          hasText: false,
          error: 'Nu s-a detectat text în imagine',
        );
      }

      // Obține limba utilizatorului din profil
      final userLanguage = _getUserLanguage();

      // Filtrează textul pentru limba utilizatorului
      final FilteredLanguageResult filteredResult = _filterTextByUserLanguage(recognizedText, userLanguage);

      // Sortează și formatează textul filtrat pentru a asigura ordinea corectă
      final sortedText = _textSorter.sortAndFormatText(recognizedText);

      return OcrResult(
        text: sortedText,
        blocks: filteredResult.blocks,
        confidence: filteredResult.confidence,
        hasText: sortedText.isNotEmpty,
        languageDetected: userLanguage,
        originalText: recognizedText.text, // Pentru debug
      );
    } catch (e) {
      return OcrResult(
        text: '',
        blocks: [],
        confidence: 0.0,
        hasText: false,
        error: e.toString(),
      );
    }
  }

  /// Extrage text cu informații detaliate (versiunea originală pentru compatibilitate)
  Future<OcrResult> extractTextDetailed(File imageFile) async {
    return await extractTextWithLanguageFilter(imageFile);
  }

  /// Extrage doar textul relevant pentru ingrediente cu filtrare pe limbă
  Future<String> extractIngredients(File imageFile) async {
    try {
      final result = await extractTextWithLanguageFilter(imageFile);

      if (!result.hasText) {
        return '';
      }

      // Obține limba utilizatorului
      final userLanguage = _getUserLanguage();

      // Caută secțiuni cu ingrediente folosind cuvinte în limba utilizatorului
      return _extractIngredientsForLanguage(result.text, userLanguage);
    } catch (e) {
      throw Exception('Eroare la extragerea ingredientelor: $e');
    }
  }

  /// Obține limba utilizatorului din UserService
  String _getUserLanguage() {
    try {
      return _userService.currentUser?.preferences.language ?? 'ro';
    } catch (e) {
      return 'ro'; // Default română
    }
  }

  /// Filtrează textul pentru limba specificată
  FilteredLanguageResult _filterTextByUserLanguage(RecognizedText recognizedText, String targetLanguage) {
  final filteredBlocks = <TextBlock>[];
  double totalConfidence = 0.0;
  int validBlocksCount = 0;

  for (final block in recognizedText.blocks) {
    // Creează un bloc nou, gol, pentru a adăuga liniile filtrate
    final filteredBlock = TextBlock(
      text: '',
      lines: [],
      recognizedLanguages: [], // Le vom adăuga manual
      boundingBox: block.boundingBox,
      cornerPoints: block.cornerPoints,
    );

    double blockConfidence = 0.0;
    int validLinesInBlock = 0;

    for (final line in block.lines) {
      final lineText = line.text.trim();

      if (lineText.isEmpty) continue;

      final languageScore = _calculateLanguageScore(lineText, targetLanguage);

      // Verificăm dacă scorul limbii este suficient de mare
      if (languageScore >= 0.4) { // Am mărit pragul la 0.4 pentru a fi mai selectivi
        // Adăugăm doar linia care se potrivește
        filteredBlock.lines.add(line);
        blockConfidence += languageScore;
        validLinesInBlock++;
      }
    }

    // Adaugă blocul filtrat doar dacă conține linii relevante
    if (validLinesInBlock > 0) {
      // Calculăm confidence-ul mediu pentru acest bloc
      final averageBlockConfidence = blockConfidence / validLinesInBlock;
      
      // Creează un TextBlock final cu textul corect și confidence-ul calculat
      final finalFilteredBlock = TextBlock(
        text: filteredBlock.lines.map((l) => l.text).join('\n'),
        lines: filteredBlock.lines,
        recognizedLanguages: [targetLanguage],
        boundingBox: filteredBlock.boundingBox,
        cornerPoints: filteredBlock.cornerPoints,
      );

      filteredBlocks.add(finalFilteredBlock);
      totalConfidence += averageBlockConfidence;
      validBlocksCount++;
    }
  }

  // Calculează confidence-ul mediu general
  final averageConfidence = validBlocksCount > 0 ? totalConfidence / validBlocksCount : 0.0;

  return FilteredLanguageResult(
    text: '', // Textul va fi construit ulterior de către `OcrTextSorter`
    blocks: filteredBlocks,
    confidence: averageConfidence,
  );
}

  /// Calculează scorul pentru limba specificată
  double _calculateLanguageScore(String text, String targetLanguage) {
    double score = 0.0;
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    // 1. Verifică diacriticele specifice limbii (40% din scor)
    final diacriticsRegex = _diacriticsRegex[targetLanguage];
    if (diacriticsRegex != null) {
      final diacriticsMatches = diacriticsRegex.allMatches(text).length;
      final diacriticsScore = text.isNotEmpty ? (diacriticsMatches / text.length).clamp(0.0, 1.0) : 0.0;
      score += diacriticsScore * 0.4;
    }

    // 2. Verifică cuvintele comune (50% din scor)
    final commonWords = _languagePatterns[targetLanguage] ?? {};
    int matchingWords = 0;

    for (final word in words) {
      if (commonWords.any((commonWord) => word.contains(commonWord) || commonWord.contains(word))) {
        matchingWords++;
      }
    }

    final wordScore = words.isNotEmpty ? (matchingWords / words.length).clamp(0.0, 1.0) : 0.0;
    score += wordScore * 0.5;

    // 3. Verifică pattern-urile morfologice (10% din scor)
    final morphologyScore = _calculateMorphologyScore(text, targetLanguage);
    score += morphologyScore * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Calculează scorul morfologic pentru limba specificată
  double _calculateMorphologyScore(String text, String targetLanguage) {
    switch (targetLanguage) {
      case 'ro':
        final romanianEndings = RegExp(r'(ului|ilor|ării|ească|enii|urile)');
        return romanianEndings.hasMatch(text.toLowerCase()) ? 1.0 : 0.0;

      case 'en':
        final englishEndings = RegExp(r'(ing|tion|ness|ment|able|ful)');
        return englishEndings.hasMatch(text.toLowerCase()) ? 1.0 : 0.0;

      case 'de':
        final germanEndings = RegExp(r'(ung|keit|heit|lich|isch|schaft)');
        return germanEndings.hasMatch(text.toLowerCase()) ? 1.0 : 0.0;

      case 'fr':
        final frenchEndings = RegExp(r'(tion|ment|eur|euse|ique)');
        return frenchEndings.hasMatch(text.toLowerCase()) ? 1.0 : 0.0;

      case 'ru':
        final russianEndings = RegExp(r'(ство|ость|ение|ание)');
        return russianEndings.hasMatch(text.toLowerCase()) ? 1.0 : 0.0;

      case 'tr':
        final turkishEndings = RegExp(r'(lar|ler|lık|lik|cık|cik)');
        return turkishEndings.hasMatch(text.toLowerCase()) ? 1.0 : 0.0;

      default:
        return 0.0;
    }
  }

  /// Calculează confidence score bazat pe rezultatele OCR (din versiunea originală)
 

  /// Extrage ingrediente pentru limba specificată
  String _extractIngredientsForLanguage(String text, String language) {
    final lowerText = text.toLowerCase();
    final lines = lowerText.split('\n');

    // Cuvinte cheie pentru "ingrediente" în diferite limbi
    final ingredientKeywords = {
      'ro': ['ingredient', 'conține', 'compoziție'],
      'en': ['ingredients', 'contains', 'composition'],
      'de': ['zutaten', 'enthält', 'zusammensetzung'],
      'fr': ['ingrédients', 'contient', 'composition'],
      'it': ['ingredienti', 'contiene', 'composizione'],
      'es': ['ingredientes', 'contiene', 'composición'],
      'hu': ['összetevők', 'tartalmaz', 'összetétel'],
      'pl': ['składniki', 'zawiera', 'skład'],
      'ru': ['состав', 'содержит', 'ингредиенты'],
      'tr': ['içindekiler', 'içerir', 'bileşenler'],
    };

    final keywords = ingredientKeywords[language] ?? ingredientKeywords['en']!;

    String ingredients = '';
    bool foundIngredients = false;

    for (String line in lines) {
      final trimmedLine = line.trim();

      // Detectează începutul listei de ingrediente
      if (!foundIngredients && keywords.any((keyword) => trimmedLine.contains(keyword))) {
        foundIngredients = true;
        // Dacă linia conține și ingredientele, le adaugă
        if (trimmedLine.length > 20) {
          ingredients += '$trimmedLine ';
        }
        continue;
      }

      // Detectează sfârșitul listei de ingrediente
      if (foundIngredients && _isEndOfIngredients(trimmedLine, language)) {
        break;
      }

      // Adaugă linia dacă suntem în secțiunea ingrediente
      if (foundIngredients && trimmedLine.isNotEmpty && trimmedLine.length > 3) {
        ingredients += '$trimmedLine ';
      }
    }

    return ingredients.trim();
  }

  /// Verifică dacă linia marchează sfârșitul ingredientelor
  bool _isEndOfIngredients(String line, String language) {
    final endKeywords = {
      'ro': ['nutritional', 'valori', 'energie', 'calorii'],
      'en': ['nutritional', 'nutrition', 'values', 'energy', 'calories'],
      'de': ['nährwert', 'energie', 'kalorien'],
      'fr': ['nutritionnel', 'valeurs', 'énergie', 'calories'],
      'it': ['nutrizional', 'valori', 'energia', 'calorie'],
      'es': ['nutricional', 'valores', 'energía', 'calorías'],
      'hu': ['tápérték', 'energia', 'kalória'],
      'pl': ['wartość', 'energia', 'kalorie'],
      'ru': ['пищевая', 'энергия', 'калории'],
      'tr': ['beslenme', 'enerji', 'kalori'],
    };

    final keywords = endKeywords[language] ?? endKeywords['en']!;
    return keywords.any((keyword) => line.contains(keyword));
  }

  /// Verifică calitatea OCR pentru o imagine
  Future<bool> isGoodQuality(File imageFile) async {
    try {
      final result = await extractTextWithLanguageFilter(imageFile);
      return result.confidence > 0.4 && result.hasText;
    } catch (e) {
      return false;
    }
  }

  /// Curăță textul OCR de caractere nedorite
  String cleanText(String rawText) {
    return rawText
        .replaceAll(RegExp(r'[^\w\s\.,;:\(\)\-\/àâäéèêëïîôöùûüÿçăâîșțñáéíóúüßäöüąćęłńóśźż]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Verifică dacă serviciul este inițializat
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}

/// Rezultatul filtrării pe limba specificată
class FilteredLanguageResult {
  final String text;
  final List<TextBlock> blocks;
  final double confidence;

  FilteredLanguageResult({
    required this.text,
    required this.blocks,
    required this.confidence,
  });
}