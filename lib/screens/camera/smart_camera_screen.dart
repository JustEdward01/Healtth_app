import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../services/camera/smart_camera_service.dart';
import '../../models/camera/ingredient_zone.dart';
import '../../models/camera/photo_quality.dart';

class SmartCameraScreen extends StatefulWidget {
  const SmartCameraScreen({super.key});

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen> {
  CameraController? _controller;
  final _cameraService = SmartCameraService();
  
  IngredientZone? _currentZone;
  PhotoQuality _currentQuality = PhotoQuality.SEARCHING;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      await _cameraService.initialize();
      
      if (mounted) {
        setState(() {});
        _startLiveDetection();
      }
    }
  }

  void _startLiveDetection() {
    if (_controller == null) return;
    
    _cameraService.detectIngredientsLive(_controller!).listen((zone) {
      if (mounted) {
        setState(() {
          _currentZone = zone;
          _currentQuality = _cameraService.assessPhotoQuality(zone);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_controller?.value.isInitialized == true)
            Positioned.fill(
              child: CameraPreview(_controller!),
            ),

          if (_controller?.value.isInitialized != true)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Ingredient zone overlay
          if (_currentZone?.rect != null)
            Positioned(
              left: _currentZone!.rect!.left,
              top: _currentZone!.rect!.top,
              child: Container(
                width: _currentZone!.rect!.width,
                height: _currentZone!.rect!.height,
                decoration: BoxDecoration(
                  border: Border.all(color: _currentQuality.color, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          // Quality feedback
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_currentQuality.icon, color: _currentQuality.color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentQuality.message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Capture button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentQuality != PhotoQuality.TERRIBLE && !_isCapturing
                    ? _capturePhoto
                    : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _currentQuality == PhotoQuality.TERRIBLE 
                        ? Colors.grey 
                        : _currentQuality.color,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: _isCapturing
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.camera, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      final imageFile = File(image.path);
      
      if (mounted) {
        Navigator.pop(context, imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}