import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../modules/image_selector.dart';
import '../modules/ocr_service.dart';
import '../modules/eu_result_handler.dart';
import 'profile_screen.dart';
import 'barcode_scanner_screen.dart';
import '../widgets/quick_settings_widgets.dart';
import '../services/enhanced_image_processor.dart';
import '../services/quality_aware_ocr_service.dart';
import '../controllers/scan_history_controller.dart';
import '../services/local_storage_service.dart';
import '../models/scan_history_entry.dart';
import '../screens/scan_history_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // Services - Updated to use EU system
  final UserService _userService = UserService();
  final ImageSelector _imageSelector = ImageSelector();
  final OcrService _ocrService = OcrService();
  final EUResultHandler _resultHandler = EUResultHandler();
  final ScanHistoryController _historyController = ScanHistoryController(LocalStorageService());

  // State pentru scanning
  File? selectedImage;
  bool isProcessing = false;
  String? detectedText;
  List<String> detectedAllergens = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initializeEUSystem();
  }

  Future<void> _loadUser() async {
    try {
      await _userService.loadUserProfile();
      setState(() {});
    } catch (e) {
      debugPrint('Eroare la încărcarea utilizatorului: $e');
    }
  }

  /// Initialize the EU allergen detection system
  Future<void> _initializeEUSystem() async {
    try {
      await _resultHandler.initialize();
      debugPrint('✅ EU Allergen System initialized');
    } catch (e) {
      debugPrint('❌ Error initializing EU system: $e');
    }
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildHistoryPage();
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildBarcodeAction() {
    return _buildQuickAction(
      icon: Icons.qr_code_scanner,
      title: 'Barcode',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BarcodeScannerScreen(),
          ),
        );
      },
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header personalizat cu numele utilizatorului
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bună, ${_userService.currentUser?.name ?? 'Utilizator'}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A3D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Să scanăm produse pentru siguranța ta',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar utilizator
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6B9B76),
                    backgroundImage: _userService.currentUser?.hasAvatar == true
                        ? FileImage(File(_userService.currentUser!.avatarPath!))
                        : null,
                    child: _userService.currentUser?.hasAvatar != true
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistici utilizator
            if (_userService.currentUser != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber, 
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF81c784) 
                        : const Color(0xFF5a7d5a)
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Monitorizezi ${_userService.currentUser!.allergenCount} ${_userService.currentUser!.allergenCount == 1 ? 'alergen' : 'alergeni'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF81c784)
                          : const Color(0xFF5a7d5a),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Scanning Area
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B9B76),
                    Color(0xFF5A8A65),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF2D5A3D),
                          ),
                          label: Text(
                            'Scanează Produsul',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFF121b16) 
                                  : const Color(0xFF2D5A3D),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFFa5d6a7) 
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.file(
                            selectedImage!,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedImage = null;
                                    detectedText = null;
                                    detectedAllergens = [];
                                    errorMessage = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Loading overlay
                          if (isProcessing)
                            Container(
                              width: double.infinity,
                              height: 300,
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Analizez pentru alergeni...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Rezultate rapide
                          if (!isProcessing && selectedImage != null && detectedAllergens.isNotEmpty)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${detectedAllergens.length} alergeni!',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Butoane pentru rezultate
                          if (!isProcessing && selectedImage != null)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  // Buton pentru rezultate principale
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: _showResults,
                                      icon: const Icon(Icons.visibility, size: 18),
                                      label: const Text('Vezi Rezultate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: detectedAllergens.isNotEmpty 
                                            ? Colors.red 
                                            : const Color(0xFF2D5A3D),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Buton pentru detalii
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showDetailedResults,
                                      icon: const Icon(Icons.list, size: 18),
                                      label: const Text('Detalii'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: detectedAllergens.isNotEmpty 
                                              ? Colors.red 
                                              : const Color(0xFF2D5A3D),
                                        ),
                                        foregroundColor: detectedAllergens.isNotEmpty 
                                            ? Colors.red 
                                            : const Color(0xFF2D5A3D),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 40),

            // Quick Actions
            Text(
              'Acțiuni Rapide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFFe8f5e9) 
                    : const Color(0xFF2D5A3D),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuickAction(
                  icon: Icons.camera_alt,
                  title: 'Cameră',
                  onTap: _pickImageFromCamera,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickAction(
                  icon: Icons.qr_code_scanner,
                  title: 'Barcode',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BarcodeScannerScreen(),
                      ),
                    );
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickAction(
                  icon: Icons.camera_enhance,
                  title: 'Smart Camera',
                  onTap: () {
                    Navigator.pushNamed(context, '/smart-camera');
                  },
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickAction(
                  icon: Icons.photo_library,
                  title: 'Galerie',
                  onTap: _pickImageFromGallery,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickAction(
                  icon: Icons.person,
                  title: 'Profil',
                  onTap: () => setState(() => _currentIndex = 2),
                )),
                const SizedBox(width: 12),
                // Placeholder pentru simetrie
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF81c784)
              : const Color.fromARGB(255, 232, 235, 232),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPage() {
    return ChangeNotifierProvider.value(
      value: _historyController,
      child: const HistoryScreen(),
    );
  }

  // Toate metodele pentru procesarea imaginilor
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        errorMessage = null;
      });
      
      final File? image = await _imageSelector.pickFromGallery();
      if (image != null) {
        setState(() {
          selectedImage = image;
          detectedText = null;
          detectedAllergens = [];
        });
        await _processImage();
      }
    } catch (e) {
      _showErrorDialog('Eroare la selectarea imaginii: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      setState(() {
        errorMessage = null;
      });
      
      final File? image = await _imageSelector.pickFromCamera();
      if (image != null) {
        setState(() {
          selectedImage = image;
          detectedText = null;
          detectedAllergens = [];
        });
        await _processImage();
      }
    } catch (e) {
      _showErrorDialog('Eroare la capturarea imaginii: $e');
    }
  }

  Future<void> _processImage() async {
    if (selectedImage == null) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      debugPrint('🔄 Începe procesarea cu sistemul EU...');

      final enhancedProcessor = EnhancedImageProcessor();
      final variants = await enhancedProcessor.createMultipleVariants(selectedImage!);
      final qualityOcr = QualityAwareOcrService();
      final ocrResult = await qualityOcr.extractTextMultiAttempt(variants);

      if (!ocrResult.isReliable) {
        _showQualityWarning(ocrResult.issues, ocrResult.suggestions);
      }

      final extractedText = ocrResult.text;
      
      // Use EU system for allergen detection
      final foundAllergens = await _resultHandler.findAllergensSimple(extractedText);

      setState(() {
        detectedText = extractedText;
        detectedAllergens = foundAllergens;
        isProcessing = false;
      });

      // Save to history
      final entry = ScanHistoryEntry(
        imagePath: selectedImage!.path,
        detectedAllergens: detectedAllergens,
        timestamp: DateTime.now(),
      );
      await _historyController.addEntry(entry);

      _showResults();
      
    } catch (e) {
      debugPrint('❌ Eroare la procesare: $e');
      setState(() {
        isProcessing = false;
        errorMessage = e.toString();
      });
      _showErrorDialog('Eroare la procesarea imaginii: $e');
    }
  }

  void _showQualityWarning(List<String> issues, List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Calitate slabă'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Probleme detectate:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...issues.map((issue) => Text('• $issue')),
            const SizedBox(height: 16),
            const Text('Sugestii:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...suggestions.map((suggestion) => Text('• $suggestion')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Înțeleg'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
            child: const Text('Poză nouă'),
          ),
        ],
      ),
    );
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                detectedAllergens.isEmpty ? Icons.check_circle : Icons.warning,
                color: detectedAllergens.isEmpty ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
  detectedAllergens.isEmpty 
    ? '🛡️ Produs Sigur!' 
    : '⚠️ ALERGEN DETECTAT!',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: detectedAllergens.isEmpty ? Colors.green : Colors.red,
  ),
),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detectedAllergens.isEmpty)
                Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.green.shade300),
  ),
  child: Column(
    children: [
      const Icon(Icons.check_circle, color: Colors.green, size: 32),
      const SizedBox(height: 8),
      Text(
        'Produs Sigur Pentru Tine!',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
      Text(
        'Nu conține alergenii din profilul tău',
        style: TextStyle(color: Colors.green.shade600),
      ),
    ],
  ),
)
              else ...[
                const Text('Alergeni detectați din profilul tău:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...detectedAllergens.map((allergen) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Container(
  margin: const EdgeInsets.symmetric(vertical: 4),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.red.shade300),
  ),
  child: Row(
    children: [
      const Icon(Icons.warning, color: Colors.red, size: 20),
      const SizedBox(width: 8),
      Text(
        allergen.toUpperCase(), 
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
      ),
    ],
  ),
),
                      ],
                    ),
                  ),
                ),
              ],
              if (detectedText?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                ExpansionTile(
  title: const Row(
    children: [
      Icon(Icons.text_fields, size: 16, color: Colors.blue),
      SizedBox(width: 8),
      Text('Text Detectat OCR', style: TextStyle(fontSize: 14)),
    ],
  ),
  children: [
    Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      constraints: const BoxConstraints(maxHeight: 150),
      child: SingleChildScrollView(
        child: Text(
          detectedText!,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontFamily: 'monospace',
            height: 1.3,
          ),
        ),
      ),
    ),
  ],
),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Închide'),
            ),
            if (detectedAllergens.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDetailedResults();
                },
                icon: const Icon(Icons.info, size: 18),
                label: const Text('Detalii EU'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Show detailed EU-compliant results
  void _showDetailedResults() async {
    if (detectedText == null) return;

    try {
      final safetyResult = await _resultHandler.analyzeSafety(detectedText!);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  safetyResult.getIndicatorColor() == Colors.green ? Icons.shield : Icons.warning,
                  color: safetyResult.getIndicatorColor(),
                ),
                const SizedBox(width: 8),
                const Text('Analiză EU Completă'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status general
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: safetyResult.getIndicatorColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: safetyResult.getIndicatorColor()),
                    ),
                    child: Column(
                      children: [
                        Text(
                          safetyResult.getMessage('ro'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: safetyResult.getIndicatorColor(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Nivel risc: ${safetyResult.riskLevel.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: safetyResult.getIndicatorColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alergeni relevanți pentru utilizator
                  if (safetyResult.userRelevantAllergens.isNotEmpty) ...[
                    const Text('⚠️ Alergeni pentru tine:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    ...safetyResult.userRelevantAllergens.map((match) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Text('EU ${match.euCode}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(match.allergenData.nameRO)),
                            Text('${(match.confidence * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Toți alergenii detectați
                  if (safetyResult.allDetectedAllergens.isNotEmpty) ...[
                    const Text('📋 Toți alergenii detectați:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...safetyResult.allDetectedAllergens.map((match) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text('EU ${match.euCode}:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(match.allergenData.nameRO, style: const TextStyle(fontSize: 11))),
                            Text('${(match.confidence * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Închide'),
              ),
              if (safetyResult.userRelevantAllergens.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAllergenAdvice(safetyResult.userRelevantAllergens);
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Sfaturi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing detailed results: $e');
      _showErrorDialog('Eroare la afișarea rezultatelor detaliate: $e');
    }
  }

  /// Show advice for detected allergens
  void _showAllergenAdvice(List<dynamic> allergenMatches) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Sfaturi importante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acest produs conține alergeni pentru care ești sensibil:'),
            const SizedBox(height: 8),
            ...allergenMatches.map((match) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${match.allergenData.nameRO.toUpperCase()} (EU ${match.euCode})', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            )),
            const SizedBox(height: 12),
            const Text(
              'Recomandări:\n• Evită consumul acestui produs\n• Verifică întotdeauna eticheta pentru codul EU\n• Consultă medicul pentru informații suplimentare\n• Păstrează lista alergenilor EU la îndemână',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Am înțeles'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eroare'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Selectează sursa imaginii',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Cameră',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1e2b25) 
              : const Color(0xFF6B9B76),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF81c784)
                  : Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const QuickSettingsRow(),
            Expanded(
              child: _getCurrentPage(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Acasă',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Istoric',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}