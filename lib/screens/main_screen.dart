import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../modules/image_selector.dart';
import '../modules/ocr_service.dart';
import '../modules/result_handler.dart';
import 'profile_screen.dart';
import 'barcode_scanner_screen.dart';
import '../widgets/quick_settings_widgets.dart';
import '../services/enhanced_image_processor.dart';
import '../services/quality_aware_ocr_service.dart';
import '../modules/ocr_tolerant_result_handler.dart';
import '../widgets/visual_allergen_overlay.dart';
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
  
  // Services
  final UserService _userService = UserService();
  final ImageSelector _imageSelector = ImageSelector();
  final OcrService _ocrService = OcrService();
  final ResultHandler _resultHandler = ResultHandler();
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
  }

  Future<void> _loadUser() async {
    try {
      await _userService.loadUserProfile();
      setState(() {});
    } catch (e) {
      debugPrint('Eroare la încărcarea utilizatorului: $e');
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                            color: Colors.white.withValues(alpha: 0.2),
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
                          // ✨ BUTOANE NOOII - Vezi pe Imagine + Lista
                          if (!isProcessing && selectedImage != null)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  // Buton pentru overlay vizual - PRINCIPAL
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: _showVisualAllergenOverlay,
                                      icon: const Icon(Icons.visibility, size: 18),
                                      label: const Text('Vezi pe Imagine'),
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
                                  // Buton pentru rezultate tradiționale - SECUNDAR
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showResults,
                                      icon: const Icon(Icons.list, size: 18),
                                      label: const Text('Lista'),
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
              color: Colors.black.withValues(alpha: 0.05),
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
      debugPrint('🔄 Începe procesarea avansată...');

      final enhancedProcessor = EnhancedImageProcessor();
      final variants = await enhancedProcessor.createMultipleVariants(selectedImage!);
      final qualityOcr = QualityAwareOcrService();
      final ocrResult = await qualityOcr.extractTextMultiAttempt(variants);

      if (!ocrResult.isReliable) {
        _showQualityWarning(ocrResult.issues, ocrResult.suggestions);
      }

      final extractedText = ocrResult.text;
      
      final ocrTolerantDetector = OCRTolerantResultHandler();
      final foundAllergens = ocrTolerantDetector.findAllergensWithOCRTolerance(extractedText);
      
      final userAllergens = _userService.currentUser?.selectedAllergens ?? [];
      final relevantAllergens = foundAllergens.where((allergen) => userAllergens.contains(allergen)).toList();

      setState(() {
        detectedText = extractedText;
        detectedAllergens = relevantAllergens;
        isProcessing = false;
      });

      // Save to history
      final entry = ScanHistoryEntry(
        imagePath: selectedImage!.path,
        detectedAllergens: detectedAllergens,
        timestamp: DateTime.now(),
      );
      await _historyController.addEntry(entry);

      if (relevantAllergens.isNotEmpty) {
        await _showVisualAllergenOverlay();
      } else {
        _showResults();
      }
      
    } catch (e) {
      debugPrint('❌ Eroare la procesare: $e');
      setState(() {
        isProcessing = false;
        errorMessage = e.toString();
      });
      _showErrorDialog('Eroare la procesarea imaginii: $e');
    }
  }


  // ✨ NOUA METODĂ pentru overlay-ul vizual
  Future<void> _showVisualAllergenOverlay() async {
    if (selectedImage == null) return;

    try {
      // Detectează pozițiile alergenilor pe imagine
      final positionedAllergens = await AllergenPositionDetector.detectAllergenPositions(
        imageFile: selectedImage!,
        detectedAllergens: detectedAllergens,
      );

      if (mounted) {
        // Afișează overlay-ul vizual full-screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VisualAllergenOverlay(
              imageFile: selectedImage!,
              allergenMatches: positionedAllergens,
              onClose: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Eroare la afișarea overlay-ului vizual: $e');
      // Fallback la afișarea normală
      _showResults();
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
              Text(detectedAllergens.isEmpty ? 'Sigur pentru tine!' : 'Atenție!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detectedAllergens.isEmpty)
                const Text('Nu au fost detectați alergenii din profilul tău în acest produs.')
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
                        Text(allergen.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
              if (detectedText?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Text detectat (Debug)'),
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Text(
                          detectedText!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  _showVisualAllergenOverlay(); // Deschide overlay-ul vizual
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Vezi pe Imagine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
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

  // ✨ FAB pentru overlay rapid
  FloatingActionButton? get _buildOverlayFAB {
    if (selectedImage != null && detectedAllergens.isNotEmpty) {
      return FloatingActionButton(
        onPressed: _showVisualAllergenOverlay,
        backgroundColor: Colors.red,
        heroTag: "visual_overlay_fab",
        child: const Icon(
          Icons.visibility,
          color: Colors.white,
        ),
      );
    }
    return null;
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
      floatingActionButton: _buildOverlayFAB, // ✨ FAB pentru overlay
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