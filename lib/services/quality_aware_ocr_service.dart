import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class QualityAwareOcrService {
  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

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
      
      // Analizează calitatea rezultatului OCR
      final qualityAnalysis = _analyzeOcrQuality(recognizedText);
      
      return EnhancedOcrResult(
        text: recognizedText.text,
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
      blocks: [],
      confidence: 0.0,
      hasText: false,
      qualityScore: 0.0,
      issues: ['Nu s-a putut citi textul din nicio variantă a imaginii'],
      suggestions: ['Fă o nouă poză cu lumină mai bună', 'Asigură-te că textul este în focus'],
      isReliable: false,
    );
  }

  /// Analizează calitatea rezultatului OCR
  OcrQualityAnalysis _analyzeOcrQuality(RecognizedText recognizedText) {
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
    
    // 3. Analizează caracterele detectate
    final weirdCharCount = _countWeirdCharacters(recognizedText.text);
    final weirdCharRatio = weirdCharCount / recognizedText.text.length;
    
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
    final wordCount = recognizedText.text.split(RegExp(r'\s+')).length;
    if (wordCount < 3) {
      issues.add('Prea puține cuvinte detectate');
      suggestions.add('Pare să lipsească text - încearcă o imagine completă');
      qualityScore *= 0.6;
    }
    
    // 5. Detectează blocuri fragmentate
    if (recognizedText.blocks.length > 10 && recognizedText.text.length < 100) {
      issues.add('Text foarte fragmentat detectat');
      suggestions.add('Textul pare împrăștiat - încearcă o imagine mai focalizată');
      qualityScore *= 0.4;
    }
    
    // 6. Verifică dacă pare să conțină ingrediente
    final hasIngredientKeywords = _hasIngredientKeywords(recognizedText.text);
    if (!hasIngredientKeywords && recognizedText.text.length > 20) {
      issues.add('Nu par să fie ingrediente detectate');
      suggestions.add('Asigură-te că pozezi lista de ingrediente');
      qualityScore *= 0.8;
    }
    
    // 7. Calculează confidence general
    double totalConfidence = 0.0;
    int blockCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // ML Kit nu oferă confidence direct, estimăm pe baza caracteristicilor
        double lineConfidence = _estimateLineConfidence(line.text);
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

  /// Numără caracterele ciudate/nerecunoscute
  int _countWeirdCharacters(String text) {
    final weirdChars = RegExp(r'[^\w\s\.,;:\(\)\-\/àâäéèêëïîôöùûüÿçăâîșțñáéíóúüßäöüąćęłńóśźż]');
    return weirdChars.allMatches(text).length;
  }

  /// Verifică dacă textul conține cuvinte cheie pentru ingrediente
  bool _hasIngredientKeywords(String text) {
    final lowerText = text.toLowerCase();
    final ingredientKeywords = [
      'ingredient', 'conține', 'lapte', 'gluten', 'ouă', 'soia', 'nuci',
      'ingredients', 'contains', 'milk', 'eggs', 'soy', 'nuts', 'wheat',
      'zutaten', 'enthält', 'milch', 'eier', 'soja', 'nüsse',
      'ingrédients', 'contient', 'lait', 'œufs', 'soja', 'noix',
    ];
    
    return ingredientKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Estimează confidence-ul pentru o linie de text
  double _estimateLineConfidence(String lineText) {
    double confidence = 1.0;
    
    // Penalizează linii foarte scurte
    if (lineText.length < 3) {
      confidence *= 0.3;
    } else if (lineText.length < 6) confidence *= 0.6;
    
    // Penalizează caractere ciudate
    final weirdCharCount = _countWeirdCharacters(lineText);
    final weirdRatio = weirdCharCount / lineText.length;
    confidence *= (1.0 - weirdRatio);
    
    // Premiază cuvinte cunoscute
    final words = lineText.toLowerCase().split(RegExp(r'\s+'));
    final knownWords = words.where((word) => 
      word.length > 2 && RegExp(r'^[a-záâîșțăéèêëïîôöùûüÿç]+$').hasMatch(word)
    ).length;
    
    if (words.isNotEmpty) {
      final knownRatio = knownWords / words.length;
      confidence *= (0.5 + knownRatio * 0.5);
    }
    
    return confidence.clamp(0.0, 1.0);
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
  final List<TextBlock> blocks;
  final double confidence;
  final bool hasText;
  final double qualityScore;
  final List<String> issues;
  final List<String> suggestions;
  final bool isReliable;

  EnhancedOcrResult({
    required this.text,
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