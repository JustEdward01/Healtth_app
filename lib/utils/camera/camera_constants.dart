class CameraConstants {
  // Detection intervals
  static const Duration liveDetectionInterval = Duration(milliseconds: 800);
  static const Duration multiFrameDelay = Duration(milliseconds: 300);
  
  // Quality thresholds
  static const double perfectThreshold = 0.8;
  static const double goodThreshold = 0.6;
  static const double poorThreshold = 0.3;
  
  // UI Constants
  static const double cornerIndicatorSize = 20.0;
  static const double borderWidth = 3.0;
  static const double overlayPadding = 20.0;
  
  // Camera settings
  static const double defaultZoom = 1.0;
  static const double maxZoom = 4.0;
  static const double minZoom = 1.0;
  
  // Ingredient keywords in multiple languages
  static const Map<String, List<String>> ingredientKeywords = {
    'ro': [
      'ingredient', 'faina', 'lapte', 'zahar', 'ulei', 'sare',
      'unt', 'oua', 'drojdie', 'bicarbonat', 'vanilie', 'cacao'
    ],
    'en': [
      'ingredients', 'flour', 'milk', 'sugar', 'oil', 'salt',
      'butter', 'eggs', 'yeast', 'baking soda', 'vanilla', 'cocoa'
    ],
    'de': [
      'zutaten', 'mehl', 'milch', 'zucker', 'öl', 'salz',
      'butter', 'eier', 'hefe', 'backpulver', 'vanille', 'kakao'
    ],
    'fr': [
      'ingrédients', 'farine', 'lait', 'sucre', 'huile', 'sel',
      'beurre', 'oeufs', 'levure', 'bicarbonate', 'vanille', 'cacao'
    ],
  };
  
  static const List<String> headerKeywords = [
    'ingrediente', 'ingredients', 'zutaten', 'ingrédients',
    'contine', 'contains', 'enthält', 'contient',
    'compozitie', 'composition', 'zusammensetzung'
  ];
}
