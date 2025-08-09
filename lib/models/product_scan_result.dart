// lib/models/product_scan_result.dart

import 'package:flutter/material.dart';
import 'product.dart';
import 'detected_product.dart';

/// Model pentru rezultatul scanării unui produs individual
class ProductScanResult {
  final DetectedProduct detectedProduct;
  final String productName;
  final Product? product; // Null dacă nu s-a găsit în OpenFood Facts
  final bool isSafe;
  final List<String> matchedAllergens;
  final double confidence;
  final String ocrText;
  final String? error;
  final Map<String, dynamic>? additionalInfo;

  ProductScanResult({
    required this.detectedProduct,
    required this.productName,
    this.product,
    required this.isSafe,
    required this.matchedAllergens,
    required this.confidence,
    required this.ocrText,
    this.error,
    this.additionalInfo,
  });

  /// Check if product was successfully identified
  bool get isIdentified => product != null;

  /// Check if scan had an error
  bool get hasError => error != null;

  /// Get status of the product
  ProductStatus get status {
    if (hasError) return ProductStatus.error;
    if (!isIdentified) return ProductStatus.unknown;
    if (isSafe) return ProductStatus.safe;
    return ProductStatus.dangerous;
  }

  /// Get color based on status
  Color get statusColor {
    switch (status) {
      case ProductStatus.safe:
        return Colors.green;
      case ProductStatus.dangerous:
        return Colors.red;
      case ProductStatus.unknown:
        return Colors.grey;
      case ProductStatus.error:
        return Colors.orange;
    }
  }

  /// Get border color for overlay
  Color get borderColor {
    if (isSafe) {
      return Colors.green.withOpacity(0.8);
    } else if (matchedAllergens.isNotEmpty) {
      // Severity based on number of allergens
      if (matchedAllergens.length >= 3) {
        return Colors.red.withOpacity(0.9);
      } else if (matchedAllergens.length >= 2) {
        return Colors.deepOrange.withOpacity(0.8);
      } else {
        return Colors.orange.withOpacity(0.8);
      }
    } else if (!isIdentified) {
      return Colors.grey.withOpacity(0.6);
    }
    return Colors.blue.withOpacity(0.5);
  }

  /// Get background color for overlay
  Color get backgroundColor {
    return borderColor.withOpacity(0.2);
  }

  /// Get icon for status
  IconData get statusIcon {
    switch (status) {
      case ProductStatus.safe:
        return Icons.check_circle;
      case ProductStatus.dangerous:
        return Icons.warning;
      case ProductStatus.unknown:
        return Icons.help_outline;
      case ProductStatus.error:
        return Icons.error_outline;
    }
  }

  /// Get display name (prioritize product name from API)
  String get displayName {
    if (product != null && product!.name.isNotEmpty) {
      return product!.name;
    }
    return productName.isNotEmpty ? productName : 'Produs neidentificat';
  }

  /// Get brand if available
  String? get brand => product?.brand;

  /// Get full name with brand
  String get fullName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand - $displayName';
    }
    return displayName;
  }

  /// Get allergen warning message
  String get allergenMessage {
    if (matchedAllergens.isEmpty) {
      return isSafe ? 'Nu conține alergenii tăi' : 'Status necunoscut';
    }
    
    if (matchedAllergens.length == 1) {
      return 'Conține ${matchedAllergens.first}';
    }
    
    return 'Conține: ${matchedAllergens.join(', ')}';
  }

  /// Get short status message
  String get statusMessage {
    switch (status) {
      case ProductStatus.safe:
        return '✅ Sigur';
      case ProductStatus.dangerous:
        return '⚠️ Conține alergeni';
      case ProductStatus.unknown:
        return '❓ Neidentificat';
      case ProductStatus.error:
        return '❌ Eroare';
    }
  }

  /// Get detailed message
  String get detailedMessage {
    final buffer = StringBuffer();
    
    buffer.writeln(fullName);
    
    if (hasError) {
      buffer.writeln('Eroare: $error');
    } else if (isIdentified) {
      buffer.writeln('Încredere: ${(confidence * 100).toStringAsFixed(0)}%');
      
      if (matchedAllergens.isNotEmpty) {
        buffer.writeln('Alergeni detectați:');
        for (final allergen in matchedAllergens) {
          buffer.writeln('  • $allergen');
        }
      } else if (isSafe) {
        buffer.writeln('✅ Produs sigur pentru tine');
      }
      
      if (product?.ingredients.isNotEmpty ?? false) {
        buffer.writeln('\nIngrediente:');
        buffer.writeln(product!.ingredients.take(5).join(', '));
        if (product!.ingredients.length > 5) {
          buffer.writeln('...și alte ${product!.ingredients.length - 5} ingrediente');
        }
      }
    } else {
      buffer.writeln('Produsul nu a fost găsit în baza de date');
      if (ocrText.isNotEmpty) {
        buffer.writeln('Text detectat: $ocrText');
      }
    }
    
    return buffer.toString();
  }

  /// Get confidence level
  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.9) return ConfidenceLevel.high;
    if (confidence >= 0.7) return ConfidenceLevel.medium;
    if (confidence >= 0.5) return ConfidenceLevel.low;
    return ConfidenceLevel.veryLow;
  }

  /// Get confidence color
  Color get confidenceColor {
    switch (confidenceLevel) {
      case ConfidenceLevel.high:
        return Colors.green;
      case ConfidenceLevel.medium:
        return Colors.blue;
      case ConfidenceLevel.low:
        return Colors.orange;
      case ConfidenceLevel.veryLow:
        return Colors.red;
    }
  }

  /// Check if contains specific allergen
  bool containsAllergen(String allergen) {
    return matchedAllergens.any((a) => 
      a.toLowerCase().contains(allergen.toLowerCase())
    );
  }

  /// Get severity level based on allergens
  AllergenSeverity get allergenSeverity {
    if (matchedAllergens.isEmpty) return AllergenSeverity.none;
    
    // Check for critical allergens (customize based on user preferences)
    final criticalAllergens = ['peanuts', 'nuts', 'shellfish', 'alune', 'arahide'];
    final hasCritical = matchedAllergens.any((allergen) =>
      criticalAllergens.any((critical) => 
        allergen.toLowerCase().contains(critical)
      )
    );
    
    if (hasCritical) return AllergenSeverity.critical;
    if (matchedAllergens.length >= 3) return AllergenSeverity.high;
    if (matchedAllergens.length >= 2) return AllergenSeverity.medium;
    return AllergenSeverity.low;
  }

  /// Get overlay widget data
  OverlayData get overlayData {
    return OverlayData(
      boundingBox: detectedProduct.boundingBox,
      color: borderColor,
      backgroundColor: backgroundColor,
      label: displayName,
      sublabel: statusMessage,
      icon: statusIcon,
      showWarning: !isSafe && matchedAllergens.isNotEmpty,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'detectedProduct': detectedProduct.toJson(),
      'productName': productName,
      'product': product?.toJson(),
      'isSafe': isSafe,
      'matchedAllergens': matchedAllergens,
      'confidence': confidence,
      'ocrText': ocrText,
      'error': error,
      'additionalInfo': additionalInfo,
    };
  }

  /// Create from JSON
  factory ProductScanResult.fromJson(Map<String, dynamic> json) {
    return ProductScanResult(
      detectedProduct: DetectedProduct.fromJson(json['detectedProduct']),
      productName: json['productName'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      isSafe: json['isSafe'],
      matchedAllergens: List<String>.from(json['matchedAllergens']),
      confidence: json['confidence'],
      ocrText: json['ocrText'],
      error: json['error'],
      additionalInfo: json['additionalInfo'],
    );
  }

  /// Create error result
  factory ProductScanResult.error({
    required DetectedProduct detectedProduct,
    required String error,
  }) {
    return ProductScanResult(
      detectedProduct: detectedProduct,
      productName: 'Eroare',
      product: null,
      isSafe: false,
      matchedAllergens: [],
      confidence: 0.0,
      ocrText: '',
      error: error,
    );
  }

  /// Create unknown result
  factory ProductScanResult.unknown({
    required DetectedProduct detectedProduct,
    String? ocrText,
  }) {
    return ProductScanResult(
      detectedProduct: detectedProduct,
      productName: ocrText ?? 'Produs necunoscut',
      product: null,
      isSafe: false,
      matchedAllergens: [],
      confidence: 0.3,
      ocrText: ocrText ?? '',
    );
  }

  /// Copy with modifications
  ProductScanResult copyWith({
    DetectedProduct? detectedProduct,
    String? productName,
    Product? product,
    bool? isSafe,
    List<String>? matchedAllergens,
    double? confidence,
    String? ocrText,
    String? error,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ProductScanResult(
      detectedProduct: detectedProduct ?? this.detectedProduct,
      productName: productName ?? this.productName,
      product: product ?? this.product,
      isSafe: isSafe ?? this.isSafe,
      matchedAllergens: matchedAllergens ?? this.matchedAllergens,
      confidence: confidence ?? this.confidence,
      ocrText: ocrText ?? this.ocrText,
      error: error ?? this.error,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() {
    return 'ProductScanResult(name: $productName, safe: $isSafe, '
           'allergens: ${matchedAllergens.length}, confidence: ${confidence.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductScanResult &&
           other.detectedProduct.id == detectedProduct.id &&
           other.productName == productName;
  }

  @override
  int get hashCode => detectedProduct.id.hashCode ^ productName.hashCode;
}

/// Enum for product status
enum ProductStatus {
  safe,
  dangerous,
  unknown,
  error,
}

/// Enum for confidence level
enum ConfidenceLevel {
  high,    // >= 90%
  medium,  // >= 70%
  low,     // >= 50%
  veryLow, // < 50%
}

/// Enum for allergen severity
enum AllergenSeverity {
  none,
  low,      // 1 allergen
  medium,   // 2 allergens
  high,     // 3+ allergens
  critical, // Contains critical allergens
}

/// Extension for AllergenSeverity
extension AllergenSeverityExtension on AllergenSeverity {
  String get displayName {
    switch (this) {
      case AllergenSeverity.none:
        return 'Fără alergeni';
      case AllergenSeverity.low:
        return 'Risc scăzut';
      case AllergenSeverity.medium:
        return 'Risc mediu';
      case AllergenSeverity.high:
        return 'Risc ridicat';
      case AllergenSeverity.critical:
        return 'Risc critic';
    }
  }

  Color get color {
    switch (this) {
      case AllergenSeverity.none:
        return Colors.green;
      case AllergenSeverity.low:
        return Colors.yellow;
      case AllergenSeverity.medium:
        return Colors.orange;
      case AllergenSeverity.high:
        return Colors.deepOrange;
      case AllergenSeverity.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case AllergenSeverity.none:
        return Icons.check_circle;
      case AllergenSeverity.low:
        return Icons.info_outline;
      case AllergenSeverity.medium:
        return Icons.warning_amber;
      case AllergenSeverity.high:
        return Icons.warning;
      case AllergenSeverity.critical:
        return Icons.dangerous;
    }
  }
}

/// Data class for overlay rendering
class OverlayData {
  final ProductBoundingBox boundingBox;
  final Color color;
  final Color backgroundColor;
  final String label;
  final String sublabel;
  final IconData icon;
  final bool showWarning;

  OverlayData({
    required this.boundingBox,
    required this.color,
    required this.backgroundColor,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.showWarning,
  });
}