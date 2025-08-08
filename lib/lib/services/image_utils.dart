import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'dart:ui';

Future<File> cropProductImage(File originalImage, Rect boundingBox) async {
  final bytes = await originalImage.readAsBytes();
  final image = img.decodeImage(bytes)!;

  // asigură coordonate în interiorul imaginii
  final x = math.max(0, boundingBox.left.toInt());
  final y = math.max(0, boundingBox.top.toInt());
  final w = math.min(image.width - x, boundingBox.width.toInt());
  final h = math.min(image.height - y, boundingBox.height.toInt());

  final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);

  final tempDir = await getTemporaryDirectory();
  final out = File('${tempDir.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await out.writeAsBytes(img.encodeJpg(cropped, quality: 85));
  return out;
}
