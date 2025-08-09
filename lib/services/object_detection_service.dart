// lib/services/object_detection_service.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detected_product.dart';

/// Service pentru detectarea produselor în imagini folosind ML sau euristici
/// Poate folosi TensorFlow Lite pentru object detection sau fallback la metode clasice
class ObjectDetectionService {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  // Configuration
  static const double minConfidenceScore = 0.3;
  static const int maxDetections = 20;
  static const int inputSize = 300; // SSD MobileNet input size
  
  // Edge detection parameters
  static const double edgeThreshold = 100.0;
  static const int minProductArea = 5000; // pixels
  static const int maxProductArea = 500000; // pixels
  
  bool _isInitialized = false;

  /// Inițializare model ML (opțional)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Încercăm să încărcăm modelul TFLite dacă există
      await _loadModel();
      _isInitialized = true;
      debugPrint('✅ Object detection model încărcat cu succes');
    } catch (e) {
      debugPrint('⚠️ Nu s-a putut încărca modelul ML, folosim detectare clasică: $e');
      _isInitialized = true; // Marcăm ca inițializat oricum pentru fallback
    }
  }

  /// Încărcare model TensorFlow Lite
  Future<void> _loadModel() async {
    try {
      // Path către modelul TFLite (trebuie adăugat în assets)
      const modelPath = 'assets/models/ssd_mobilenet.tflite';
      const labelsPath = 'assets/models/labels.txt';
      
      // Verificăm dacă fișierele există
      final modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        throw Exception('Model file not found');
      }
      
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // Încărcăm labels
      final labelsFile = File(labelsPath);
      if (await labelsFile.exists()) {
        final labelsContent = await labelsFile.readAsString();
        _labels = labelsContent.split('\n').where((label) => label.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Eroare la încărcarea modelului TFLite: $e');
      _interpreter = null;
      _labels = null;
    }
  }

  /// Detectare principală - încearcă ML apoi fallback la metode clasice
  Future<List<ProductBoundingBox>> detectProductsInImage(File imageFile) async {
    await initialize();
    
    try {
      // Dacă avem model ML, îl folosim
      if (_interpreter != null) {
        return await _detectWithML(imageFile);
      }
      
      // Altfel folosim detectare clasică bazată pe edge detection și contururi
      return await _detectWithClassicCV(imageFile);
      
    } catch (e) {
      debugPrint('❌ Eroare la detectarea produselor: $e');
      // În caz de eroare totală, returnăm grid uniform
      return _generateUniformGrid(3, 4);
    }
  }

  /// Detectare folosind model TensorFlow Lite
  Future<List<ProductBoundingBox>> _detectWithML(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Model ML nu este încărcat');
    }
    
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Nu s-a putut decoda imaginea');
    }
    
    // Preprocesare imagine pentru model
    final input = _preprocessImageForML(image);
    
    // Prepare output tensors
    final output = List.generate(1, (index) => 
      List.generate(maxDetections, (index) => List.filled(4, 0.0))
    );
    final classes = List.generate(1, (index) => List.filled(maxDetections, 0.0));
    final scores = List.generate(1, (index) => List.filled(maxDetections, 0.0));
    final numDetections = List.filled(1, 0.0);
    
    // Run inference
    final inputs = [input];
    final outputs = {
      0: output,
      1: classes,
      2: scores,
      3: numDetections,
    };
    
    _interpreter!.runForMultipleInputs(inputs, outputs);
    
    // Parse results
    final detections = <ProductBoundingBox>[];
    final numDetected = numDetections[0].toInt();
    
    for (int i = 0; i < numDetected && i < maxDetections; i++) {
      final score = scores[0][i];
      if (score < minConfidenceScore) continue;
      
      // Coordonatele sunt normalizate [0, 1]
      final bbox = output[0][i];
      final yMin = bbox[0] * image.height;
      final xMin = bbox[1] * image.width;
      final yMax = bbox[2] * image.height;
      final xMax = bbox[3] * image.width;
      
      detections.add(ProductBoundingBox(
        x: xMin,
        y: yMin,
        width: xMax - xMin,
        height: yMax - yMin,
        confidence: score,
        label: _labels != null && classes[0][i].toInt() < _labels!.length 
            ? _labels![classes[0][i].toInt()]
            : 'product',
      ));
    }
    
    debugPrint('🎯 ML a detectat ${detections.length} produse');
    return detections;
  }

  /// Detectare folosind computer vision clasic (edge detection + contour finding)
  Future<List<ProductBoundingBox>> _detectWithClassicCV(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Nu s-a putut decoda imaginea');
    }
    
    // 1. Convertire la grayscale
    final grayscale = img.grayscale(image);
    
    // 2. Edge detection (Sobel operator)
    final edges = _detectEdges(grayscale);
    
    // 3. Find contours/rectangles
    final rectangles = _findRectangles(edges);
    
    // 4. Filter și merge rectangles apropiate
    final filtered = _filterAndMergeRectangles(rectangles, image.width, image.height);
    
    // 5. Convert to ProductBoundingBox
    final detections = filtered.map((rect) => ProductBoundingBox(
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
      confidence: _calculateRectangleConfidence(rect, image),
      label: 'product',
    )).toList();
    
    // Sortăm după poziție (stânga-sus spre dreapta-jos)
    detections.sort((a, b) {
      final rowA = a.y ~/ (image.height / 3);
      final rowB = b.y ~/ (image.height / 3);
      if (rowA != rowB) return rowA.compareTo(rowB);
      return a.x.compareTo(b.x);
    });
    
    debugPrint('📦 Classic CV a detectat ${detections.length} produse');
    return detections.take(maxDetections).toList();
  }

  /// Edge detection folosind Sobel operator
  img.Image _detectEdges(img.Image grayscale) {
    final width = grayscale.width;
    final height = grayscale.height;
    final edges = img.Image(width: width, height: height);
    
    // Sobel kernels
    const sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]
    ];
    
    const sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1]
    ];
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double gx = 0;
        double gy = 0;
        
        // Apply Sobel kernels
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = grayscale.getPixel(x + kx, y + ky);
            final intensity = pixel.r;
            
            gx += intensity * sobelX[ky + 1][kx + 1];
            gy += intensity * sobelY[ky + 1][kx + 1];
          }
        }
        
        // Calculate edge magnitude
        final magnitude = sqrt(gx * gx + gy * gy);
        
        // Threshold și set pixel
        if (magnitude > edgeThreshold) {
          edges.setPixelRgb(x, y, 255, 255, 255);
        } else {
          edges.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    
    // Apply morphological operations pentru a închide golurile
    return _morphologicalClose(edges);
  }

  /// Morphological closing pentru a conecta edge-urile
  img.Image _morphologicalClose(img.Image binary) {
    // Dilatare urmată de eroziune
    final dilated = _dilate(binary, 2);
    return _erode(dilated, 2);
  }

  /// Dilatare binară
  img.Image _dilate(img.Image binary, int kernelSize) {
    final result = img.Image(width: binary.width, height: binary.height);
    
    for (int y = 0; y < binary.height; y++) {
      for (int x = 0; x < binary.width; x++) {
        bool shouldSet = false;
        
        for (int ky = -kernelSize; ky <= kernelSize && !shouldSet; ky++) {
          for (int kx = -kernelSize; kx <= kernelSize && !shouldSet; kx++) {
            final nx = x + kx;
            final ny = y + ky;
            
            if (nx >= 0 && nx < binary.width && ny >= 0 && ny < binary.height) {
              final pixel = binary.getPixel(nx, ny);
              if (pixel.r > 128) {
                shouldSet = true;
              }
            }
          }
        }
        
        if (shouldSet) {
          result.setPixelRgb(x, y, 255, 255, 255);
        } else {
          result.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    
    return result;
  }

  /// Eroziune binară
  img.Image _erode(img.Image binary, int kernelSize) {
    final result = img.Image(width: binary.width, height: binary.height);
    
    for (int y = 0; y < binary.height; y++) {
      for (int x = 0; x < binary.width; x++) {
        bool shouldSet = true;
        
        for (int ky = -kernelSize; ky <= kernelSize && shouldSet; ky++) {
          for (int kx = -kernelSize; kx <= kernelSize && shouldSet; kx++) {
            final nx = x + kx;
            final ny = y + ky;
            
            if (nx >= 0 && nx < binary.width && ny >= 0 && ny < binary.height) {
              final pixel = binary.getPixel(nx, ny);
              if (pixel.r < 128) {
                shouldSet = false;
              }
            }
          }
        }
        
        if (shouldSet) {
          result.setPixelRgb(x, y, 255, 255, 255);
        } else {
          result.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }
    
    return result;
  }

  /// Găsește dreptunghiuri în imagine binară
  List<Rectangle> _findRectangles(img.Image edges) {
    final rectangles = <Rectangle>[];
    final visited = List.generate(
      edges.height,
      (_) => List.filled(edges.width, false),
    );
    
    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        if (visited[y][x]) continue;
        
        final pixel = edges.getPixel(x, y);
        if (pixel.r > 128) {
          // Found white pixel, start flood fill to find connected component
          final rect = _floodFillBoundingBox(edges, x, y, visited);
          
          if (rect != null && _isValidProductRectangle(rect)) {
            rectangles.add(rect);
          }
        }
      }
    }
    
    return rectangles;
  }

  /// Flood fill pentru a găsi bounding box-ul unei componente conectate
  Rectangle? _floodFillBoundingBox(
    img.Image image,
    int startX,
    int startY,
    List<List<bool>> visited,
  ) {
    if (visited[startY][startX]) return null;
    
    final stack = <Point<int>>[Point(startX, startY)];
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;
    int pixelCount = 0;
    
    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;
      
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      if (visited[y][x]) continue;
      
      final pixel = image.getPixel(x, y);
      if (pixel.r < 128) continue; // Not white
      
      visited[y][x] = true;
      pixelCount++;
      
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);
      
      // Add neighbors
      stack.add(Point(x + 1, y));
      stack.add(Point(x - 1, y));
      stack.add(Point(x, y + 1));
      stack.add(Point(x, y - 1));
    }
    
    if (pixelCount < 100) return null; // Too small
    
    return Rectangle(
      x: minX.toDouble(),
      y: minY.toDouble(),
      width: (maxX - minX).toDouble(),
      height: (maxY - minY).toDouble(),
    );
  }

  /// Verifică dacă un dreptunghi este valid pentru un produs
  bool _isValidProductRectangle(Rectangle rect) {
    final area = rect.width * rect.height;
    final aspectRatio = rect.width / rect.height;
    
    return area >= minProductArea &&
           area <= maxProductArea &&
           aspectRatio > 0.2 &&
           aspectRatio < 5.0; // Produsele nu sunt foarte înguste sau late
  }

  /// Filtrează și combină dreptunghiuri suprapuse
  List<Rectangle> _filterAndMergeRectangles(
    List<Rectangle> rectangles,
    int imageWidth,
    int imageHeight,
  ) {
    if (rectangles.isEmpty) return [];
    
    // Sortăm după arie (cele mai mari primele)
    rectangles.sort((a, b) => (b.area).compareTo(a.area));
    
    final merged = <Rectangle>[];
    final used = List.filled(rectangles.length, false);
    
    for (int i = 0; i < rectangles.length; i++) {
      if (used[i]) continue;
      
      Rectangle current = rectangles[i];
      used[i] = true;
      
      // Găsim toate dreptunghiurile care se suprapun cu acesta
      bool foundOverlap;
      do {
        foundOverlap = false;
        
        for (int j = i + 1; j < rectangles.length; j++) {
          if (used[j]) continue;
          
          if (_rectanglesOverlap(current, rectangles[j], threshold: 0.3)) {
            // Merge rectangles
            current = _mergeRectangles(current, rectangles[j]);
            used[j] = true;
            foundOverlap = true;
          }
        }
      } while (foundOverlap);
      
      // Verificăm că dreptunghiul final este în limite rezonabile
      if (current.width < imageWidth * 0.8 && 
          current.height < imageHeight * 0.8) {
        merged.add(current);
      }
    }
    
    return merged;
  }

  /// Verifică dacă două dreptunghiuri se suprapun
  bool _rectanglesOverlap(Rectangle r1, Rectangle r2, {double threshold = 0.3}) {
    final intersectX = max(r1.x, r2.x);
    final intersectY = max(r1.y, r2.y);
    final intersectRight = min(r1.x + r1.width, r2.x + r2.width);
    final intersectBottom = min(r1.y + r1.height, r2.y + r2.height);
    
    if (intersectRight <= intersectX || intersectBottom <= intersectY) {
      return false;
    }
    
    final intersectArea = (intersectRight - intersectX) * (intersectBottom - intersectY);
    final minArea = min(r1.area, r2.area);
    
    return intersectArea / minArea > threshold;
  }

  /// Combină două dreptunghiuri
  Rectangle _mergeRectangles(Rectangle r1, Rectangle r2) {
    final minX = min(r1.x, r2.x);
    final minY = min(r1.y, r2.y);
    final maxX = max(r1.x + r1.width, r2.x + r2.width);
    final maxY = max(r1.y + r1.height, r2.y + r2.height);
    
    return Rectangle(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  /// Calculează confidence score pentru un dreptunghi detectat
  double _calculateRectangleConfidence(Rectangle rect, img.Image image) {
    // Factori pentru confidence:
    // 1. Aspect ratio (produsele au de obicei aspect ratio între 0.5 și 2)
    final aspectRatio = rect.width / rect.height;
    final aspectScore = 1.0 - min(
      (aspectRatio - 1.0).abs() / 2.0,
      1.0,
    );
    
    // 2. Size relative to image
    final sizeRatio = rect.area / (image.width * image.height);
    final sizeScore = min(sizeRatio * 10, 1.0); // Ideal ~10% din imagine
    
    // 3. Position (produsele sunt de obicei centrate, nu la margini)
    final centerX = rect.x + rect.width / 2;
    final centerY = rect.y + rect.height / 2;
    final distFromCenterX = (centerX - image.width / 2).abs() / (image.width / 2);
    final distFromCenterY = (centerY - image.height / 2).abs() / (image.height / 2);
    final positionScore = 1.0 - (distFromCenterX + distFromCenterY) / 2;
    
    // Weighted average
    return (aspectScore * 0.3 + sizeScore * 0.4 + positionScore * 0.3)
        .clamp(minConfidenceScore, 1.0);
  }

  /// Generează un grid uniform ca fallback
  List<ProductBoundingBox> _generateUniformGrid(int rows, int cols) {
    final boxes = <ProductBoundingBox>[];
    
    const imageWidth = 1000.0; // Valori normalizate
    const imageHeight = 1000.0;
    
    final cellWidth = imageWidth / cols;
    final cellHeight = imageHeight / rows;
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        boxes.add(ProductBoundingBox(
          x: col * cellWidth,
          y: row * cellHeight,
          width: cellWidth,
          height: cellHeight,
          confidence: 0.3, // Low confidence pentru grid
          label: 'grid_cell',
        ));
      }
    }
    
    return boxes;
  }

  /// Preprocesare imagine pentru model ML
  Float32List _preprocessImageForML(img.Image image) {
    // Resize la input size
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    
    // Normalizare și conversie la Float32List
    final buffer = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;
    
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        
        // Normalizare [-1, 1] pentru MobileNet
        buffer[pixelIndex++] = (pixel.r - 128.0) / 128.0;
        buffer[pixelIndex++] = (pixel.g - 128.0) / 128.0;
        buffer[pixelIndex++] = (pixel.b - 128.0) / 128.0;
      }
    }
    
    return buffer;
  }

  /// Cleanup
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
  }
}

/// Helper class pentru dreptunghiuri
class Rectangle {
  final double x;
  final double y;
  final double width;
  final double height;

  Rectangle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get area => width * height;
}