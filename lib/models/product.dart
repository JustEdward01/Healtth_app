class Product {
  final String id;
  final String name;
  final String brand;
  final String barcode;
  final List<String> ingredients;
  final List<String> allergens;
  final List<String> detectedAllergens;
  final String? imageUrl;
  final String? description;
  final DateTime? scannedAt;
  final String? language;
  final Map<String, dynamic>? nutritionalInfo;
  final bool isVerified;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.ingredients,
    required this.allergens,
    required this.detectedAllergens,
    this.imageUrl,
    this.description,
    this.scannedAt,
    this.language,
    this.nutritionalInfo,
    this.isVerified = false,
  });

  // Factory constructor for creating Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      barcode: json['barcode'] as String,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
      detectedAllergens: List<String>.from(json['detected_allergens'] ?? []),
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      scannedAt: json['scanned_at'] != null 
          ? DateTime.parse(json['scanned_at']) 
          : null,
      language: json['language'] as String?,
      nutritionalInfo: json['nutritional_info'] as Map<String, dynamic>?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'ingredients': ingredients,
      'allergens': allergens,
      'detected_allergens': detectedAllergens,
      'image_url': imageUrl,
      'description': description,
      'scanned_at': scannedAt?.toIso8601String(),
      'language': language,
      'nutritional_info': nutritionalInfo,
      'is_verified': isVerified,
    };
  }

  // Create a copy of Product with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? barcode,
    List<String>? ingredients,
    List<String>? allergens,
    List<String>? detectedAllergens,
    String? imageUrl,
    String? description,
    DateTime? scannedAt,
    String? language,
    Map<String, dynamic>? nutritionalInfo,
    bool? isVerified,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      scannedAt: scannedAt ?? this.scannedAt,
      language: language ?? this.language,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Check if product contains specific allergen
  bool containsAllergen(String allergen) {
    return allergens.contains(allergen) || 
           detectedAllergens.contains(allergen);
  }

  // Get all unique allergens (declared + detected)
  List<String> getAllAllergens() {
    final allAllergens = <String>{};
    allAllergens.addAll(allergens);
    allAllergens.addAll(detectedAllergens);
    return allAllergens.toList();
  }

  // Check if product is safe for user with specific allergies
  bool isSafeFor(List<String> userAllergies) {
    final productAllergens = getAllAllergens();
    return !productAllergens.any((allergen) => 
        userAllergies.any((userAllergy) => 
            allergen.toLowerCase().contains(userAllergy.toLowerCase())));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product{id: $id, name: $name, brand: $brand, allergens: $allergens}';
  }
}

// Enum for common allergen types
enum AllergenType {
  gluten,
  milk,
  eggs,
  nuts,
  peanuts,
  soy,
  fish,
  shellfish,
  sesame,
  mustard,
  celery,
  lupin,
  sulfites,
  molluscs,
}

// Extension to convert AllergenType to string
extension AllergenTypeExtension on AllergenType {
  String get displayName {
    switch (this) {
      case AllergenType.gluten:
        return 'Gluten';
      case AllergenType.milk:
        return 'Milk/Dairy';
      case AllergenType.eggs:
        return 'Eggs';
      case AllergenType.nuts:
        return 'Tree Nuts';
      case AllergenType.peanuts:
        return 'Peanuts';
      case AllergenType.soy:
        return 'Soy';
      case AllergenType.fish:
        return 'Fish';
      case AllergenType.shellfish:
        return 'Shellfish';
      case AllergenType.sesame:
        return 'Sesame';
      case AllergenType.mustard:
        return 'Mustard';
      case AllergenType.celery:
        return 'Celery';
      case AllergenType.lupin:
        return 'Lupin';
      case AllergenType.sulfites:
        return 'Sulfites';
      case AllergenType.molluscs:
        return 'Molluscs';
    }
  }

  String get value {
    return name;
  }
}