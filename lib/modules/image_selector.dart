import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageSelector {
  final ImagePicker _picker = ImagePicker();

  /// Selectează imagine din galerie cu configurări optimizate pentru OCR
  Future<File?> pickFromGallery({
    double maxWidth = 1000,
    double maxHeight = 1000,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la selectarea imaginii din galerie: $e');
    }
  }

  /// Capturează imagine cu camera cu configurări optimizate pentru OCR
  Future<File?> pickFromCamera({
    double maxWidth = 1000,
    double maxHeight = 1000,
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la capturarea imaginii cu camera: $e');
    }
  }

  /// Selectează imagini multiple din galerie (pentru scanare în lot)
  Future<List<File>> pickMultipleFromGallery({
    double maxWidth = 1000,
    double maxHeight = 1000,
    int imageQuality = 85,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      
      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw Exception('Eroare la selectarea imaginilor multiple: $e');
    }
  }

  /// Configurări preset pentru diferite scenarii
  
  /// Configurare pentru calitate maximă (analiză detaliată)
  Future<File?> pickHighQuality({required ImageSource source}) async {
    return source == ImageSource.gallery
        ? pickFromGallery(maxWidth: 2000, maxHeight: 2000, imageQuality: 100)
        : pickFromCamera(maxWidth: 2000, maxHeight: 2000, imageQuality: 100);
  }

  /// Configurare pentru procesare rapidă (preview)
  Future<File?> pickLowQuality({required ImageSource source}) async {
    return source == ImageSource.gallery
        ? pickFromGallery(maxWidth: 500, maxHeight: 500, imageQuality: 60)
        : pickFromCamera(maxWidth: 500, maxHeight: 500, imageQuality: 60);
  }

  /// Configurare optimizată pentru OCR (text recognition)
  Future<File?> pickForOCR({required ImageSource source}) async {
    return source == ImageSource.gallery
        ? pickFromGallery(maxWidth: 1500, maxHeight: 1500, imageQuality: 90)
        : pickFromCamera(maxWidth: 1500, maxHeight: 1500, imageQuality: 90);
  }

  /// Verifică dacă camera este disponibilă pe dispozitiv
  Future<bool> isCameraAvailable() async {
    try {
      final cameras = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 100,
        maxHeight: 100,
      );
      return cameras != null;
    } catch (e) {
      return false;
    }
  }

  /// Obține informații despre imaginea selectată
  Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final stat = await imageFile.stat();
      return {
        'path': imageFile.path,
        'size': stat.size,
        'sizeKB': (stat.size / 1024).round(),
        'sizeMB': (stat.size / (1024 * 1024)).toStringAsFixed(2),
        'modified': stat.modified,
      };
    } catch (e) {
      return {'error': 'Nu se pot obține informații despre imagine: $e'};
    }
  }
}