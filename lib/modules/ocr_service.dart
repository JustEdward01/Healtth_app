import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Model pentru rezultatul OCR cu informații detaliate
class OcrResult {
  final String text;
  final List<TextBlock> blocks;
  final double confidence;
  final bool hasText;
  final String? error;

  OcrResult({
    required this.text,
    required this.blocks,
    required this.confidence,
    required this.hasText,
    this.error,
  });
}

class OcrService {
  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  /// Inițializează serviciul cu configurări pentru limba română și engleză
  Future<void> initialize({TextRecognitionScript script = TextRecognitionScript.latin}) async {
    if (!_isInitialized) {
      _textRecognizer = TextRecognizer(script: script);
      _isInitialized = true;
    }
  }

  /// Extrage text simplu din imagine (compatibilitate cu versiunea ta)
  Future<String> extractText(File imageFile) async {
    try {
      await initialize();
      
      if (!await imageFile.exists()) {
        throw Exception('Fișierul imagine nu există');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Eroare la extragerea textului: $e');
    }
  }

  /// Extrage text cu informații detaliate
  Future<OcrResult> extractTextDetailed(File imageFile) async {
    try {
      await initialize();
      
      if (!await imageFile.exists()) {
        throw Exception('Fișierul imagine nu există');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Calculează confidence score bazat pe numărul de blocuri detectate
      final confidence = _calculateConfidence(recognizedText);
      
      return OcrResult(
        text: recognizedText.text,
        blocks: recognizedText.blocks,
        confidence: confidence,
        hasText: recognizedText.text.isNotEmpty,
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

  /// Extrage doar textul relevant pentru ingrediente
  Future<String> extractIngredients(File imageFile) async {
    try {
      final result = await extractTextDetailed(imageFile);
      
      if (!result.hasText) {
        return '';
      }

      // Caută secțiuni cu ingrediente
      final text = result.text.toLowerCase();
      final lines = text.split('\n');
      
      String ingredients = '';
      bool foundIngredients = false;
      
      for (String line in lines) {
        // Detectează începutul listei de ingrediente
        if (line.contains('ingredient') || 
            line.contains('składniki') || 
            line.contains('ingrediente') ||
            line.contains('composition')) {
          foundIngredients = true;
          continue;
        }
        
        // Detectează sfârșitul listei de ingrediente
        if (foundIngredients && (
            line.contains('nutritional') ||
            line.contains('nutrition') ||
            line.contains('values') ||
            line.contains('energy') ||
            line.contains('energie'))) {
          break;
        }
        
        // Adaugă linia dacă suntem în secțiunea ingrediente
        if (foundIngredients && line.trim().isNotEmpty) {
          ingredients += '${line.trim()} ';
        }
      }
      
      return ingredients.trim();
    } catch (e) {
      throw Exception('Eroare la extragerea ingredientelor: $e');
    }
  }

  /// Verifică calitatea OCR pentru o imagine
  Future<bool> isGoodQuality(File imageFile) async {
    try {
      final result = await extractTextDetailed(imageFile);
      return result.confidence > 0.6 && result.hasText;
    } catch (e) {
      return false;
    }
  }

  /// Curăță textul OCR de caractere nedorite
  String cleanText(String rawText) {
    return rawText
        .replaceAll(RegExp(r'[^\w\s\.,;:\(\)\-\/]'), '') // Păstrează doar caractere utile
        .replaceAll(RegExp(r'\s+'), ' ') // Înlocuiește spații multiple cu unul singur
        .trim();
  }

  /// Calculează confidence score bazat pe rezultatele OCR
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.text.isEmpty) return 0.0;
    
    double confidence = 0.0;
    int totalBlocks = recognizedText.blocks.length;
    
    if (totalBlocks == 0) return 0.0;
    
    // Bazat pe numărul de blocuri și lungimea textului
    confidence += (totalBlocks * 0.1).clamp(0.0, 0.5);
    confidence += (recognizedText.text.length / 100).clamp(0.0, 0.5);
    
    return confidence.clamp(0.0, 1.0);
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