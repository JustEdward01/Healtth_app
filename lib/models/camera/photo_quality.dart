import 'package:flutter/material.dart';

enum PhotoQuality {
  PERFECT,    // Verde - scanează acum!
  GOOD,       // Verde deschis - bună calitate
  POOR,       // Portocaliu - apropie camera  
  TERRIBLE,   // Roșu - repoziționează
  SEARCHING,  // Albastru - caută ingrediente
}

extension PhotoQualityExtension on PhotoQuality {
  Color get color {
    switch (this) {
      case PhotoQuality.PERFECT: return Colors.green;
      case PhotoQuality.GOOD: return Colors.lightGreen;
      case PhotoQuality.POOR: return Colors.orange;
      case PhotoQuality.TERRIBLE: return Colors.red;
      case PhotoQuality.SEARCHING: return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case PhotoQuality.PERFECT: return Icons.check_circle;
      case PhotoQuality.GOOD: return Icons.check;
      case PhotoQuality.POOR: return Icons.zoom_in;
      case PhotoQuality.TERRIBLE: return Icons.warning;
      case PhotoQuality.SEARCHING: return Icons.search;
    }
  }

  String get title {
    switch (this) {
      case PhotoQuality.PERFECT: return 'PERFECT';
      case PhotoQuality.GOOD: return 'BUNĂ CALITATE';
      case PhotoQuality.POOR: return 'APROPIE CAMERA';
      case PhotoQuality.TERRIBLE: return 'REPOZIȚIONEAZĂ';
      case PhotoQuality.SEARCHING: return 'CAUT INGREDIENTE';
    }
  }

  String get message {
    switch (this) {
      case PhotoQuality.PERFECT: return '✅ Perfect! Apasă pentru scanare';
      case PhotoQuality.GOOD: return '👍 Bună calitate - poți scana';
      case PhotoQuality.POOR: return '📏 Apropie camera pentru mai multă claritate';
      case PhotoQuality.TERRIBLE: return '❌ Repoziționează camera spre ingrediente';
      case PhotoQuality.SEARCHING: return '🔍 Caut ingredientele în imagine...';
    }
  }
}