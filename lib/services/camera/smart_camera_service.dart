import 'dart:io';
import 'dart:async';
import 'dart:ui'; // 🔧 ADDED for Rect
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart'; // 🔧 ADDED for debugPrint
import '../../models/camera/ingredient_zone.dart';
import '../../models/camera/photo_quality.dart';

class SmartCameraService {
  static final _instance = SmartCameraService._internal();
  factory SmartCameraService() => _instance;
  SmartCameraService._internal();

  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  // Ingredient keywords
  static const Map<String, List<String>> _ingredientKeywords = {
    'ro': [
      'ingredient', 'faina', 'lapte', 'zahar', 'ulei', 'sare',
      'unt', 'oua', 'drojdie', 'bicarbonat', 'vanilie', 'cacao'
    ],
    'en': [
      'ingredients', 'flour', 'milk', 'sugar', 'oil', 'salt',
      'butter', 'eggs', 'yeast', 'baking soda', 'vanilla', 'cocoa'
    ],
  };
  
  static const List<String> _headerKeywords = [
    'ingrediente', 'ingredients', 'contine', 'contains',
    'compozitie', 'composition'
  ];

  Future<void> initialize() async {
    if (!_isInitialized) {
      _textRecognizer = TextRecognizer();
      _isInitialized = true;
    }
  }

  Stream<IngredientZone> detectIngredientsLive(CameraController controller) {
    return Stream.periodic(const Duration(milliseconds: 800))
        .asyncMap((_) => _performLiveDetection(controller));
  }

  Future<IngredientZone> _performLiveDetection(CameraController controller) async {
    if (!controller.value.isInitialized) {
      return IngredientZone.empty();
    }

    try {
      await initialize();
      
      final image = await controller.takePicture();
      final inputImage = InputImage.fromFile(File(image.path));
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final zone = _analyzeIngredientZone(recognizedText);
      
      // Cleanup
      await File(image.path).delete();
      
      return zone;
    } catch (e) {
      debugPrint('Live detection error: $e'); // 🔧 FIXED: print -> debugPrint
      return IngredientZone.empty();
    }
  }

  IngredientZone _analyzeIngredientZone(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return IngredientZone.empty();

    final candidates = <IngredientCandidate>[];

    for (final block in recognizedText.blocks) {
      final candidate = _evaluateBlock(block);
      if (candidate.score > 0.2) {
        candidates.add(candidate);
      }
    }

    if (candidates.isEmpty) return IngredientZone.empty();

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;

    return IngredientZone(
      rect: best.expandedRect,
      confidence: best.score,
      wordCount: best.wordCount,
      detectedIngredients: best.detectedIngredients,
    );
  }

  IngredientCandidate _evaluateBlock(TextBlock block) {
    final text = block.text.toLowerCase();
    final words = text.split(RegExp(r'[\s,;:.()]+'));
    final detectedIngredients = <String>[];

    double score = 0.0;

    // 1. Ingredient keyword scoring (40%)
    score += _calculateIngredientScore(words, detectedIngredients) * 0.4;

    // 2. Pattern scoring (30%)  
    score += _calculatePatternScore(text) * 0.3;

    // 3. Layout scoring (30%)
    score += _calculateLayoutScore(block.lines, words) * 0.3;

    return IngredientCandidate(
      rect: block.boundingBox,
      expandedRect: _expandRect(block.boundingBox),
      score: score.clamp(0.0, 1.0),
      wordCount: words.length,
      detectedIngredients: detectedIngredients,
    );
  }

  double _calculateIngredientScore(List<String> words, List<String> detected) {
    final allKeywords = _ingredientKeywords.values
        .expand((keywords) => keywords).toSet();
    
    int matches = 0;
    for (final word in words) {
      if (allKeywords.any((keyword) => 
          word.contains(keyword) || keyword.contains(word))) {
        matches++;
        detected.add(word);
      }
    }

    return words.isNotEmpty ? matches / words.length : 0.0;
  }

  double _calculatePatternScore(String text) {
    double score = 0.0;
    
    if (RegExp(r'[a-zA-Z]+,\s*[a-zA-Z]+,\s*[a-zA-Z]+').hasMatch(text)) {
      score += 0.4;
    }
    
    if (RegExp(r'\b\d+(?:[.,]\d+)?%\b').hasMatch(text)) {
      score += 0.2;
    }
    
    if (RegExp(r'\bE\d{3,4}\b').hasMatch(text)) {
      score += 0.2;
    }
    
    if (_headerKeywords.any((keyword) => text.contains(keyword))) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateLayoutScore(List<TextLine> lines, List<String> words) {
    double score = 0.0;

    if (lines.length >= 2) score += 0.3;
    if (lines.length >= 4) score += 0.2;

    final avgWordLength = words.isNotEmpty 
        ? words.fold<int>(0, (sum, word) => sum + word.length) / words.length 
        : 0.0;
    
    if (avgWordLength >= 4 && avgWordLength <= 12) {
      score += 0.3;
    }

    final totalChars = words.join('').length;
    if (totalChars >= 30 && totalChars <= 200) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  Rect _expandRect(Rect rect) {
    const padding = 20.0;
    return Rect.fromLTRB(
      (rect.left - padding).clamp(0.0, double.infinity),
      (rect.top - padding).clamp(0.0, double.infinity),
      rect.right + padding,
      rect.bottom + padding,
    );
  }

  PhotoQuality assessPhotoQuality(IngredientZone zone) {
    if (!zone.isDetected) return PhotoQuality.searching;
    
    final confidence = zone.confidence;
    
    if (confidence >= 0.8) return PhotoQuality.perfect;
    if (confidence >= 0.6) return PhotoQuality.good;
    if (confidence >= 0.3) return PhotoQuality.poor;
    return PhotoQuality.terrible;
  }

  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}