import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/shelf_scanner_service.dart';
import '../models/shelf_scan_models.dart';

class ShelfScannerScreen extends StatefulWidget {
  @override
  State<ShelfScannerScreen> createState() => _ShelfScannerScreenState();
}

class _ShelfScannerScreenState extends State<ShelfScannerScreen> {
  File? _selectedImage;
  bool _isScanning = false;
  ShelfScanResult? _scanResult;
  String _progressMessage = '';
  int _currentProduct = 0;
  int _totalProducts = 0;

  final _shelfScannerService = ShelfScannerService();
  final List<String> _userAllergens = ['milk', 'peanuts', 'eggs']; // exemplu

  @override
  void dispose() {
    _shelfScannerService.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _scanResult = null;
    });
  }

  Future<void> _startScanning() async {
    if (_selectedImage == null) return;
    setState(() {
      _isScanning = true;
      _progressMessage = 'Început scan...';
      _currentProduct = 0;
      _totalProducts = 0;
    });

    _shelfScannerService.onProgress = (current, total, message) {
      setState(() {
        _currentProduct = current;
        _totalProducts = total;
        _progressMessage = message;
      });
    };

    try {
      final result = await _shelfScannerService.scanShelf(_selectedImage!, _userAllergens);
      setState(() {
        _scanResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare la scan: $e')));
    } finally {
      setState(() {
        _isScanning = false;
        _progressMessage = '';
      });
    }
  }

  // restul widget-urilor (_buildImageSection, _buildProgressSection, _buildActionButtons, _buildResultsOverlay)
  // păstrează implementarea din descrierea ta, dar asigură-te că folosești _scanResult?.allProducts pentru desenare.
}
