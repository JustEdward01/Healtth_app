// lib/services/enhanced_ocr_service.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../services/enhanced_image_processor.dart';

/// Enhanced OCR Service optimizat pentru extragerea numelor de produse
/// Include preprocesare avansată, multi-language support și product name extraction
class EnhancedOcrService {
  late final TextRecognizer _textRecognizer;
  final EnhancedImageProcessor _imageProcessor = EnhancedImageProcessor();
  
  // Cache pentru rezultate recente
  final Map<String, String> _ocrCache = {};
  static const int maxCacheSize = 50;
  
  // Product name patterns
  static final List<RegExp> productNamePatterns = [
    RegExp(r'^[A-Z][A-Za-z\s&\-]+(?:\s+\d+(?:g|ml|L|kg))?$'), // Nume produs cu greutate
    RegExp(r'^[A-Z]{2,}(?:\s+[A-Z]{2,})*$'), // BRAND NAME
    RegExp(r'^[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3}$'), // Nume normal
    RegExp(r'^\w+\s+(?:Original|Classic|Premium|Light|Zero|Diet|Max|Plus)$', caseSensitive: false),
  ];
  
  // Brand indicators
  static const List<String> knownBrands = [
    'Coca-Cola', 'Pepsi', 'Nestle', 'Danone', 'Milka', 'Oreo', 'Lays', 'Pringles',
    'Nutella', 'Ferrero', 'Kinder', 'Snickers', 'Mars', 'Twix', 'Bounty',
    'Dorna', 'Bucegi', 'Borsec', 'Napolact', 'Zuzu', 'Albalact', 'Cris-Tim',
    'Scandia', 'Agricola', 'Vel Pitar', 'Dobrogea', 'Karamela', 'Kandia',
    'Rom', 'Eugenia', 'Joe', 'Ulpio', 'Gusto', 'Star', 'Chio', 'Felix'
  ];
  
  // Noise words to filter out
  static const List<String> noiseWords = [
    'ingredients', 'ingrediente', 'contains', 'contine', 'net', 'weight', 
    'greutate', 'best', 'before', 'expira', 'lot', 'fabricat', 'produs',
    'romania', 'import', 'export', 'srl', 'sa', 'ltd', 'gmbh',
    'nutritional', 'valori', 'energie', 'kcal', 'protein', 'carb',
    'contact', 'telefon', 'email', 'www', 'http', 'address', 'str'
  ];

  EnhancedOcrService() {
    _initializeOCR();
  }

  void _initializeOCR() {
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    debugPrint('✅ Enhanced OCR Service inițializat');
  }

  /// Extract product name din imagine
  Future<String> extractProductName(
    File imageFile, {
    List<String> languages = const ['ro', 'en'],
    bool useCache = true,
  }) async {
    try {
      // Check cache
      final cacheKey = imageFile.path;
      if (useCache && _ocrCache.containsKey(cacheKey)) {
        debugPrint('📦 OCR rezultat din cache');
        return _ocrCache[cacheKey]!;
      }
      
      // 1. Preprocesare imagine pentru OCR optim
      final processedFile = await _preprocessForProductName(imageFile);
      
      // 2. OCR pe imaginea procesată
      final recognizedText = await _performOCR(processedFile);
      
      // 3. Extrage și curăță numele produsului
      final productName = _extractAndCleanProductName(recognizedText);
      
      // 4. Validare și post-procesare
      final finalName = _validateAndPostProcess(productName, languages);
      
      // Cache result
      if (useCache) {
        _addToCache(cacheKey, finalName);
      }
      
      // Cleanup temp file
      if (processedFile.path != imageFile.path) {
        try {
          await processedFile.delete();
        } catch (_) {}
      }
      
      debugPrint('🏷️ Nume produs extras: "$finalName"');
      return finalName;
      
    } catch (e) {
      debugPrint('❌ Eroare OCR pentru nume produs: $e');
      return '';
    }
  }

  /// Preprocesare specifică pentru extragerea numelor de produse
  Future<File> _preprocessForProductName(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return imageFile;
      
      // 1. Crop zona superioară (unde de obicei e numele)
      final topRegion = _cropTopRegion(image);
      
      // 2. Enhance pentru text
      final enhanced = await _enhanceForText(topRegion);
      
      // 3. Multiple preprocessing attempts
      final attempts = [
        _preprocessAttempt1(enhanced), // High contrast B&W
        _preprocessAttempt2(enhanced), // Adaptive threshold
        _preprocessAttempt3(enhanced), // Color preserved
      ];
      
      // Try each preprocessing și alege cel mai bun
      String bestText = '';
      File bestFile = imageFile;
      
      for (final attemptImage in attempts) {
        final tempFile = File('${imageFile.parent.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(img.encodeJpg(attemptImage, quality: 95));
        
        final text = await _quickOCR(tempFile);
        if (text.length > bestText.length && _looksLikeProductName(text)) {
          bestText = text;
          bestFile = tempFile;
        } else {
          try { await tempFile.delete(); } catch (_) {}
        }
      }
      
      return bestFile;
      
    } catch (e) {
      debugPrint('⚠️ Preprocessing failed, using original: $e');
      return imageFile;
    }
  }

  /// Crop regiunea de sus unde de obicei apare numele produsului
  img.Image _cropTopRegion(img.Image image) {
    // Luăm top 40% din imagine
    final cropHeight = (image.height * 0.4).toInt();
    
    return img.copyCrop(
      image,
      x: 0,
      y: 0,
      width: image.width,
      height: cropHeight,
    );
  }

  /// Enhance specific pentru text
  Future<img.Image> _enhanceForText(img.Image image) async {
    // Resize dacă e prea mare sau prea mic
    if (image.width > 2000) {
      image = img.copyResize(image, width: 1500);
    } else if (image.width < 800) {
      image = img.copyResize(image, width: 1000);
    }
    
    // Sharpen pentru text mai clar
    image = _sharpen(image);
    
    // Denoise
    image = _denoise(image);
    
    return image;
  }

  /// Preprocessing attempt 1: High contrast black & white
  img.Image _preprocessAttempt1(img.Image image) {
    var processed = img.grayscale(image);
    processed = img.adjustColor(processed, contrast: 1.5, brightness: 1.1);
    
    // Binarization cu threshold fix
    const threshold = 128;
    for (int y = 0; y < processed.height; y++) {
      for (int x = 0; x < processed.width; x++) {
        final pixel = processed.getPixel(x, y);
        final value = pixel.r > threshold ? 255 : 0;
        processed.setPixelRgb(x, y, value, value, value);
      }
    }
    
    return processed;
  }

  /// Preprocessing attempt 2: Adaptive threshold
  img.Image _preprocessAttempt2(img.Image image) {
    final gray = img.grayscale(image);
    final binary = img.Image(width: gray.width, height: gray.height);
    
    const windowSize = 15;
    const constant = 10;
    
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        // Calculate local mean
        int sum = 0;
        int count = 0;
        
        for (int wy = -windowSize; wy <= windowSize; wy++) {
          for (int wx = -windowSize; wx <= windowSize; wx++) {
            final nx = x + wx;
            final ny = y + wy;
            
            if (nx >= 0 && nx < gray.width && ny >= 0 && ny < gray.height) {
              sum += gray.getPixel(nx, ny).r.toInt();
              count++;
            }
          }
        }
        
        final localMean = sum ~/ count;
        final pixel = gray.getPixel(x, y);
        
        if (pixel.r > localMean - constant) {
          binary.setPixelRgb(x, y, 255, 255, 255);
        } else {
          binary.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    
    return binary;
  }

  /// Preprocessing attempt 3: Color preserved with enhancement
  img.Image _preprocessAttempt3(img.Image image) {
    // Keep colors but enhance contrast
    var processed = img.adjustColor(
      image,
      contrast: 1.3,
      brightness: 1.05,
      saturation: 0.8,
    );
    
    // Unsharp mask pentru claritate
    processed = _unsharpMask(processed);
    
    return processed;
  }

  /// Sharpen filter
  img.Image _sharpen(img.Image image) {
    const kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0]
    ];
    
    return _applyKernel(image, kernel);
  }

  /// Unsharp mask pentru enhanced sharpness
  img.Image _unsharpMask(img.Image image) {
    // Create blurred version
    final blurred = img.gaussianBlur(image, radius: 1);
    
    // Subtract blur from original și amplify
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final orig = image.getPixel(x, y);
        final blur = blurred.getPixel(x, y);
        
        final r = (orig.r + 1.5 * (orig.r - blur.r)).clamp(0, 255).toInt();
        final g = (orig.g + 1.5 * (orig.g - blur.g)).clamp(0, 255).toInt();
        final b = (orig.b + 1.5 * (orig.b - blur.b)).clamp(0, 255).toInt();
        
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return result;
  }

  /// Simple denoise
  img.Image _denoise(img.Image image) {
    // Median filter 3x3
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final pixels = <int>[];
        
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            pixels.add(pixel.r.toInt());
          }
        }
        
        pixels.sort();
        final median = pixels[4]; // Middle value
        
        result.setPixelRgb(x, y, median, median, median);
      }
    }
    
    return result;
  }

  /// Apply convolution kernel
  img.Image _applyKernel(img.Image image, List<List<int>> kernel) {
    final result = img.Image(width: image.width, height: image.height);
    final kernelSize = kernel.length ~/ 2;
    
    for (int y = kernelSize; y < image.height - kernelSize; y++) {
      for (int x = kernelSize; x < image.width - kernelSize; x++) {
        int sumR = 0, sumG = 0, sumB = 0;
        
        for (int ky = -kernelSize; ky <= kernelSize; ky++) {
          for (int kx = -kernelSize; kx <= kernelSize; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final weight = kernel[ky + kernelSize][kx + kernelSize];
            
            sumR += (pixel.r * weight).toInt();
            sumG += (pixel.g * weight).toInt();
            sumB += (pixel.b * weight).toInt();
          }
        }
        
        result.setPixelRgb(
          x, y,
          sumR.clamp(0, 255),
          sumG.clamp(0, 255),
          sumB.clamp(0, 255),
        );
      }
    }
    
    return result;
  }

  /// Quick OCR pentru testing
  Future<String> _quickOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  /// Main OCR processing
  Future<RecognizedText> _performOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    debugPrint('📝 OCR raw text: ${recognizedText.text}');
    debugPrint('📊 Blocks detected: ${recognizedText.blocks.length}');
    
    return recognizedText;
  }

  /// Extract și clean product name din OCR result
  String _extractAndCleanProductName(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return '';
    
    // Collect all potential product names
    final candidates = <ProductNameCandidate>[];
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        
        // Calculate score pentru fiecare linie
        final score = _scoreProductNameCandidate(text, line);
        
        if (score > 0) {
          candidates.add(ProductNameCandidate(
            text: text,
            score: score,
            fontSize: _estimateFontSize(line),
            position: line.boundingBox.top,
          ));
        }
      }
    }
    
    if (candidates.isEmpty) {
      // Fallback: ia prima linie non-noise
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final cleaned = _cleanText(line.text);
          if (cleaned.length > 2 && !_isNoise(cleaned)) {
            return cleaned;
          }
        }
      }
      return '';
    }
    
    // Sort by score și alege best candidate
    candidates.sort((a, b) => b.score.compareTo(a.score));
    
    // Combine top candidates dacă sunt apropiate
    final topCandidate = candidates.first;
    final combined = _combineNearbyText(topCandidate, candidates);
    
    return _cleanText(combined);
  }

  /// Score a text line as potential product name
  double _scoreProductNameCandidate(String text, TextLine line) {
    double score = 0;
    
    // 1. Check for brand match
    for (final brand in knownBrands) {
      if (text.toLowerCase().contains(brand.toLowerCase())) {
        score += 10.0;
        break;
      }
    }
    
    // 2. Check patterns
    for (final pattern in productNamePatterns) {
      if (pattern.hasMatch(text)) {
        score += 5.0;
        break;
      }
    }
    
    // 3. Position score (top of image is better)
    final positionScore = max(0, 5 - (line.boundingBox.top / 100));
    score += positionScore;
    
    // 4. Font size score (bigger is better for product names)
    final fontSize = _estimateFontSize(line);
    score += fontSize / 10;
    
    // 5. Capitalization score
    if (_hasProperCapitalization(text)) {
      score += 3.0;
    }
    
    // 6. Length score (product names are usually 1-4 words)
    final wordCount = text.split(' ').length;
    if (wordCount >= 1 && wordCount <= 4) {
      score += 2.0;
    }
    
    // 7. Penalize noise words
    if (_containsNoiseWords(text)) {
      score -= 10.0;
    }
    
    // 8. Penalize URLs, emails, numbers only
    if (_isMetadata(text)) {
      score -= 20.0;
    }
    
    return score;
  }

  /// Estimate font size from bounding box
  double _estimateFontSize(TextLine line) {
    return line.boundingBox.height;
  }

  /// Check if text has proper capitalization for product name
  bool _hasProperCapitalization(String text) {
    if (text.isEmpty) return false;
    
    // First letter capitalized
    if (text[0] == text[0].toUpperCase()) return true;
    
    // All caps (brand names)
    if (text == text.toUpperCase() && text.length > 2) return true;
    
    // Title case
    final words = text.split(' ');
    final titleCase = words.every((word) => 
      word.isEmpty || word[0] == word[0].toUpperCase()
    );
    
    return titleCase;
  }

  /// Check if text contains noise words
  bool _containsNoiseWords(String text) {
    final lower = text.toLowerCase();
    return noiseWords.any((noise) => lower.contains(noise));
  }

  /// Check if text is metadata (URL, email, phone, etc)
  bool _isMetadata(String text) {
    // URL pattern
    if (text.contains('www.') || text.contains('http')) return true;
    
    // Email pattern
    if (text.contains('@')) return true;
    
    // Phone pattern
    if (RegExp(r'^\+?\d[\d\s\-\(\)]+$').hasMatch(text)) return true;
    
    // Just numbers
    if (RegExp(r'^\d+$').hasMatch(text)) return true;
    
    // Barcode
    if (text.length > 8 && RegExp(r'^\d{8,}$').hasMatch(text)) return true;
    
    return false;
  }

  /// Check if text looks like a product name
  bool _looksLikeProductName(String text) {
    if (text.isEmpty || text.length < 2) return false;
    if (_isMetadata(text)) return false;
    if (_containsNoiseWords(text)) return false;
    
    // Has at least one letter
    if (!text.contains(RegExp(r'[a-zA-Z]'))) return false;
    
    // Not too long
    if (text.length > 50) return false;
    
    return true;
  }

  /// Combine nearby text elements
  String _combineNearbyText(
    ProductNameCandidate main,
    List<ProductNameCandidate> candidates,
  ) {
    final combined = [main.text];
    const proximityThreshold = 30.0; // pixels
    
    for (final candidate in candidates) {
      if (candidate == main) continue;
      
      // Check if nearby vertically
      if ((candidate.position - main.position).abs() < proximityThreshold) {
        // Check if similar font size
        if ((candidate.fontSize - main.fontSize).abs() < 5) {
          // Check if makes sense to combine
          final combinedText = '${main.text} ${candidate.text}';
          if (combinedText.split(' ').length <= 5) {
            combined.add(candidate.text);
          }
        }
      }
    }
    
    return combined.join(' ');
  }

  /// Clean extracted text
  String _cleanText(String text) {
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove special characters dar păstrează dash și ampersand
    text = text.replaceAll(RegExp(r'[^\w\s\-&À-ÿ]'), ' ');
    
    // Remove standalone numbers at the end (probably weight/volume)
    text = text.replaceAll(RegExp(r'\s+\d+\s*(g|ml|l|kg|oz)?$', caseSensitive: false), '');
    
    // Capitalize properly
    if (text.isNotEmpty && text == text.toLowerCase()) {
      // Title case if all lowercase
      text = text.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    
    return text.trim();
  }

  /// Check if text is just noise
  bool _isNoise(String text) {
    if (text.length < 2) return true;
    if (_isMetadata(text)) return true;
    if (_containsNoiseWords(text)) return true;
    
    // Only special characters or numbers
    if (!text.contains(RegExp(r'[a-zA-Z]'))) return true;
    
    return false;
  }

  /// Validate și post-process extracted name
  String _validateAndPostProcess(String productName, List<String> languages) {
    if (productName.isEmpty) return '';
    
    // Language-specific processing
    if (languages.contains('ro')) {
      productName = _processRomanian(productName);
    }
    
    // Final validation
    if (productName.length < 2 || productName.length > 50) {
      return '';
    }
    
    // Remove any remaining noise
    for (final noise in noiseWords) {
      productName = productName.replaceAll(RegExp('\\b$noise\\b', caseSensitive: false), '');
    }
    
    return productName.trim();
  }

  /// Romanian-specific processing
  String _processRomanian(String text) {
    // Romanian diacritics fix
    text = text
      .replaceAll('ã', 'ă')
      .replaceAll('â', 'â')
      .replaceAll('î', 'î')
      .replaceAll('ş', 'ș')
      .replaceAll('ţ', 'ț');
    
    return text;
  }

  /// Add result to cache
  void _addToCache(String key, String value) {
    // Limit cache size
    if (_ocrCache.length >= maxCacheSize) {
      _ocrCache.remove(_ocrCache.keys.first);
    }
    
    _ocrCache[key] = value;
  }

  /// Extract text with language filter (compatibility method)
  Future<OCRResult> extractTextWithLanguageFilter(File imageFile) async {
    final text = await extractProductName(imageFile);
    
    return OCRResult(
      text: text,
      confidence: text.isNotEmpty ? 0.8 : 0.0,
      languageDetected: 'ro', // Default
      blocks: [],
    );
  }

  /// Extract ingredients (fallback to basic OCR)
  Future<String> extractIngredients(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Look for ingredients section
      final text = recognizedText.text.toLowerCase();
      final ingredientsIndex = text.indexOf('ingredient');
      
      if (ingredientsIndex >= 0) {
        // Extract text after "ingredients:"
        final afterIngredients = text.substring(ingredientsIndex);
        final lines = afterIngredients.split('\n');
        
        if (lines.isNotEmpty) {
          // Take first few lines after ingredients label
          return lines.take(5).join(' ').trim();
        }
      }
      
      return '';
    } catch (e) {
      debugPrint('❌ Error extracting ingredients: $e');
      return '';
    }
  }

  /// Extract any text (compatibility)
  Future<String> extractText(File imageFile) async {
    return extractProductName(imageFile);
  }

  /// Cleanup resources
  void dispose() {
    _textRecognizer.close();
    _ocrCache.clear();
  }
}

/// Helper class for product name candidates
class ProductNameCandidate {
  final String text;
  final double score;
  final double fontSize;
  final double position;

  ProductNameCandidate({
    required this.text,
    required this.score,
    required this.fontSize,
    required this.position,
  });
}

/// OCR Result wrapper for compatibility
class OCRResult {
  final String text;
  final double confidence;
  final String languageDetected;
  final List<TextBlock> blocks;
  
  OCRResult({
    required this.text,
    required this.confidence,
    required this.languageDetected,
    required this.blocks,
  });
  
  bool get hasText => text.isNotEmpty;
}