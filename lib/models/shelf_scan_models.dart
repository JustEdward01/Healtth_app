import 'dart:io';
import 'dart:ui';

class ShelfScanResult {
  final int totalProducts;
  final List<ProductScanResult> safeProducts;
  final List<ProductScanResult> dangerousProducts;
  final File originalImage;

  List<ProductScanResult> get allProducts => [...safeProducts, ...dangerousProducts];

  ShelfScanResult({
    required this.totalProducts,
    required this.safeProducts,
    required this.dangerousProducts,
    required this.originalImage,
  });
}

class ProductScanResult {
  final String id;
  final String name;
  final String? brand;
  final Rect boundingBox;
  final bool isSafe;
  final List<String> allergens;
  final List<String> ingredients;
  final String? imageUrl;

  ProductScanResult({
    required this.id,
    required this.name,
    this.brand,
    required this.boundingBox,
    required this.isSafe,
    required this.allergens,
    required this.ingredients,
    this.imageUrl,
  });
}

class DetectedProduct {
  final String id;
  final Rect boundingBox;
  final double confidence;
  final String? name;

  DetectedProduct({
    required this.id,
    required this.boundingBox,
    required this.confidence,
    this.name,
  });
}
