import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../../providers/allergen_provider.dart';
import '../../../models/allergen/allergen_match.dart';

class AllergenScannerScreen extends StatefulWidget {
  const AllergenScannerScreen({super.key});

  @override
  State<AllergenScannerScreen> createState() => _AllergenScannerScreenState();
}

class _AllergenScannerScreenState extends State<AllergenScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Alergeni'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Consumer<AllergenProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildCameraPreview(),
              ),
              
              if (provider.userAllergens.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alergiile tale: ${provider.userAllergens.join(', ')}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: provider.isScanning ? null : _openCamera,
                  icon: Icon(provider.isScanning ? Icons.hourglass_empty : Icons.camera_alt),
                  label: Text(provider.isScanning ? 'Procesez...' : '📸 Scanează Ingrediente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              
              Expanded(
                flex: 2,
                child: _buildResults(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.camera_alt, size: 80, color: Colors.orange),
          ),
          const SizedBox(height: 20),
          const Text(
            '📸 Scanner Alergeni',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildFeatureRow('🎯', 'Detectează ingrediente periculoase'),
                _buildFeatureRow('⚠️', 'Identifică alergenii tăi'),
                _buildFeatureRow('✅', 'Rezultate instant'),
                _buildFeatureRow('📱', '100% offline și sigur'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Nu s-au găsit camere disponibile');
      }

      // Navigate to camera screen and get result
      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(camera: cameras.first),
        ),
      );

      if (result != null && mounted) {
        final provider = Provider.of<AllergenProvider>(context, listen: false);
        await provider.scanImage(result);
        
        // Cleanup the temporary file
        if (await result.exists()) {
          await result.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare camera: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

Widget _buildResults(AllergenProvider provider) {
  if (provider.isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const Icon(Icons.search, size: 32, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Analizez ingredientele...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Caut alergeni în imagine',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  if (provider.lastResult == null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Fă o poză la ingrediente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voi detecta automat alergenii tăi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  final result = provider.lastResult!;
  final safetyStatus = provider.getSafetyStatus();
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Card Header
        _buildStatusCard(safetyStatus, result.detectedAllergens.length),
        
        const SizedBox(height: 20),
        
        // Allergens Section
        if (result.detectedAllergens.isNotEmpty) ...[
          _buildSectionHeader('⚠️ Alergeni Detectați', result.detectedAllergens.length),
          const SizedBox(height: 12),
          ..._buildAllergenCards(result.detectedAllergens),
        ] else ...[
          _buildSafeCard(),
        ],
        
        const SizedBox(height: 20),
        
        // Action Buttons
        _buildActionButtons(),
      ],
    ),
  );
}

// 3. ACTUALIZEAZĂ metoda _buildAllergenCards:
List<Widget> _buildAllergenCards(List<AllergenMatch> allergens) {
  return allergens.map((allergen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allergen.allergen.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Găsit: "${allergen.foundTerm}"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Metoda: ${allergen.method}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(allergen.confidence),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(allergen.confidence * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(allergen.severityLevel),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        allergen.severityLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }).toList();
}

// 4. ADAUGĂ această metodă helper nouă:
Color _getSeverityColor(String severity) {
  switch (severity) {
    case 'CRITICAL': return Colors.red[900]!;
    case 'HIGH': return Colors.red;
    case 'MEDIUM': return Colors.orange;
    default: return Colors.amber;
  }
}
Widget _buildStatusCard(ProductSafetyStatus status, int allergenCount) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          _getStatusColor(status),
          _getStatusColor(status).withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusTitle(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusMessage(status, allergenCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionHeader(String title, int count) {
  return Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}


Widget _buildSafeCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: Colors.green,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Produsul este SIGUR!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nu s-au detectat alergeni din lista ta',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            // Scan again
            _openCamera();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Scanează Din Nou'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.orange),
            foregroundColor: Colors.orange,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            // Share results
            _shareResults();
          },
          icon: const Icon(Icons.share),
          label: const Text('Partajează'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ],
  );
}

// Helper methods
String _getStatusTitle(ProductSafetyStatus status) {
  switch (status) {
    case ProductSafetyStatus.safe: return 'PRODUS SIGUR';
    case ProductSafetyStatus.warning: return 'ATENȚIE';
    case ProductSafetyStatus.dangerous: return 'PERICOL';
    case ProductSafetyStatus.unknown: return 'ANALIZĂ INCOMPLETĂ';
  }
}

Color _getConfidenceColor(double confidence) {
  if (confidence >= 0.8) return Colors.red;
  if (confidence >= 0.6) return Colors.orange;
  return Colors.amber;
}

void _shareResults() {
  final provider = Provider.of<AllergenProvider>(context, listen: false);
  final result = provider.lastResult;
  
  if (result != null) {
    String shareText;
    if (result.detectedAllergens.isEmpty) {
      shareText = '✅ Produsul este SIGUR! Nu conține alergeni din lista mea.';
    } else {
      shareText = '⚠️ ATENȚIE! Acest produs conține ${result.detectedAllergens.length} alergeni: ';
      shareText += result.detectedAllergens.map((a) => a.allergen).join(', ');
      shareText += '\n\nDetalii:\n';
      for (var allergen in result.detectedAllergens) {
        shareText += '• ${allergen.allergen}: "${allergen.foundTerm}" (${(allergen.confidence * 100).toInt()}%)\n';
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rezultat: ${result.detectedAllergens.isEmpty ? "Sigur" : "${result.detectedAllergens.length} alergeni detectați"}'),
        backgroundColor: result.detectedAllergens.isEmpty ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
  Color _getStatusColor(ProductSafetyStatus status) {
    switch (status) {
      case ProductSafetyStatus.safe: return Colors.green;
      case ProductSafetyStatus.warning: return Colors.orange;
      case ProductSafetyStatus.dangerous: return Colors.red;
      case ProductSafetyStatus.unknown: return Colors.grey;
    }
  }

  IconData _getStatusIcon(ProductSafetyStatus status) {
    switch (status) {
      case ProductSafetyStatus.safe: return Icons.check_circle;
      case ProductSafetyStatus.warning: return Icons.warning;
      case ProductSafetyStatus.dangerous: return Icons.dangerous;
      case ProductSafetyStatus.unknown: return Icons.help_outline;
    }
  }

  String _getStatusMessage(ProductSafetyStatus status, int allergenCount) {
    switch (status) {
      case ProductSafetyStatus.safe: return 'SIGUR - Nu s-au detectat alergeni';
      case ProductSafetyStatus.warning: return 'ATENȚIE - $allergenCount alergeni detectați';
      case ProductSafetyStatus.dangerous: return 'PERICOL - $allergenCount alergeni periculoși!';
      case ProductSafetyStatus.unknown: return 'Nu s-au putut analiza datele';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner Alergeni'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 Detectează ingrediente din poze'),
            SizedBox(height: 8),
            Text('⚠️ Identifică alergenii din profilul tău'),
            SizedBox(height: 8),
            Text('✅ Analiză rapidă și precisă'),
            SizedBox(height: 8),
            Text('📱 Funcționează offline'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Simple Camera Screen for taking pictures
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      
      if (mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la fotografiere: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fotografiază ingredientele'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller),
                ),
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        onPressed: _takePicture,
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.camera, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}