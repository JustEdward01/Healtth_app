import 'package:flutter/material.dart';

enum PhotoQuality {
  perfect,    // Verde - scanează acum!
  good,       // Verde deschis - bună calitate
  poor,       // Portocaliu - apropie camera  
  terrible,   // Roșu - repoziționează
  searching,  // Albastru - caută ingrediente
}

extension PhotoQualityExtension on PhotoQuality {
  Color get color {
    switch (this) {
      case PhotoQuality.perfect: return Colors.green;
      case PhotoQuality.good: return Colors.lightGreen;
      case PhotoQuality.poor: return Colors.orange;
      case PhotoQuality.terrible: return Colors.red;
      case PhotoQuality.searching: return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case PhotoQuality.perfect: return Icons.check_circle;
      case PhotoQuality.good: return Icons.check;
      case PhotoQuality.poor: return Icons.zoom_in;
      case PhotoQuality.terrible: return Icons.warning;
      case PhotoQuality.searching: return Icons.search;
    }
  }

  String get title {
    switch (this) {
      case PhotoQuality.perfect: return 'PERFECT';
      case PhotoQuality.good: return 'BUNĂ CALITATE';
      case PhotoQuality.poor: return 'APROPIE CAMERA';
      case PhotoQuality.terrible: return 'REPOZIȚIONEAZĂ';
      case PhotoQuality.searching: return 'CAUT INGREDIENTE';
    }
  }

  String get message {
    switch (this) {
      case PhotoQuality.perfect: return '✅ Perfect! Apasă pentru scanare';
      case PhotoQuality.good: return '👍 Bună calitate - poți scana';
      case PhotoQuality.poor: return '📏 Apropie camera pentru mai multă claritate';
      case PhotoQuality.terrible: return '❌ Repoziționează camera spre ingrediente';
      case PhotoQuality.searching: return '🔍 Caut ingredientele în imagine...';
    }
  }
}