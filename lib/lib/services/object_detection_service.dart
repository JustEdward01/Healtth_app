import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../models/shelf_scan_models.dart';

class ObjectDetectionService {
  final _uuid = Uuid();

  Future<List<DetectedProduct>> detectProducts(File imageFile, {int rows = 3, int cols = 4}) async {
    // grid-based detection: împarte imaginea în rows x cols
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];

    final imageW = decoded.width.toDouble();
    final imageH = decoded.height.toDouble();

    List<DetectedProduct> products = [];

    final cellW = imageW / cols;
    final cellH = imageH / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = (c * cellW).clamp(0, imageW).toDouble();
        final top = (r * cellH).clamp(0, imageH).toDouble();
        final width = cellW;
        final height = cellH;

        final rect = Rect.fromLTWH(left, top, width, height);

        products.add(DetectedProduct(
          id: _uuid.v4(),
          boundingBox: rect,
          confidence: 0.8, // heuristic
        ));
      }
    }

    return products;
  }
}
