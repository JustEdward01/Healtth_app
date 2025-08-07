import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class QualityAwareOcrService {
  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;
  
  /// Normalizează textul pentru matching mai bun - ENHANCED
  static String normalize(String input) {
    return input
        .toLowerCase()
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
        // Normalizează diacriticele poloneze
        .replaceAll(RegExp(r'[ąć]'), 'a')
        .replaceAll(RegExp(r'[ęė]'), 'e')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z')
        // Normalizează diacriticele italiene
        .replaceAll(RegExp(r'[àáâ]'), 'a')
        .replaceAll(RegExp(r'[èéê]'), 'e')
        .replaceAll(RegExp(r'[ìíî]'), 'i')
        .replaceAll(RegExp(r'[òóô]'), 'o')
        .replaceAll(RegExp(r'[ùúû]'), 'u')
        // Curăță spațiile multiple
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _isInitialized = true;
    }
  }

  /// Extrage text cu detectare automată a calității și feedback utilizator
  Future<EnhancedOcrResult> extractTextWithQualityCheck(File imageFile) async {
    await initialize();
    
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Normalizează textul pentru analiză mai bună
      final normalizedText = normalize(recognizedText.text);
      
      // Analizează calitatea rezultatului OCR
      final qualityAnalysis = _analyzeOcrQuality(recognizedText, normalizedText);
      
      return EnhancedOcrResult(
        text: normalizedText, // Returnează textul normalizat
        originalText: recognizedText.text, // Păstrează originalul pentru debug
        blocks: recognizedText.blocks,
        confidence: qualityAnalysis.confidence,
        hasText: recognizedText.text.isNotEmpty,
        qualityScore: qualityAnalysis.qualityScore,
        issues: qualityAnalysis.issues,
        suggestions: qualityAnalysis.suggestions,
        isReliable: qualityAnalysis.isReliable,
      );
      
    } catch (e) {
      return EnhancedOcrResult(
        text: '',
        originalText: '',
        blocks: [],
        confidence: 0.0,
        hasText: false,
        qualityScore: 0.0,
        issues: ['Eroare la procesarea imaginii: $e'],
        suggestions: ['Încearcă o altă imagine cu text mai clar'],
        isReliable: false,
      );
    }
  }

  /// Încearcă OCR pe multiple variante ale imaginii
  Future<EnhancedOcrResult> extractTextMultiAttempt(List<File> imageVariants) async {
    await initialize();
    
    EnhancedOcrResult? bestResult;
    double bestScore = 0.0;
    
    for (final imageFile in imageVariants) {
      try {
        final result = await extractTextWithQualityCheck(imageFile);
        final combinedScore = result.confidence * result.qualityScore;
        
        if (combinedScore > bestScore) {
          bestScore = combinedScore;
          bestResult = result;
        }
      } catch (e) {
        continue;
      }
    }
    
    return bestResult ?? EnhancedOcrResult(
      text: '',
      originalText: '',
      blocks: [],
      confidence: 0.0,
      hasText: false,
      qualityScore: 0.0,
      issues: ['Nu s-a putut citi textul din nicio variantă a imaginii'],
      suggestions: ['Fă o nouă poză cu lumină mai bună', 'Asigură-te că textul este în focus'],
      isReliable: false,
    );
  }

  /// Analizează calitatea rezultatului OCR - IMPROVED
  OcrQualityAnalysis _analyzeOcrQuality(RecognizedText recognizedText, String normalizedText) {
    final issues = <String>[];
    final suggestions = <String>[];
    double qualityScore = 1.0;
    
    // 1. Verifică dacă există text
    if (recognizedText.text.isEmpty) {
      issues.add('Nu s-a detectat niciun text');
      suggestions.add('Verifică dacă imaginea conține text vizibil');
      return OcrQualityAnalysis(
        confidence: 0.0,
        qualityScore: 0.0,
        issues: issues,
        suggestions: suggestions,
        isReliable: false,
      );
    }
    
    // 2. Verifică lungimea textului
    if (recognizedText.text.length < 10) {
      issues.add('Text foarte scurt detectat');
      suggestions.add('Textul pare incomplet - încearcă o imagine mai clară');
      qualityScore *= 0.5;
    }
    
    // 3. Analizează caracterele detectate - îmbunătățit
    final weirdCharCount = _countWeirdCharacters(normalizedText);
    final weirdCharRatio = normalizedText.isNotEmpty ? weirdCharCount / normalizedText.length : 0.0;
    
    if (weirdCharRatio > 0.3) {
      issues.add('Multe caractere nerecunoscute detectate');
      suggestions.add('Textul pare distorsionat - încearcă o imagine mai clară');
      qualityScore *= 0.3;
    } else if (weirdCharRatio > 0.1) {
      issues.add('Unele caractere pot fi incorecte');
      suggestions.add('Verifică manual textul detectat');
      qualityScore *= 0.7;
    }
    
    // 4. Verifică continuitatea textului
    final wordCount = normalizedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount < 3) {
      issues.add('Prea puține cuvinte detectate');
      suggestions.add('Pare să lipsească text - încearcă o imagine completă');
      qualityScore *= 0.6;
    }
    
    // 5. Detectează blocuri fragmentate
    if (recognizedText.blocks.length > 10 && normalizedText.length < 100) {
      issues.add('Text foarte fragmentat detectat');
      suggestions.add('Textul pare împrăștiat - încearcă o imagine mai focalizată');
      qualityScore *= 0.4;
    }
    
    // 6. Verifică dacă pare să conțină ingrediente - îmbunătățit
    final hasIngredientKeywords = _hasIngredientKeywords(normalizedText);
    if (!hasIngredientKeywords && normalizedText.length > 20) {
      issues.add('Nu par să fie ingrediente detectate');
      suggestions.add('Asigură-te că pozezi lista de ingrediente');
      qualityScore *= 0.8;
    }
    
    // 7. Verifică pentru indicii de calitate OCR slabă
    if (_hasLowQualityIndicators(normalizedText)) {
      issues.add('Posibile erori OCR detectate');
      suggestions.add('Încearcă o poză mai clară sau cu mai multă lumină');
      qualityScore *= 0.6;
    }
    
    // 8. Calculează confidence general
    double totalConfidence = 0.0;
    int blockCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // Estimăm confidence-ul pe baza caracteristicilor
        double lineConfidence = _estimateLineConfidence(line.text, normalizedText);
        totalConfidence += lineConfidence;
        blockCount++;
      }
    }
    
    final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;
    
    // Determinăm dacă rezultatul e de încredere
    final isReliable = qualityScore > 0.6 && avgConfidence > 0.7 && issues.length <= 1;
    
    return OcrQualityAnalysis(
      confidence: avgConfidence,
      qualityScore: qualityScore,
      issues: issues,
      suggestions: suggestions,
      isReliable: isReliable,
    );
  }

  /// Numără caracterele ciudate/nerecunoscute - IMPROVED
  int _countWeirdCharacters(String text) {
    // Pattern mai permisiv pentru caractere acceptabile
    final validChars = RegExp(r'[a-zA-Z0-9\s\.,;:\(\)\-\/\%\+\=\[\]àâäéèêëïîôöùûüÿçăâîșțñáéíóúüßäöüąćęłńóśźżœ]');
    int weirdCount = 0;
    
    for (int i = 0; i < text.length; i++) {
      if (!validChars.hasMatch(text[i])) {
        weirdCount++;
      }
    }
    
    return weirdCount;
  }

  /// Verifică dacă textul conține cuvinte cheie pentru ingrediente - ENHANCED
  bool _hasIngredientKeywords(String text) {
    final lowerText = normalize(text);
    final ingredientKeywords = [
      // Română
      'ingredient', 'ingrediente', 'contine', 'conține', 'lapte', 'gluten', 'oua', 'ouă', 'soia', 'nuci',
      // Engleză
      'ingredients', 'contains', 'milk', 'eggs', 'soy', 'nuts', 'wheat',
      // Germană
      'zutaten', 'enthält', 'milch', 'eier', 'soja', 'nüsse',
      // Franceză
      'ingrédients', 'contient', 'lait', 'oeufs', 'œufs', 'soja', 'noix',
      // Pattern-uri comune
      'e[0-9]{3,4}', // Additivi alimentari (E123, E456)
    ];
    
    return ingredientKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Detectează indicatori de calitate OCR slabă
  bool _hasLowQualityIndicators(String text) {
    // Pattern-uri care indică erori OCR frecvente
    final lowQualityPatterns = [
      RegExp(r'[il1|]{3,}'), // Confuzie între i, l, 1, |
      RegExp(r'[0oO]{3,}'), // Confuzie între 0, o, O
      RegExp(r'\b[a-z]{1,2}\b.*\b[a-z]{1,2}\b.*\b[a-z]{1,2}\b'), // Prea multe cuvinte de 1-2 litere
      RegExp(r'[^a-zA-Z0-9\s]{5,}'), // Șiruri lungi de caractere ciudate
    ];
    
    return lowQualityPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Estimează confidence-ul pentru o linie de text - IMPROVED
  double _estimateLineConfidence(String lineText, String normalizedText) {
    final normalizedLine = normalize(lineText);
    double confidence = 1.0;
    
    // Penalizează linii foarte scurte
    if (normalizedLine.length < 3) {
      confidence *= 0.3;
    } else if (normalizedLine.length < 6) {
      confidence *= 0.6;
    }
    
    // Penalizează caractere ciudate
    final weirdCharCount = _countWeirdCharacters(normalizedLine);
    final weirdRatio = normalizedLine.isNotEmpty ? weirdCharCount / normalizedLine.length : 0.0;
    confidence *= (1.0 - weirdRatio);
    
    // Premiază cuvinte cunoscute și pattern-uri alimentare
    final words = normalizedLine.split(RegExp(r'\s+'));
    final knownWords = words.where((word) => 
      word.length > 2 && _isKnownWord(word)
    ).length;
    
    if (words.isNotEmpty) {
      final knownRatio = knownWords / words.length;
      confidence *= (0.5 + knownRatio * 0.5);
    }
    
    // Bonus pentru context de ingrediente
    if (_hasIngredientKeywords(normalizedLine)) {
      confidence *= 1.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Verifică dacă un cuvânt pare cunoscut
  bool _isKnownWord(String word) {
    // Lista cuvintelor comune în contextul alimentar
    final commonWords = [
      // Română
      'faina', 'zahar', 'ulei', 'sare', 'lapte', 'apa', 'oua',
      // Engleză
      'flour', 'sugar', 'oil', 'salt', 'milk', 'water', 'eggs',
      // Germană
      'mehl', 'zucker', 'öl', 'salz', 'milch', 'wasser', 'eier',
      // Ingrediente comune
      'vitamina', 'vitamin', 'mineral', 'proteina', 'protein',
    ];
    
    return commonWords.contains(word) || 
           RegExp(r'^[a-z]{3,}$').hasMatch(word); // Cuvinte normale de 3+ litere
  }

  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}

/// Rezultat OCR îmbunătățit cu informații despre calitate
class EnhancedOcrResult {
  final String text;
  final String originalText; // ADDED: păstrează textul original
  final List<TextBlock> blocks;
  final double confidence;
  final bool hasText;
  final double qualityScore;
  final List<String> issues;
  final List<String> suggestions;
  final bool isReliable;

  EnhancedOcrResult({
    required this.text,
    required this.originalText,
    required this.blocks,
    required this.confidence,
    required this.hasText,
    required this.qualityScore,
    required this.issues,
    required this.suggestions,
    required this.isReliable,
  });
}

/// Analiză calitate OCR
class OcrQualityAnalysis {
  final double confidence;
  final double qualityScore;
  final List<String> issues;
  final List<String> suggestions;
  final bool isReliable;

  OcrQualityAnalysis({
    required this.confidence,
    required this.qualityScore,
    required this.issues,
    required this.suggestions,
    required this.isReliable,
  });
}