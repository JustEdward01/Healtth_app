// lib/widgets/visual_allergen_overlay.dart

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

/// Widget pentru afișarea overlay-ului cu alergeni pe imagine
class VisualAllergenOverlay extends StatefulWidget {
  final File imageFile;
  final List<AllergenMatchWithPosition> allergenMatches;
  final bool showOverlay;
  final VoidCallback? onClose;

  const VisualAllergenOverlay({
    super.key,
    required this.imageFile,
    required this.allergenMatches,
    this.showOverlay = true,
    this.onClose,
  });

  @override
  State<VisualAllergenOverlay> createState() => _VisualAllergenOverlayState();
}

class _VisualAllergenOverlayState extends State<VisualAllergenOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Imaginea de fundal
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 3.0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    // Imaginea principală
                    Positioned.fill(
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    // Overlay-urile pentru alergeni
                    if (widget.showOverlay)
                      ...widget.allergenMatches.asMap().entries.map((entry) {
                        final index = entry.key;
                        final match = entry.value;
                        return _buildAllergenHighlight(match, index);
                      }),
                  ],
                ),
              ),
            ),
          ),

          // Header cu informații
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.allergenMatches.isNotEmpty
                        ? Icons.warning_amber
                        : Icons.check_circle,
                    color: widget.allergenMatches.isNotEmpty
                        ? Colors.red
                        : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.allergenMatches.isNotEmpty
                              ? '⚠️ ${widget.allergenMatches.length} Alergen${widget.allergenMatches.length > 1 ? 'i' : ''} Detectat${widget.allergenMatches.length > 1 ? 'i' : ''}'
                              : '✅ Nu s-au găsit alergeni',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.allergenMatches.isNotEmpty)
                          Text(
                            widget.allergenMatches
                                .map((m) => m.allergen.toUpperCase())
                                .join(', '),
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Lista detaliată jos
          if (widget.allergenMatches.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.allergenMatches.length,
                        itemBuilder: (context, index) {
                          final match = widget.allergenMatches[index];
                          return _buildAllergenListItem(match, index);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

          // Instrucțiuni de utilizare
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 20),
                  SizedBox(height: 4),
                  Text(
                    'Zoom\npentru\ndetalii',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construiește highlight-ul pentru un alergen
  Widget _buildAllergenHighlight(AllergenMatchWithPosition match, int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.deepOrange,
      Colors.pink,
      Colors.purple,
    ];
    
    final color = colors[index % colors.length];

    return Positioned(
      left: match.boundingBox.left,
      top: match.boundingBox.top,
      width: match.boundingBox.width,
      height: match.boundingBox.height,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: color,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(6),
                color: color.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Label cu numele alergenului
                  Positioned(
                    top: -25,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        match.allergen.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Iconița de warning
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 14,
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

  /// Construiește un item din lista de alergeni
  Widget _buildAllergenListItem(AllergenMatchWithPosition match, int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.deepOrange,
      Colors.pink,
      Colors.purple,
    ];
    
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.allergen.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Găsit: "${match.foundTerm}"',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(match.confidence * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Model pentru alergen cu poziție pe imagine
class AllergenMatchWithPosition {
  final String allergen;
  final String foundTerm;
  final double confidence;
  final Rect boundingBox;

  AllergenMatchWithPosition({
    required this.allergen,
    required this.foundTerm,
    required this.confidence,
    required this.boundingBox,
  });
}

/// Service pentru detectarea pozițiilor alergenilor pe imagine
class AllergenPositionDetector {
  /// Detectează pozițiile alergenilor pe imagine folosind OCR
  static Future<List<AllergenMatchWithPosition>> detectAllergenPositions({
    required File imageFile,
    required List<String> detectedAllergens,
  }) async {
    final List<AllergenMatchWithPosition> positionedAllergens = [];
    
    try {
      // Inițializează OCR
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      // Pentru fiecare alergen detectat, găsește pozițiile pe imagine
      for (final allergen in detectedAllergens) {
        final positions = _findAllergenInText(recognizedText, allergen);
        positionedAllergens.addAll(positions);
      }
      
      await textRecognizer.close();
      
    } catch (e) {
      debugPrint('Eroare la detectarea pozițiilor: $e');
    }
    
    return positionedAllergens;
  }
  
  /// Găsește toate aparițiile unui alergen în textul OCR
  static List<AllergenMatchWithPosition> _findAllergenInText(
    RecognizedText recognizedText, 
    String targetAllergen,
  ) {
    final List<AllergenMatchWithPosition> matches = [];
    
    // Pattern-uri pentru fiecare tip de alergen (simplificat)
    final patterns = {
      'lapte': [r'lapte', r'milk', r'lactoz', r'lactos', r'smantana', r'unt', r'branza'],
      'oua': [r'ou[aă]?', r'egg[s]?', r'galben', r'albu[șs]'],
      'grau': [r'gr[aă]u', r'wheat', r'f[aă]in[aă]', r'flour', r'gluten'],
      'soia': [r'soia', r'soy', r'lecitina'],
      'nuci': [r'nuci', r'nuts?', r'alune', r'migdale'],
      'peste': [r'pe[șs]te', r'fish', r'ton', r'somon'],
    };
    
    final allergenPatterns = patterns[targetAllergen] ?? [targetAllergen];
    
    // Caută în fiecare bloc de text
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.toLowerCase();
        
        for (final pattern in allergenPatterns) {
          final regex = RegExp(pattern, caseSensitive: false);
          final match = regex.firstMatch(lineText);
          
          if (match != null) {
            // Calculează poziția relativă în linie
            final matchStart = match.start;
            final matchEnd = match.end;
            final lineLength = lineText.length;
            
            if (lineLength > 0) {
              // Estimează poziția pe baza proporției în linie
              final startRatio = matchStart / lineLength;
              final endRatio = matchEnd / lineLength;
              
              final lineRect = line.boundingBox;
              final matchLeft = lineRect.left + (lineRect.width * startRatio);
              final matchWidth = lineRect.width * (endRatio - startRatio);
              
              matches.add(AllergenMatchWithPosition(
                allergen: targetAllergen,
                foundTerm: match.group(0) ?? pattern,
                confidence: 0.85, // Confidence estimat
                boundingBox: Rect.fromLTWH(
                  matchLeft,
                  lineRect.top,
                  matchWidth.clamp(50.0, lineRect.width),
                  lineRect.height,
                ),
              ));
            }
          }
        }
      }
    }
    
    return matches;
  }
}