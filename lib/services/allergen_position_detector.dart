import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../modules/ocr_tolerant_result_handler.dart';
import '../widgets/visual_allergen_overlay.dart';

/// Service îmbunătățit pentru detectarea precisă a pozițiilor alergenilor
class AllergenPositionDetector {
  
  /// Detectează pozițiile exacte ale alergenilor pe imagine
  static Future<List<AllergenMatchWithPosition>> detectAllergenPositions({
    required File imageFile,
    required List<String> detectedAllergens,
  }) async {
    final List<AllergenMatchWithPosition> positionedAllergens = [];
    
    if (detectedAllergens.isEmpty) {
      debugPrint('🔍 Nu sunt alergeni de căutat');
      return positionedAllergens;
    }
    
    try {
      debugPrint('🔍 Caut pozițiile pentru: $detectedAllergens');
      
      // Inițializează OCR
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      debugPrint('📝 Text OCR găsit: ${recognizedText.text}');
      debugPrint('📊 Blocuri OCR: ${recognizedText.blocks.length}');
      
      // Pentru fiecare alergen detectat, găsește toate pozițiile
      for (final allergen in detectedAllergens) {
        final positions = await _findAllergenInOCRText(
          recognizedText, 
          allergen,
          imageFile,
        );
        
        debugPrint('📍 Pentru $allergen găsite ${positions.length} poziții');
        positionedAllergens.addAll(positions);
      }
      
      await textRecognizer.close();
      debugPrint('✅ Total poziții găsite: ${positionedAllergens.length}');
      
    } catch (e) {
      debugPrint('❌ Eroare la detectarea pozițiilor: $e');
    }
    
    return positionedAllergens;
  }
  
  /// Găsește toate aparițiile unui alergen în textul OCR cu toleranță la erori
  static Future<List<AllergenMatchWithPosition>> _findAllergenInOCRText(
    RecognizedText recognizedText, 
    String targetAllergen,
    File imageFile,
  ) async {
    final List<AllergenMatchWithPosition> matches = [];
    
    // Pattern-uri specifice pentru fiecare alergen cu toleranță OCR
    final allergenPatterns = _getOCRTolerantPatterns(targetAllergen);
    
    debugPrint('🔎 Caut $targetAllergen cu ${allergenPatterns.length} pattern-uri');
    
    // Caută în fiecare bloc și linie de text
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.toLowerCase();
        debugPrint('📄 Verific linia: "$lineText"');
        
        // Testează fiecare pattern pentru alergenul curent
        for (final pattern in allergenPatterns) {
          final regex = RegExp(pattern, caseSensitive: false);
          final regexMatches = regex.allMatches(lineText);
          
          for (final match in regexMatches) {
            final foundTerm = match.group(0) ?? '';
            debugPrint('✅ GĂSIT: "$foundTerm" pentru $targetAllergen în "$lineText"');
            
            // Calculează poziția exactă în linie
            final boundingBox = _calculateWordPosition(line, match, lineText);
            
            if (boundingBox != null) {
              matches.add(AllergenMatchWithPosition(
                allergen: targetAllergen,
                foundTerm: foundTerm,
                confidence: 0.9, // Confidence înalt pentru că a fost deja detectat
                boundingBox: boundingBox,
              ));
              
              debugPrint('📍 Poziție: ${boundingBox.toString()}');
            }
          }
        }
      }
    }
    
    return matches;
  }
  
  /// Obține pattern-uri tolerante la erori OCR pentru alergen specific
  static List<String> _getOCRTolerantPatterns(String allergen) {
    final patterns = <String>[];
    
    switch (allergen.toLowerCase()) {
      case 'lapte':
        patterns.addAll([
          r'\b(l[aă@4]*[pt]*[pt]*[eë3ê]*)\b',           // lapte, lnpte, etc.
          r'\b(m[il1|]*[il1|]*k)\b',                    // milk, miik, etc.
          r'\b(l[aă@4]*ct[o0ö]*[sz5]*[aă@4]*)\b',       // lactoza, lactosa
          r'\b(d[aă@4]*[il1|]*ry)\b',                   // dairy, daity
          r'\b(sm[aă@4]*nt[aă@4]*n[aă@4]*)\b',          // smântână
          r'\b(cr[eë3ê]*[aă@4]*m)\b',                   // cream, creem
          r'\b(ch[eë3ê]*[eë3ê]*s[eë3ê]*)\b',           // cheese, cheise
          r'\b(unt|butt[eë3ê]*r)\b',                    // unt, butter
          r'\b(br[aă@4]*nz[aă@4]*)\b',                  // brânză, branza
        ]);
        break;
        
      case 'oua':
        patterns.addAll([
          r'\b([oö0]*[uüú]*[aă@4ä]*)\b',                // ouă, oua, oun
          r'\b([oö0]*[uüú]*[nli]*)\b',                  // ou, oun, oui
          r'\b([eë3ê]*[gq]*[gq]*[s5]*?)\b',             // eggs, eqqs, eqg
          r'\b([eë3ê]*[gq]*[gq]*)\b',                   // egg, eqg
          r'\b([gq]*[aă@4]*lb[eë3ê]*nu[șs]*)\b',        // gălbenuș
          r'\b([aă@4]*lbu[șs]*)\b',                     // albuș
          r'\b(y[oö0]*lk)\b',                           // yolk
          r'\b([eë3ê]*[il1|]*[eë3ê]*r)\b',              // eier (germană)
          r'\b([œoö0]*[eë3ê]*uf[s5]*?)\b',              // œufs (franceză)
        ]);
        break;
        
      case 'grau':
        patterns.addAll([
          r'\b([gq]*r[aă@4â]*[uw]*)\b',                 // grâu, grau, qrau
          r'\b(f[aă@4ä]*[il1|]*n[aă@4ä]*)\b',          // făină, fiina, faina
          r'\b([gq]*lut[eë3ê]*n)\b',                    // gluten, qluten
          r'\b(wh[eë3ê]*[aă@4]*t)\b',                   // wheat, whiat
          r'\b(fl[oö0]*[uwr]*)\b',                      // flour, flowr
          r'\b([aă@4]*m[il1|]*d[oö0]*n)\b',             // amidon, imidon
          r'\b(w[eë3ê]*[il1|]*z[eë3ê]*n)\b',           // weizen (germană)
          r'\b(bl[eë3ê]*)\b',                           // blé (franceză)
        ]);
        break;
        
      case 'soia':
        patterns.addAll([
          r'\b([șs]*[oö0]*[il1|]*[aă@4]*)\b',           // soia, soyia
          r'\b([șs]*[oö0]*y[aă@4]*)\b',                 // soy, soya
          r'\b(l[eë3ê]*c[il1|]*t[il1|]*n[aă@4]*)\b',    // lecitină, licitina
          r'\b(t[oö0]*fu)\b',                           // tofu
        ]);
        break;
        
      case 'nuci':
        patterns.addAll([
          r'\b(nuc[il1|]*)\b',                          // nuci, nuci
          r'\b(nut[s5]*?)\b',                           // nuts, nut5
          r'\b([aă@4]*lun[eë3ê]*)\b',                   // alune, ilune
          r'\b(m[il1|]*[gq]*d[aă@4]*l[eë3ê]*)\b',       // migdale, miqdile
          r'\b([aă@4]*lm[oö0]*nd[s5]*?)\b',             // almonds, ilmonds
          r'\b(h[aă@4]*z[eë3ê]*lnut[s5]*?)\b',          // hazelnuts
          r'\b(w[aă@4]*lnut[s5]*?)\b',                  // walnuts
        ]);
        break;
        
      case 'peste':
        patterns.addAll([
          r'\b(p[eë3ê]*[șs]*t[eë3ê]*)\b',               // pește, piste
          r'\b(f[il1|]*[șs]*h)\b',                      // fish, filsh
          r'\b(t[oö0]*n[aă@4]*)\b',                     // ton, tuna
          r'\b([șs]*[aă@4]*lm[oö0]*n)\b',               // somon, salmon
        ]);
        break;
        
      case 'orz':
        patterns.addAll([
          r'\b([oö0]*rz)\b',                            // orz
          r'\b(b[aă@4]*rl[eë3ê]*y)\b',                  // barley, birley
          r'\b(m[aă@4]*lt[aă@4]*)\b',                   // malta, malt
          r'\b([gq]*[eë3ê]*rst[eë3ê]*)\b',             // gerste (germană)
          r'\b([oö0]*r[gq]*[eë3ê]*)\b',                 // orge (franceză)
        ]);
        break;
        
      default:
        // Pattern generic pentru alergeni necunoscuți
        patterns.add(r'\b(' + RegExp.escape(allergen) + r')\b');
        break;
    }
    
    return patterns;
  }
  
  /// Calculează poziția exactă a unui cuvânt într-o linie OCR
  static Rect? _calculateWordPosition(TextLine line, RegExpMatch match, String lineText) {
    if (lineText.isEmpty) return null;
    
    final matchStart = match.start;
    final matchEnd = match.end;
    final matchLength = matchEnd - matchStart;
    
    // Calculează proporția în linie
    final startRatio = matchStart / lineText.length;
    final lengthRatio = matchLength / lineText.length;
    
    final lineRect = line.boundingBox;
    
    // Calculează poziția exactă
    final matchLeft = lineRect.left + (lineRect.width * startRatio);
    final matchWidth = (lineRect.width * lengthRatio).clamp(30.0, lineRect.width);
    
    // Adaugă un padding pentru vizibilitate mai bună
    final padding = 8.0;
    
    return Rect.fromLTWH(
      (matchLeft - padding).clamp(0.0, double.infinity),
      (lineRect.top - padding).clamp(0.0, double.infinity),
      matchWidth + (padding * 2),
      lineRect.height + (padding * 2),
    );
  }
}

/// Extension pentru debugging mai ușor
extension AllergenMatchDebug on AllergenMatchWithPosition {
  void printDebugInfo() {
    debugPrint('🏷️ Alergen: $allergen');
    debugPrint('🔤 Termen găsit: "$foundTerm"');
    debugPrint('📊 Confidence: ${(confidence * 100).toInt()}%');
    debugPrint('📍 Poziție: (${boundingBox.left.toInt()}, ${boundingBox.top.toInt()}) - ${boundingBox.width.toInt()}x${boundingBox.height.toInt()}');
  }
}