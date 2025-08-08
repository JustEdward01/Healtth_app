import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../modules/ocr_service.dart';
import '../modules/result_handler.dart';
import '../services/user_service.dart';
import '../models/product.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> 
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  
  // Services
  final ProductService _productService = ProductService();
  final OcrService _ocrService = OcrService();
  final ResultHandler _resultHandler = ResultHandler();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // State
  bool isProcessing = false;
  String? lastScannedBarcode;
  bool showSuccessAnimation = false;
  Product? detectedProduct;
  List<String> detectedAllergens = [];
  String? detectedText;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Animations
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;
  late Animation<Color?> _successColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudio();
    _initializeOCR();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    cameraController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Animația liniei de scanare (sus-jos continuu)
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    
    // Animația de puls pentru cadru
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animația de succes
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
    
    _successColorAnimation = ColorTween(
      begin: const Color(0xFF6B9B76),
      end: Colors.green,
    ).animate(_successController);
    
    // Pornește animațiile
    _scanLineController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  void _initializeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('Eroare la încărcarea sunetului: $e');
    }
  }

  void _initializeOCR() async {
    try {
      await _ocrService.initialize();
    } catch (e) {
      debugPrint('Eroare la inițializarea OCR: $e');
    }
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (isProcessing) return;
    
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode == lastScannedBarcode) return;

    setState(() {
      isProcessing = true;
      lastScannedBarcode = barcode;
      showSuccessAnimation = true;
    });
    
    HapticFeedback.mediumImpact();
    _audioPlayer.resume();
    _scanLineController.stop();
    _pulseController.stop();
    _successController.forward();
    
    try {
      debugPrint('📊 Barcode detectat: $barcode');
      
      // Oprește scannerul temporar
      await cameraController.stop();
      
      // Procesează barcode-ul cu OCR pentru ingrediente
      await _processBarcodeWithOCR(barcode);
      
    } catch (e) {
      debugPrint('❌ Eroare la procesarea barcode-ului: $e');
      _showErrorSnackBar('Eroare la procesarea produsului: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// Procesează barcode-ul și face OCR pe imaginea captată pentru ingrediente
  Future<void> _processBarcodeWithOCR(String barcode) async {
    debugPrint('📊 Procesez barcode cu OCR...');

    Product? product = await _productService.getProductByBarcode(barcode);

    // Dacă produsul nu este găsit în baza de date, încearcă OCR pe imagine
    if (product == null) {
      // Capturează imaginea curentă și fă OCR
      await _captureAndProcessImage(barcode);
      return;
    }

    // Dacă produsul există dar nu are ingrediente complete, îmbunătățește cu OCR
    if (product.ingredients.isEmpty) {
      await _captureAndProcessImage(barcode, existingProduct: product);
      return;
    }

    // Procesează produsul existent
    await _processExistingProduct(product);
  }

  /// Capturează imaginea curentă și procesează cu OCR filtrat pe limba utilizatorului
  Future<void> _captureAndProcessImage(String? barcode, {Product? existingProduct}) async {
    try {
      debugPrint('📷 Capturez imaginea pentru OCR...');
      
      // Pentru moment, folosim image picker ca alternativă
      // În viitor, poți implementa capturarea directă din MobileScanner
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (imageFile == null) {
        _showErrorSnackBar('Nu s-a putut captura imaginea');
        return;
      }

      final file = File(imageFile.path);
      
      // Extrage text folosind OCR cu filtrare pe limba utilizatorului
      final ocrResult = await _ocrService.extractTextWithLanguageFilter(file);
      
      if (!ocrResult.hasText) {
        _showErrorSnackBar('Nu s-a detectat text în imaginea capturată');
        return;
      }

      debugPrint('📝 Text OCR detectat (filtrat): ${ocrResult.text}');
      debugPrint('🌍 Limba detectată: ${ocrResult.languageDetected}');
      
      // Extrage ingredientele din textul OCR
      final ingredients = await _ocrService.extractIngredients(file);
      
      Product processedProduct;
      if (existingProduct != null) {
        // Îmbunătățește produsul existent cu ingredientele detectate
        processedProduct = existingProduct.copyWith(
          ingredients: ingredients.isNotEmpty ? ingredients.split(RegExp(r'[,;]')).map((e) => e.trim()).toList() : [],
        );
      } else {
        // Creează un produs nou cu informațiile detectate
        processedProduct = Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          detectedAllergens: [],
          barcode: barcode ?? 'unknown',
          name: 'Produs scanat',
          brand: '',
          ingredients: ingredients.isNotEmpty ? ingredients.split(RegExp(r'[,;]')).map((e) => e.trim()).toList() : [],
          allergens: [],
          imageUrl: null,
        );
      }

      await _processProduct(processedProduct, ocrResult.text);
      
    } catch (e) {
      debugPrint('❌ Eroare la procesarea imaginii: $e');
      _showErrorSnackBar('Eroare la procesarea imaginii: $e');
    }
  }

  /// Procesează un produs existent
  Future<void> _processExistingProduct(Product product) async {
    await _processProduct(product, product.ingredients.join(', '));
  }

  /// Procesează produsul și detectează alergenii
  Future<void> _processProduct(Product product, String text) async {
    // Detectează alergenii din text
    List<String> relevantAllergens = [];
    if (text.isNotEmpty) {
      final foundAllergens = _resultHandler.findAllergens(text);
      final userAllergens = _userService.currentUser?.selectedAllergens ?? [];
      relevantAllergens = foundAllergens
          .where((allergen) => userAllergens.contains(allergen))
          .toList();
    }

    setState(() {
      detectedProduct = product;
      detectedText = text;
      detectedAllergens = relevantAllergens;
    });

    // Verifică dacă produsul este sigur pentru utilizator
    final userAllergens = _userService.currentUser?.selectedAllergens ?? [];
    final isProductSafe = product.isSafeFor(userAllergens) && relevantAllergens.isEmpty;
    
    // Afișează dialog cu detaliile produsului
    _showProductDetailsDialog(product, relevantAllergens, isProductSafe);
    _showResults();
  }

  /// Buton pentru scanarea manuală a ingredientelor (fără barcode)
  void _scanIngredientsOnly() async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (imageFile == null) return;

      setState(() {
        isProcessing = true;
      });

      final file = File(imageFile.path);
      
      // Extrage text folosind OCR cu filtrare pe limba utilizatorului
      final ocrResult = await _ocrService.extractTextWithLanguageFilter(file);
      
      if (!ocrResult.hasText) {
        _showErrorSnackBar('Nu s-a detectat text în imaginea capturată');
        return;
      }

      // Afișează rezultatele OCR
      _showOCRResults(ocrResult);
      
    } catch (e) {
      _showErrorSnackBar('Eroare la scanarea ingredientelor: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// Afișează rezultatele OCR pentru scanarea doar a ingredientelor
  void _showOCRResults(OcrResult ocrResult) {
    final foundAllergens = _resultHandler.findAllergens(ocrResult.text);
    final userAllergens = _userService.currentUser?.selectedAllergens ?? [];
    final relevantAllergens = foundAllergens
        .where((allergen) => userAllergens.contains(allergen))
        .toList();
    final isTextSafe = relevantAllergens.isEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isTextSafe ? Icons.check_circle : Icons.warning,
              color: isTextSafe ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Ingrediente scanate',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTextSafe ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTextSafe ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isTextSafe ? Icons.shield_outlined : Icons.warning_amber_rounded,
                      color: isTextSafe ? Colors.green.shade700 : Colors.red.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTextSafe ? 'SIGUR PENTRU TINE' : 'ATENȚIE: ALERGENI DETECTAȚI!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isTextSafe ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Informații despre limba detectată
              if (ocrResult.languageDetected != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Limba detectată: ${_getLanguageName(ocrResult.languageDetected!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Alergeni detectați
              if (relevantAllergens.isNotEmpty) ...[
                Text(
                  '⚠️ Alergeni detectați pentru tine:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: relevantAllergens.map((allergen) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            allergen.toUpperCase(),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Text detectat
              Text(
                'Text detectat (filtrat pe limba ta):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    ocrResult.text.isNotEmpty ? ocrResult.text : 'Nu s-a detectat text în limba ta',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // Confidence score
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.analytics, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Încredere: ${(ocrResult.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Text(
              'Închide',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          if (!isTextSafe)
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                _showAllergenAdvice(relevantAllergens);
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Sfaturi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Returnează numele limbii în română
  String _getLanguageName(String languageCode) {
    final languageNames = {
      'ro': 'Română',
      'en': 'Engleză',
      'de': 'Germană',
      'fr': 'Franceză',
      'it': 'Italiană',
      'es': 'Spaniolă',
      'hu': 'Maghiară',
      'pl': 'Poloneză',
      'ru': 'Rusă',
      'tr': 'Turcă',
    };
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  void _showProductDetailsDialog(Product product, List<String> foundAllergens, bool isSafe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSafe ? Icons.check_circle : Icons.warning,
                color: isSafe ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status alergeni
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSafe ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSafe ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isSafe ? Icons.shield_outlined : Icons.warning_amber_rounded,
                        color: isSafe ? Colors.green.shade700 : Colors.red.shade700,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSafe ? 'SIGUR PENTRU TINE' : 'ATENȚIE: ALERGENI DETECTAȚI!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSafe ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Imagine produs
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nu s-a putut încărca imaginea',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Imaginea nu este disponibilă',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Informații produs
                _buildInfoSection('Brand', product.brand),
                _buildInfoSection('Cod de bare', product.barcode),
                
                // Alergeni detectați (dacă există)
                if (foundAllergens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '⚠️ Alergeni detectați pentru tine:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: foundAllergens.map((allergen) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              allergen.toUpperCase(),
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
                
                // Toți alergenii declarați
                if (product.allergens.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Alergeni declarați pe produs:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: product.allergens.map((allergen) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        allergen,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                
                // Ingrediente
                const SizedBox(height: 16),
                const Text(
                  'Ingrediente:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    product.ingredients.isNotEmpty 
                        ? product.ingredients.join(', ')
                        : 'Ingredientele nu sunt disponibile',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Text(
                'Închide',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            if (!isSafe) ...[
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  _showAllergenAdvice(foundAllergens);
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Sfaturi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.favorite_outline, size: 18),
                label: const Text('Salvează'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Helper method pentru secțiunile de info
  Widget _buildInfoSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Method pentru sfaturi despre alergeni
  void _showAllergenAdvice(List<String> allergens) {
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
            ...allergens.map((allergen) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${allergen.toUpperCase()}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            )),
            const SizedBox(height: 12),
            const Text(
              'Recomandări:\n• Evită consumul acestui produs\n• Verifică întotdeauna eticheta\n• Consultă medicul pentru informații suplimentare',
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

  void _showResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultsSheet(),
    );
  }

  Widget _buildResultsSheet() {
    final hasProduct = detectedProduct != null;
    final hasAllergens = detectedAllergens.isNotEmpty;
    final isSafe = !hasAllergens;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Status icon și titlu
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSafe ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              isSafe ? Icons.check_circle : Icons.warning,
              size: 48,
              color: isSafe ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            isSafe ? 'Sigur pentru tine!' : 'Atenție!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSafe ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          
          if (hasProduct)
            Text(
              detectedProduct!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D5A3D),
              ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: 24),
          
          // Informații despre alergeni
          if (hasAllergens) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alergeni detectați din profilul tău:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detectedAllergens.map((allergen) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          allergen.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nu au fost detectați alergenii din profilul tău în acest produs.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Acțiuni
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resumeScanning();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6B9B76)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Scanează din nou',
                    style: TextStyle(color: Color(0xFF6B9B76)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: hasProduct ? _saveToFavorites : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B9B76),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Salvează',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          
          // Debug info (doar în development)
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
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _resumeScanning() {
    setState(() {
      lastScannedBarcode = null;
      detectedProduct = null;
      detectedAllergens = [];
      detectedText = null;
      showSuccessAnimation = false;
    });
    
    // Resetează animațiile
    _successController.reset();
    _scanLineController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    
    cameraController.start();
  }

  Future<void> _saveToFavorites() async {
    if (detectedProduct == null) return;
    
    try {
      await _productService.saveToFavorites(detectedProduct!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produs salvat în favorite!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Închide și scanner-ul
      }
    } catch (e) {
      _showErrorSnackBar('Eroare la salvarea produsului: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanează Barcode'),
        backgroundColor: const Color(0xFF6B9B76),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_on),
            tooltip: 'Bliț',
          ),
          IconButton(
            onPressed: _scanIngredientsOnly,
            icon: const Icon(Icons.text_fields),
            tooltip: 'Scanează doar ingrediente',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),
          
          // Overlay cu instrucțiuni
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Îndreaptă camera către barcode-ul produsului.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Textul va fi filtrat pentru limba ta: ${_getLanguageName(_getUserLanguage())}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Scanning frame
          _buildScannerFrame(),

          // Bottom instructions
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        'Barcode',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white30,
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.text_fields, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        'Ingrediente',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obține limba utilizatorului
  String _getUserLanguage() {
    try {
      return _userService.currentUser?.preferences.language ?? 'ro';
    } catch (e) {
      return 'ro';
    }
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ScannerOverlayPainter(
            scanLinePosition: _scanLineAnimation.value,
            isScanning: !isProcessing && !showSuccessAnimation,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildScannerFrame() {
    return Center(
      child: AnimatedBuilder(
        animation: showSuccessAnimation ? _successAnimation : _pulseAnimation,
        builder: (context, child) {
          final scale = showSuccessAnimation ? 1.0 : _pulseAnimation.value;
          final color = showSuccessAnimation 
              ? _successColorAnimation.value ?? const Color(0xFF6B9B76)
              : const Color(0xFF6B9B76);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: color,
                  width: showSuccessAnimation ? 4 : 3,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha:0.3),
                    blurRadius: showSuccessAnimation ? 20 : 10,
                    spreadRadius: showSuccessAnimation ? 5 : 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Colțuri animate
                  ...List.generate(4, (index) => _buildCornerDecoration(index, color)),
                  
                  // Overlay de scanare
                  if (!showSuccessAnimation) _buildScanningOverlay(),
                  
                  // Animație de succes
                  if (showSuccessAnimation)
                    Center(
                      child: ScaleTransition(
                        scale: _successAnimation,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha:0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  
                  // Loading indicator
                  if (isProcessing && !showSuccessAnimation)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Procesez produsul...',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCornerDecoration(int index, Color color) {
    final positions = [
      const Alignment(-1, -1), // Top-left
      const Alignment(1, -1),  // Top-right  
      const Alignment(-1, 1),  // Bottom-left
      const Alignment(1, 1),   // Bottom-right
    ];

    return Align(
      alignment: positions[index],
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: index < 2 ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: index >= 2 ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: index.isEven ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: index.isOdd ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// Painter pentru overlay-ul de scanare
class ScannerOverlayPainter extends CustomPainter {
  final double scanLinePosition;
  final bool isScanning;

  ScannerOverlayPainter({
    required this.scanLinePosition,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isScanning) return;

    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF6B9B76).withValues(alpha:0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));

    // Desenează linia de scanare
    final lineY = size.height * scanLinePosition;
    canvas.drawRect(
      Rect.fromLTWH(0, lineY - 2, size.width, 4),
      gradient,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}