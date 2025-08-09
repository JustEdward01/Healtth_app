// lib/models/shelf_scan_result.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'product_scan_result.dart';

/// Model pentru rezultatul complet al scanării unui raft
class ShelfScanResult {
  final String scanId;
  final DateTime timestamp;
  final List<ProductScanResult> products;
  final int totalProductsDetected;
  final int safeProducts;
  final int dangerousProducts;
  final int unknownProducts;
  final List<String> userAllergens;
  final int processingTimeMs;
  final File imageFile;
  final Map<String, dynamic>? metadata;

  ShelfScanResult({
    required this.scanId,
    required this.timestamp,
    required this.products,
    required this.totalProductsDetected,
    required this.safeProducts,
    required this.dangerousProducts,
    required this.unknownProducts,
    required this.userAllergens,
    required this.processingTimeMs,
    required this.imageFile,
    this.metadata,
  });

  /// Calculate safety score (0-100)
  double get safetyScore {
    if (totalProductsDetected == 0) return 0;
    
    // Safe products contribute positively
    // Dangerous products contribute negatively
    // Unknown products are neutral but slightly negative
    
    final safeRatio = safeProducts / totalProductsDetected;
    final dangerousRatio = dangerousProducts / totalProductsDetected;
    final unknownRatio = unknownProducts / totalProductsDetected;
    
    // Formula: 100 * safe - 50 * dangerous - 10 * unknown
    final score = (100 * safeRatio - 50 * dangerousRatio - 10 * unknownRatio)
        .clamp(0.0, 100.0);
    
    return score;
  }

  /// Get safety level based on score
  ShelfSafetyLevel get safetyLevel {
    final score = safetyScore;
    
    if (score >= 80) return ShelfSafetyLevel.safe;
    if (score >= 60) return ShelfSafetyLevel.mostlySafe;
    if (score >= 40) return ShelfSafetyLevel.caution;
    if (score >= 20) return ShelfSafetyLevel.warning;
    return ShelfSafetyLevel.danger;
  }

  /// Get color for safety level
  Color get safetyColor {
    switch (safetyLevel) {
      case ShelfSafetyLevel.safe:
        return Colors.green;
      case ShelfSafetyLevel.mostlySafe:
        return Colors.lightGreen;
      case ShelfSafetyLevel.caution:
        return Colors.orange;
      case ShelfSafetyLevel.warning:
        return Colors.deepOrange;
      case ShelfSafetyLevel.danger:
        return Colors.red;
    }
  }

  /// Get icon for safety level
  IconData get safetyIcon {
    switch (safetyLevel) {
      case ShelfSafetyLevel.safe:
        return Icons.check_circle;
      case ShelfSafetyLevel.mostlySafe:
        return Icons.check_circle_outline;
      case ShelfSafetyLevel.caution:
        return Icons.warning_amber;
      case ShelfSafetyLevel.warning:
        return Icons.warning;
      case ShelfSafetyLevel.danger:
        return Icons.dangerous;
    }
  }

  /// Get safety message
  String get safetyMessage {
    switch (safetyLevel) {
      case ShelfSafetyLevel.safe:
        return 'Toate produsele sunt sigure pentru tine!';
      case ShelfSafetyLevel.mostlySafe:
        return 'Majoritatea produselor sunt sigure';
      case ShelfSafetyLevel.caution:
        return 'Atenție! Unele produse conțin alergeni';
      case ShelfSafetyLevel.warning:
        return 'Avertisment! Mai multe produse conțin alergeni';
      case ShelfSafetyLevel.danger:
        return 'Pericol! Multe produse conțin alergeni periculoși';
    }
  }

  /// Get list of dangerous products
  List<ProductScanResult> get dangerousProductsList {
    return products.where((p) => !p.isSafe && p.matchedAllergens.isNotEmpty).toList();
  }

  /// Get list of safe products
  List<ProductScanResult> get safeProductsList {
    return products.where((p) => p.isSafe).toList();
  }

  /// Get list of unknown products
  List<ProductScanResult> get unknownProductsList {
    return products.where((p) => p.product == null).toList();
  }

  /// Get all detected allergens across all products
  Set<String> get allDetectedAllergens {
    final allergens = <String>{};
    for (final product in products) {
      allergens.addAll(product.matchedAllergens);
    }
    return allergens;
  }

  /// Get allergen statistics
  Map<String, int> get allergenStatistics {
    final stats = <String, int>{};
    for (final product in products) {
      for (final allergen in product.matchedAllergens) {
        stats[allergen] = (stats[allergen] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// Get most common allergen
  String? get mostCommonAllergen {
    final stats = allergenStatistics;
    if (stats.isEmpty) return null;
    
    return stats.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Processing time in seconds
  double get processingTimeSeconds => processingTimeMs / 1000.0;

  /// Average confidence across all products
  double get averageConfidence {
    if (products.isEmpty) return 0;
    final sum = products.fold<double>(0, (sum, p) => sum + p.confidence);
    return sum / products.length;
  }

  /// Check if scan was successful
  bool get isSuccessful => totalProductsDetected > 0;

  /// Check if any dangerous products were found
  bool get hasDangerousProducts => dangerousProducts > 0;

  /// Get summary text
  String get summary {
    if (!isSuccessful) {
      return 'Nu s-au detectat produse în imagine';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Scanare completă în ${processingTimeSeconds.toStringAsFixed(1)}s');
    buffer.writeln('Total produse: $totalProductsDetected');
    
    if (safeProducts > 0) {
      buffer.writeln('✅ Sigure: $safeProducts');
    }
    if (dangerousProducts > 0) {
      buffer.writeln('⚠️ Cu alergeni: $dangerousProducts');
    }
    if (unknownProducts > 0) {
      buffer.writeln('❓ Necunoscute: $unknownProducts');
    }
    
    if (allDetectedAllergens.isNotEmpty) {
      buffer.writeln('\nAlergeni detectați:');
      for (final allergen in allDetectedAllergens) {
        final count = allergenStatistics[allergen];
        buffer.writeln('  • $allergen ($count produse)');
      }
    }
    
    return buffer.toString();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'scanId': scanId,
      'timestamp': timestamp.toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
      'totalProductsDetected': totalProductsDetected,
      'safeProducts': safeProducts,
      'dangerousProducts': dangerousProducts,
      'unknownProducts': unknownProducts,
      'userAllergens': userAllergens,
      'processingTimeMs': processingTimeMs,
      'imagePath': imageFile.path,
      'metadata': metadata,
      'safetyScore': safetyScore,
      'safetyLevel': safetyLevel.toString(),
      'allDetectedAllergens': allDetectedAllergens.toList(),
      'allergenStatistics': allergenStatistics,
    };
  }

  /// Create from JSON
  factory ShelfScanResult.fromJson(Map<String, dynamic> json) {
    return ShelfScanResult(
      scanId: json['scanId'],
      timestamp: DateTime.parse(json['timestamp']),
      products: (json['products'] as List)
          .map((p) => ProductScanResult.fromJson(p))
          .toList(),
      totalProductsDetected: json['totalProductsDetected'],
      safeProducts: json['safeProducts'],
      dangerousProducts: json['dangerousProducts'],
      unknownProducts: json['unknownProducts'],
      userAllergens: List<String>.from(json['userAllergens']),
      processingTimeMs: json['processingTimeMs'],
      imageFile: File(json['imagePath']),
      metadata: json['metadata'],
    );
  }

  /// Create empty result
  factory ShelfScanResult.empty() {
    return ShelfScanResult(
      scanId: 'empty',
      timestamp: DateTime.now(),
      products: [],
      totalProductsDetected: 0,
      safeProducts: 0,
      dangerousProducts: 0,
      unknownProducts: 0,
      userAllergens: [],
      processingTimeMs: 0,
      imageFile: File(''),
    );
  }

  /// Copy with modifications
  ShelfScanResult copyWith({
    String? scanId,
    DateTime? timestamp,
    List<ProductScanResult>? products,
    int? totalProductsDetected,
    int? safeProducts,
    int? dangerousProducts,
    int? unknownProducts,
    List<String>? userAllergens,
    int? processingTimeMs,
    File? imageFile,
    Map<String, dynamic>? metadata,
  }) {
    return ShelfScanResult(
      scanId: scanId ?? this.scanId,
      timestamp: timestamp ?? this.timestamp,
      products: products ?? this.products,
      totalProductsDetected: totalProductsDetected ?? this.totalProductsDetected,
      safeProducts: safeProducts ?? this.safeProducts,
      dangerousProducts: dangerousProducts ?? this.dangerousProducts,
      unknownProducts: unknownProducts ?? this.unknownProducts,
      userAllergens: userAllergens ?? this.userAllergens,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      imageFile: imageFile ?? this.imageFile,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ShelfScanResult(scanId: $scanId, products: ${products.length}, '
           'safe: $safeProducts, dangerous: $dangerousProducts, '
           'unknown: $unknownProducts, safetyScore: ${safetyScore.toStringAsFixed(1)})';
  }
}

/// Enum pentru nivelul de siguranță al raftului
enum ShelfSafetyLevel {
  safe,       // 80-100% safe products
  mostlySafe, // 60-80% safe products
  caution,    // 40-60% safe products
  warning,    // 20-40% safe products
  danger,     // 0-20% safe products
}

/// Extension pentru ShelfSafetyLevel
extension ShelfSafetyLevelExtension on ShelfSafetyLevel {
  String get displayName {
    switch (this) {
      case ShelfSafetyLevel.safe:
        return 'Sigur';
      case ShelfSafetyLevel.mostlySafe:
        return 'Majoritar Sigur';
      case ShelfSafetyLevel.caution:
        return 'Atenție';
      case ShelfSafetyLevel.warning:
        return 'Avertisment';
      case ShelfSafetyLevel.danger:
        return 'Pericol';
    }
  }

  String get emoji {
    switch (this) {
      case ShelfSafetyLevel.safe:
        return '✅';
      case ShelfSafetyLevel.mostlySafe:
        return '👍';
      case ShelfSafetyLevel.caution:
        return '⚠️';
      case ShelfSafetyLevel.warning:
        return '🚨';
      case ShelfSafetyLevel.danger:
        return '❌';
    }
  }
}