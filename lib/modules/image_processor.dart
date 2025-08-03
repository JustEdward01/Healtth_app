import 'dart:io';
import 'package:image/image.dart';

class ImageProcessor {
  Future<File> processImage(File originalImage, {int maxWidth = 1000, int maxHeight = 1000}) async {
    final bytes = await originalImage.readAsBytes();

    Image? image = decodeImage(bytes);
    if (image == null) {
      throw Exception('Imaginea nu poate fi decodată');
    }

    // Resize - păstrează aspectul original
    image = copyResize(image, width: maxWidth, height: maxHeight);

    // Grayscale
    image = grayscale(image);

    // Binarizare manuală - versiunea corectă
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Extrage componentele RGB - metoda corectă pentru toate versiunile
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();  
        final b = pixel.b.toInt();

        // Calculăm luminanța
        final luma = (0.299 * r + 0.587 * g + 0.114 * b).round();

        // Setăm pixel alb sau negru
        if (luma < 128) {
          image.setPixelRgb(x, y, 0, 0, 0);    // negru
        } else {
          image.setPixelRgb(x, y, 255, 255, 255); // alb
        }
      }
    }

    final processedBytes = encodeJpg(image);

    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/processed_image_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
    await tempFile.writeAsBytes(processedBytes);

    return tempFile;
  }

  /// Alternativă mai simplă folosind funcțiile built-in
  Future<File> processImageSimple(File originalImage, {int maxWidth = 1000, int maxHeight = 1000}) async {
    final bytes = await originalImage.readAsBytes();

    Image? image = decodeImage(bytes);
    if (image == null) {
      throw Exception('Imaginea nu poate fi decodată');
    }

    // Resize
    image = copyResize(image, width: maxWidth, height: maxHeight);

    // Conversie la grayscale
    image = grayscale(image);

    // Îmbunătățiri pentru contrast
    image = contrast(image, contrast: 150);
    image = adjustColor(image, brightness: 1.3);

    final processedBytes = encodeJpg(image);

    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/processed_simple_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
    await tempFile.writeAsBytes(processedBytes);

    return tempFile;
  }

  /// Procesare optimizată pentru OCR
  Future<File> processForOCR(File originalImage) async {
    final bytes = await originalImage.readAsBytes();

    Image? image = decodeImage(bytes);
    if (image == null) {
      throw Exception('Imaginea nu poate fi decodată');
    }

    // Resize pentru OCR optim (nu prea mic, nu prea mare)
    if (image.width > 2000 || image.height > 2000) {
      image = copyResize(image, width: 1500, height: 1500);
    }

    // Îmbunătățiri pentru OCR
    image = adjustColor(image, contrast: 1.2, brightness: 1.1);
    image = gaussianBlur(image, radius: 1); // Reduce noise-ul
    
    // Conversie la grayscale pentru OCR mai bun
    image = grayscale(image);

    final processedBytes = encodeJpg(image, quality: 95);

    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/ocr_ready_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
    await tempFile.writeAsBytes(processedBytes);

    return tempFile;
  }

  /// Versiune foarte simplă - doar resize și contrast
  Future<File> processBasic(File originalImage, {int maxWidth = 1000, int maxHeight = 1000}) async {
    final bytes = await originalImage.readAsBytes();

    Image? image = decodeImage(bytes);
    if (image == null) {
      throw Exception('Imaginea nu poate fi decodată');
    }

    // Resize
    image = copyResize(image, width: maxWidth, height: maxHeight);
    
    // Îmbunătățire contrast pentru text mai clar
    image = contrast(image, contrast: 120);

    final processedBytes = encodeJpg(image, quality: 90);

    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/basic_${DateTime.now().millisecondsSinceEpoch}.jpg').create();
    await tempFile.writeAsBytes(processedBytes);

    return tempFile;
  }
}