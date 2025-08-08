import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ProductOcrResult {
  final String? productName;
  final String? brand;
  final String allText;
  ProductOcrResult({this.productName, this.brand, required this.allText});
}

class EnhancedOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<ProductOcrResult> extractProductInfo(File productImage) async {
    final inputImage = InputImage.fromFile(productImage);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final lines = recognizedText.blocks
        .expand((b) => b.lines)
        .map((l) => l.text)
        .toList();

    final allText = lines.join(' ');

    String? productName = _extractProductName(lines);
    String? brand = _extractBrand(lines);

    return ProductOcrResult(productName: productName, brand: brand, allText: allText);
  }

  String? _extractProductName(List<String> lines) {
    // heuristics: cea mai lungă linie fără multă puntuatie și litere mari sunt probabile
    if (lines.isEmpty) return null;
    lines.sort((a, b) => b.length.compareTo(a.length));
    for (final l in lines.take(5)) {
      final cleaned = l.trim();
      if (cleaned.length >= 3 && !RegExp(r'^\d+$').hasMatch(cleaned)) {
        return cleaned;
      }
    }
    return lines.first.trim();
  }

  String? _extractBrand(List<String> lines) {
    final knownBrands = ['coca-cola', 'pepsi', 'nestle', 'danone', 'milka', 'snickers'];
    for (final l in lines) {
      final lower = l.toLowerCase();
      for (final b in knownBrands) {
        if (lower.contains(b)) return b;
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
