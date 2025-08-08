// enhanced_image_processor.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class EnhancedImageProcessor {
  /// Procesează imaginea cu multiple tehnici pentru calitate slabă
  Future<File> processForOCREnhanced(File originalImage) async {
    final bytes = await originalImage.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) throw Exception('Nu se poate decoda imaginea');

    final qualityScore = _analyzeImageQuality(image);

    if (qualityScore < 0.3) {
      image = _processLowQualityImage(image);
    } else if (qualityScore < 0.6) {
      image = _processMediumQualityImage(image);
    } else {
      image = _processGoodQualityImage(image);
    }

    final processedBytes = img.encodePng(image);
    final tempDir = Directory.systemTemp;
    final processedFile = File('${tempDir.path}/enhanced_ocr_${DateTime.now().millisecondsSinceEpoch}.png');
    await processedFile.writeAsBytes(processedBytes);

    return processedFile;
  }

  /// Analizează calitatea imaginii (0.0 = foarte slabă, 1.0 = foarte bună)
  double _analyzeImageQuality(img.Image image) {
    double qualityScore = 0.0;

    final pixels = image.width * image.height;
    final resolutionScore = (pixels / 1000000).clamp(0.0, 1.0);
    qualityScore += resolutionScore * 0.3;

    final contrastScore = _calculateContrast(image);
    qualityScore += contrastScore * 0.4;

    final sharpnessScore = _calculateSharpness(image);
    qualityScore += sharpnessScore * 0.3;

    return qualityScore.clamp(0.0, 1.0);
  }

  /// Calculează contrastul imaginii
  double _calculateContrast(img.Image image) {
    int minLuma = 255;
    int maxLuma = 0;

    final step = (image.width * image.height / 1000).round().clamp(1, 100);

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final luma = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();

        if (luma < minLuma) minLuma = luma;
        if (luma > maxLuma) maxLuma = luma;
      }
    }

    return ((maxLuma - minLuma) / 255.0).clamp(0.0, 1.0);
  }

  /// Calculează claritatea imaginii (detectare blur)
  double _calculateSharpness(img.Image image) {
    final laplacian = img.convolution(image, filter: [
      0, -1, 0,
      -1, 4, -1,
      0, -1, 0
    ]);

    double variance = 0;
    int count = 0;

    for (int y = 1; y < laplacian.height - 1; y++) {
      for (int x = 1; x < laplacian.width - 1; x++) {
        final pixel = laplacian.getPixel(x, y);
        final gray = (pixel.r + pixel.g + pixel.b) / 3;
        variance += gray * gray;
        count++;
      }
    }

    variance = variance / count;
    return (variance / 10000).clamp(0.0, 1.0);
  }

  /// Procesare pentru imagini de calitate slabă
  img.Image _processLowQualityImage(img.Image image) {
    if (image.width > 2500 || image.height > 2500) {
      image = img.copyResize(image, width: 2000);
    }

    image = img.gaussianBlur(image, radius: 2);
    image = img.convolution(image, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);

    image = img.adjustColor(image, contrast: 2.0, brightness: 1.3);
    image = _adaptiveBinarization(image);

    return image;
  }

  /// Procesare pentru imagini de calitate medie
  img.Image _processMediumQualityImage(img.Image image) {
    if (image.width > 2000 || image.height > 2000) {
      image = img.copyResize(image, width: 1600);
    }

    image = img.gaussianBlur(image, radius: 1);
    image = img.adjustColor(image, contrast: 1.5, brightness: 1.2);
    image = img.grayscale(image);

    return image;
  }

  /// Procesare pentru imagini de calitate bună
  img.Image _processGoodQualityImage(img.Image image) {
    if (image.width > 1800 || image.height > 1800) {
      image = img.copyResize(image, width: 1500);
    }

    image = img.adjustColor(image, contrast: 1.2, brightness: 1.1);
    image = img.grayscale(image);

    return image;
  }

  /// Binarizare adaptivă pentru text foarte neclar
  img.Image _adaptiveBinarization(img.Image image) {
    final gray = img.grayscale(image);
    final binary = img.Image(width: gray.width, height: gray.height);

    const windowSize = 15;

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        int sum = 0;
        int count = 0;

        for (int wy = -windowSize; wy <= windowSize; wy++) {
          for (int wx = -windowSize; wx <= windowSize; wx++) {
            final nx = x + wx;
            final ny = y + wy;

            if (nx >= 0 && nx < gray.width && ny >= 0 && ny < gray.height) {
              final pixel = gray.getPixel(nx, ny);
              sum += pixel.r.toInt();
              count++;
            }
          }
        }

        final localThreshold = sum ~/ count;
        final currentPixel = gray.getPixel(x, y);

        if (currentPixel.r.toInt() > localThreshold + 10) {
          binary.setPixelRgb(x, y, 255, 255, 255);
        } else {
          binary.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }

    return binary;
  }

  /// Binarizare Otsu pentru imagini cu fundal relativ uniform
  img.Image _otsuBinarization(img.Image image) {
    final gray = img.grayscale(image);

    List<int> histogram = List<int>.filled(256, 0);
    for (final pixel in gray) {
      histogram[pixel.r.toInt()]++;
    }

    int total = gray.width * gray.height;

    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;

    double mB;
    double mF;

    double max = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];

      mB = sumB / wB;
      mF = (sum - sumB) / wF;

      double between = wB * wF * (mB - mF) * (mB - mF);

      if (between > max) {
        max = between;
        threshold = i;
      }
    }

    return _binarize(gray, threshold: threshold);
  }

  /// Binarizare simplă (metodă privată)
  img.Image _binarize(img.Image image, {int threshold = 127}) {
    var binarizedImage = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        var gray = (pixel.r.toInt() + pixel.g.toInt() + pixel.b.toInt()) ~/ 3;
        if (gray > threshold) {
          binarizedImage.setPixelRgb(x, y, 255, 255, 255);
        } else {
          binarizedImage.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    return binarizedImage;
  }

  /// Detectează și procesează fundalul colorat
 

  /// Creează multiple variante ale imaginii pentru OCR
  Future<List<File>> createMultipleVariants(File originalImage) async {
    final bytes = await originalImage.readAsBytes();
    img.Image? baseImage = img.decodeImage(bytes);
    if (baseImage == null) throw Exception('Nu se poate decoda imaginea');

    final variants = <File>[];
    final tempDir = Directory.systemTemp;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Varianta 1: Standard (îmbunătățire de bază)
    var variant1 = _processGoodQualityImage(img.Image.from(baseImage));
    final file1 = File('${tempDir.path}/variant1_$now.png');
    await file1.writeAsBytes(img.encodePng(variant1));
    variants.add(file1);

    // Varianta 2: Contrast mare
    var variant2 = img.adjustColor(img.Image.from(baseImage), contrast: 2.5, brightness: 1.4);
    variant2 = img.grayscale(variant2);
    final file2 = File('${tempDir.path}/variant2_$now.png');
    await file2.writeAsBytes(img.encodePng(variant2));
    variants.add(file2);

    // Varianta 3: Binarizare Otsu (pentru fundal uniform)
    try {
      var variant3 = _otsuBinarization(img.Image.from(baseImage));
      final file3 = File('${tempDir.path}/variant3_$now.png');
      await file3.writeAsBytes(img.encodePng(variant3));
      variants.add(file3);
    } catch (e) {
      debugPrint('Eroare la binarizare Otsu: $e');
    }

    return variants;
  }
}