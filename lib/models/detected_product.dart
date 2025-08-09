// lib/models/detected_product.dart

import 'dart:io';
import 'package:flutter/material.dart';

/// Model pentru un produs detectat în imagine cu bounding box
class DetectedProduct {
  final String id;
  final ProductBoundingBox boundingBox;
  final double confidence;
  final File croppedImage;
  final String? label;
  final Map<String, dynamic>? metadata;

  DetectedProduct({
    required this.id,
    required this.boundingBox,
    required this.confidence,
    required this.croppedImage,
    this.label,
    this.metadata,
  });

  /// Get position in grid (if using grid detection)
  GridPosition? get gridPosition {
    if (id.startsWith('grid_')) {
      final parts = id.split('_');
      if (parts.length >= 3) {
        return GridPosition(
          row: int.tryParse(parts[1]) ?? 0,
          column: int.tryParse(parts[2]) ?? 0,
        );
      }
    }
    return null;
  }

  /// Check if this is from grid detection
  bool get isFromGrid => id.startsWith('grid_');

  /// Check if this is from ML detection
  bool get isFromML => id.startsWith('product_');

  /// Get detection method
  DetectionMethod get detectionMethod {
    if (isFromGrid) return DetectionMethod.grid;
    if (isFromML) return DetectionMethod.ml;
    return DetectionMethod.classic;
  }

  /// Get center point of bounding box
  Offset get center => boundingBox.center;

  /// Get area of bounding box
  double get area => boundingBox.area;

  /// Check if overlaps with another product
  bool overlaps(DetectedProduct other, {double threshold = 0.3}) {
    return boundingBox.overlaps(other.boundingBox, threshold: threshold);
  }

  /// Calculate distance to another product
  double distanceTo(DetectedProduct other) {
    final dx = center.dx - other.center.dx;
    final dy = center.dy - other.center.dy;
    return (dx * dx + dy * dy).sqrt();
  }

  /// Check if product is near edge of image
  bool isNearEdge(Size imageSize, {double margin = 50}) {
    return boundingBox.x < margin ||
           boundingBox.y < margin ||
           boundingBox.x + boundingBox.width > imageSize.width - margin ||
           boundingBox.y + boundingBox.height > imageSize.height - margin;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boundingBox': boundingBox.toJson(),
      'confidence': confidence,
      'croppedImagePath': croppedImage.path,
      'label': label,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory DetectedProduct.fromJson(Map<String, dynamic> json) {
    return DetectedProduct(
      id: json['id'],
      boundingBox: ProductBoundingBox.fromJson(json['boundingBox']),
      confidence: json['confidence'],
      croppedImage: File(json['croppedImagePath']),
      label: json['label'],
      metadata: json['metadata'],
    );
  }

  /// Copy with modifications
  DetectedProduct copyWith({
    String? id,
    ProductBoundingBox? boundingBox,
    double? confidence,
    File? croppedImage,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    return DetectedProduct(
      id: id ?? this.id,
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      croppedImage: croppedImage ?? this.croppedImage,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'DetectedProduct(id: $id, confidence: ${confidence.toStringAsFixed(2)}, '
           'bounds: $boundingBox, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Bounding box pentru produs detectat
class ProductBoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final double? confidence;
  final String? label;

  ProductBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence,
    this.label,
  });

  /// Get rectangle representation
  Rect get rect => Rect.fromLTWH(x, y, width, height);

  /// Get center point
  Offset get center => Offset(x + width / 2, y + height / 2);

  /// Get area
  double get area => width * height;

  /// Get aspect ratio
  double get aspectRatio => width / height;

  /// Get top-left corner
  Offset get topLeft => Offset(x, y);

  /// Get top-right corner
  Offset get topRight => Offset(x + width, y);

  /// Get bottom-left corner
  Offset get bottomLeft => Offset(x, y + height);

  /// Get bottom-right corner
  Offset get bottomRight => Offset(x + width, y + height);

  /// Get all corners
  List<Offset> get corners => [topLeft, topRight, bottomRight, bottomLeft];

  /// Check if point is inside bounding box
  bool contains(Offset point) {
    return point.dx >= x &&
           point.dx <= x + width &&
           point.dy >= y &&
           point.dy <= y + height;
  }

  /// Check if overlaps with another bounding box
  bool overlaps(ProductBoundingBox other, {double threshold = 0.0}) {
    final intersectX = x.clamp(other.x, other.x + other.width);
    final intersectY = y.clamp(other.y, other.y + other.height);
    final intersectRight = (x + width).clamp(other.x, other.x + other.width);
    final intersectBottom = (y + height).clamp(other.y, other.y + other.height);
    
    final intersectWidth = intersectRight - intersectX;
    final intersectHeight = intersectBottom - intersectY;
    
    if (intersectWidth <= 0 || intersectHeight <= 0) {
      return false;
    }
    
    if (threshold <= 0) {
      return true;
    }
    
    final intersectArea = intersectWidth * intersectHeight;
    final minArea = area < other.area ? area : other.area;
    
    return intersectArea / minArea > threshold;
  }

  /// Calculate intersection with another bounding box
  ProductBoundingBox? intersection(ProductBoundingBox other) {
    final intersectX = x.clamp(other.x, other.x + other.width);
    final intersectY = y.clamp(other.y, other.y + other.height);
    final intersectRight = (x + width).clamp(other.x, other.x + other.width);
    final intersectBottom = (y + height).clamp(other.y, other.y + other.height);
    
    final intersectWidth = intersectRight - intersectX;
    final intersectHeight = intersectBottom - intersectY;
    
    if (intersectWidth <= 0 || intersectHeight <= 0) {
      return null;
    }
    
    return ProductBoundingBox(
      x: intersectX,
      y: intersectY,
      width: intersectWidth,
      height: intersectHeight,
    );
  }

  /// Calculate union with another bounding box
  ProductBoundingBox union(ProductBoundingBox other) {
    final minX = x < other.x ? x : other.x;
    final minY = y < other.y ? y : other.y;
    final maxX = x + width > other.x + other.width ? x + width : other.x + other.width;
    final maxY = y + height > other.y + other.height ? y + height : other.y + other.height;
    
    return ProductBoundingBox(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
      confidence: confidence != null && other.confidence != null
          ? (confidence! + other.confidence!) / 2
          : confidence ?? other.confidence,
    );
  }

  /// Calculate IoU (Intersection over Union) with another bounding box
  double iou(ProductBoundingBox other) {
    final intersect = intersection(other);
    if (intersect == null) return 0.0;
    
    final unionArea = area + other.area - intersect.area;
    return intersect.area / unionArea;
  }

  /// Scale bounding box
  ProductBoundingBox scale(double factor) {
    final newWidth = width * factor;
    final newHeight = height * factor;
    final dx = (width - newWidth) / 2;
    final dy = (height - newHeight) / 2;
    
    return ProductBoundingBox(
      x: x + dx,
      y: y + dy,
      width: newWidth,
      height: newHeight,
      confidence: confidence,
      label: label,
    );
  }

  /// Expand bounding box by padding
  ProductBoundingBox expand(double padding) {
    return ProductBoundingBox(
      x: x - padding,
      y: y - padding,
      width: width + 2 * padding,
      height: height + 2 * padding,
      confidence: confidence,
      label: label,
    );
  }

  /// Normalize coordinates to [0, 1] range
  ProductBoundingBox normalize(Size imageSize) {
    return ProductBoundingBox(
      x: x / imageSize.width,
      y: y / imageSize.height,
      width: width / imageSize.width,
      height: height / imageSize.height,
      confidence: confidence,
      label: label,
    );
  }

  /// Denormalize from [0, 1] range to pixel coordinates
  ProductBoundingBox denormalize(Size imageSize) {
    return ProductBoundingBox(
      x: x * imageSize.width,
      y: y * imageSize.height,
      width: width * imageSize.width,
      height: height * imageSize.height,
      confidence: confidence,
      label: label,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'confidence': confidence,
      'label': label,
    };
  }

  /// Create from JSON
  factory ProductBoundingBox.fromJson(Map<String, dynamic> json) {
    return ProductBoundingBox(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
      confidence: json['confidence']?.toDouble(),
      label: json['label'],
    );
  }

  /// Create from Rect
  factory ProductBoundingBox.fromRect(Rect rect, {double? confidence, String? label}) {
    return ProductBoundingBox(
      x: rect.left,
      y: rect.top,
      width: rect.width,
      height: rect.height,
      confidence: confidence,
      label: label,
    );
  }

  @override
  String toString() {
    return 'BoundingBox(x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)}, '
           'w: ${width.toStringAsFixed(1)}, h: ${height.toStringAsFixed(1)}, '
           'confidence: ${confidence?.toStringAsFixed(2) ?? 'N/A'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductBoundingBox &&
           other.x == x &&
           other.y == y &&
           other.width == width &&
           other.height == height;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// Grid position for grid-based detection
class GridPosition {
  final int row;
  final int column;

  GridPosition({
    required this.row,
    required this.column,
  });

  /// Get linear index (for 4-column grid)
  int get index => row * 4 + column;

  /// Get display label
  String get label => 'R${row + 1}C${column + 1}';

  @override
  String toString() => 'GridPosition($row, $column)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridPosition &&
           other.row == row &&
           other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

/// Enum for detection method
enum DetectionMethod {
  ml,      // Machine Learning model
  classic, // Classic CV (edge detection)
  grid,    // Grid division fallback
}

/// Extension for DetectionMethod
extension DetectionMethodExtension on DetectionMethod {
  String get displayName {
    switch (this) {
      case DetectionMethod.ml:
        return 'ML Detection';
      case DetectionMethod.classic:
        return 'Computer Vision';
      case DetectionMethod.grid:
        return 'Grid Division';
    }
  }

  IconData get icon {
    switch (this) {
      case DetectionMethod.ml:
        return Icons.psychology;
      case DetectionMethod.classic:
        return Icons.image_search;
      case DetectionMethod.grid:
        return Icons.grid_on;
    }
  }

  double get baseConfidence {
    switch (this) {
      case DetectionMethod.ml:
        return 0.9;
      case DetectionMethod.classic:
        return 0.7;
      case DetectionMethod.grid:
        return 0.5;
    }
  }
}