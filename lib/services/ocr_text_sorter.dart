// ocr_text_sorter.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrTextSorter {
  /// Sortează blocurile de text de la stânga la dreapta, de sus în jos.
  String sortAndFormatText(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return '';
    }

    final List<TextBlock> blocks = recognizedText.blocks;
    
    // Sortează toate blocurile inițial de sus în jos
    blocks.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final List<List<TextBlock>> lines = [];
    if (blocks.isNotEmpty) {
      // Primul bloc este întotdeauna pe prima linie
      List<TextBlock> currentLine = [blocks.first];
      lines.add(currentLine);

      for (int i = 1; i < blocks.length; i++) {
        final currentBlock = blocks[i];
        final previousBlock = blocks[i-1];
        
        // Verificăm dacă blocurile sunt pe aceeași linie, comparând coordonatele Y
        // Un prag mic (e.g., 20) este necesar pentru a ține cont de mici variații
        if ((currentBlock.boundingBox.top - previousBlock.boundingBox.top).abs() < 20) {
          // Dacă este pe aceeași linie, adaugă la linia curentă
          currentLine.add(currentBlock);
        } else {
          // Altfel, pornim o linie nouă
          currentLine = [currentBlock];
          lines.add(currentLine);
        }
      }
    }
    
    // Sortează fiecare linie de la stânga la dreapta
    for (var line in lines) {
      line.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    }

    // Reconstruim textul final
    final StringBuffer sortedTextBuffer = StringBuffer();
    for (final line in lines) {
      sortedTextBuffer.writeln(line.map((block) => block.text).join(' '));
    }

    return sortedTextBuffer.toString().trim();
  }
}