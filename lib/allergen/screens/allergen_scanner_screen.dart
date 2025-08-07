import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../providers/allergen_provider.dart';
import '../../screens/camera/smart_camera_screen.dart';

class AllergenScannerScreen extends StatefulWidget {
  const AllergenScannerScreen({super.key});

  @override
  State<AllergenScannerScreen> createState() => _AllergenScannerScreenState(); // 🔧 FIXED public
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
                child: _buildSmartCameraPreview(),
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
                  onPressed: provider.isScanning ? null : _openSmartCamera,
                  icon: Icon(provider.isScanning ? Icons.hourglass_empty : Icons.camera_enhance),
                  label: Text(provider.isScanning ? 'Procesez...' : '📸 Scanare Inteligentă'),
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

  Widget _buildSmartCameraPreview() {
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
              color: Colors.orange.withValues(alpha: 0.1), // 🔧 FIXED withOpacity
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.camera_enhance, size: 80, color: Colors.orange),
          ),
          const SizedBox(height: 20),
          const Text(
            '📸 Camera Inteligentă',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildFeatureRow('🎯', 'Detectează automat ingredientele'),
                _buildFeatureRow('📏', 'Ghidare pentru poza perfectă'),
                _buildFeatureRow('⚡', 'Feedback în timp real'),
                _buildFeatureRow('✂️', 'Auto-crop la zona relevantă'),
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

  Future<void> _openSmartCamera() async {
    try {
      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (context) => const SmartCameraScreen()),
      );

      if (result != null && mounted) { // 🔧 FIXED: Added mounted check
        final provider = Provider.of<AllergenProvider>(context, listen: false);
        await provider.scanImage(result);
        
        if (await result.exists()) {
          await result.delete();
        }
      }
    } catch (e) {
      if (mounted) { // 🔧 FIXED: Added mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildResults(AllergenProvider provider) {
    if (provider.isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizez imaginea...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (provider.lastResult == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_enhance, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Folosește camera inteligentă pentru detectarea optimă',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final result = provider.lastResult!;
    final safetyStatus = provider.getSafetyStatus();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(safetyStatus).withValues(alpha: 0.1), // 🔧 FIXED withOpacity
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStatusColor(safetyStatus)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(safetyStatus), color: _getStatusColor(safetyStatus)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusMessage(safetyStatus, result.detectedAllergens.length),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(safetyStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (result.detectedAllergens.isNotEmpty) ...[
            const Text('Alergeni detectați:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: result.detectedAllergens.length,
                itemBuilder: (context, index) {
                  final allergen = result.detectedAllergens[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: Text(allergen.allergen.toUpperCase()),
                      subtitle: Text('Găsit: "${allergen.foundTerm}"'),
                      trailing: Text('${(allergen.confidence * 100).toInt()}%'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
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
        title: const Text('Smart Camera'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 Detectare live a zonei ingrediente'),
            SizedBox(height: 8),
            Text('📏 Ghidare vizuală pentru poza perfectă'),
            SizedBox(height: 8),
            Text('⚡ Feedback în timp real'),
            SizedBox(height: 8),
            Text('📱 100% offline'),
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