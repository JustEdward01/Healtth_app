import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../modules/ocr_service.dart';

class ProductService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const String _searchBase = 'https://world.openfoodfacts.org/cgi/search.pl';

  final OcrService _ocrService = OcrService();

  /// Caută produs după barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      debugPrint('🔍 Caut produs pentru barcode: $barcode');

      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final productData = data['product'];

          // Fallback la OCR dacă lipsesc ingredientele
          String ingredients = _extractIngredients(productData);
          final imageUrl = _extractImageUrl(productData);
          if (ingredients.isEmpty && imageUrl != null) {
            debugPrint('⚠️ Fallback OCR pe imagine: $imageUrl');
            ingredients = await _ocrFromImageUrl(imageUrl);
          }

          return Product(
  id: barcode, // sau generateId() dacă ai o funcție pentru asta
  barcode: barcode,
  name: _extractProductName(productData),
  brand: _extractBrand(productData),
  allergens: _extractAllergens(productData),
  detectedAllergens: [], // Lista goală inițial, va fi populată de ML model
  ingredients: ingredients.split(', '), // Convertește String la List<String>
  imageUrl: imageUrl,
  description: null, // sau o descriere dacă o ai
  scannedAt: DateTime.now(), // în loc de lastScanned
  language: null, // sau detectează limba
  nutritionalInfo: null, // dacă nu ai info nutriționale
  isVerified: false,
);
        }
      }

      debugPrint('❌ Produs nu a fost găsit pentru barcode: $barcode');
      return null;

    } catch (e) {
      debugPrint('❌ Eroare la obținerea produsului: $e');
      return null;
    }
  }

  /// Fallback căutare după nume (ex: "Monster Energy")
  Future<List<Product>> searchProductByName(String query) async {
    try {
      final url = Uri.parse(
          '$_searchBase?search_terms=$query&search_simple=1&action=process&json=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsRaw = data['products'];

        return productsRaw.map<Product>((productData) {
  return Product(
    id: productData['code'] ?? '',
    barcode: productData['code'] ?? '',
    name: _extractProductName(productData),
    brand: _extractBrand(productData),
    allergens: _extractAllergens(productData),
    detectedAllergens: [],
    ingredients: _extractIngredients(productData).split(', '),
    imageUrl: _extractImageUrl(productData),
    description: null,
    scannedAt: DateTime.now(),
    language: null,
    nutritionalInfo: null,
    isVerified: false,
  );
}).toList();
      }
    } catch (e) {
      debugPrint('❌ Eroare la căutare după nume: $e');
    }

    return [];
  }

  Future<String> _ocrFromImageUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_ocr.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return await _ocrService.extractText(file);
    } catch (e) {
      debugPrint('❌ OCR failed: $e');
      return '';
    }
  }

  String _extractProductName(Map<String, dynamic> productData) {
    return productData['product_name'] ??
        productData['product_name_en'] ??
        productData['product_name_ro'] ??
        productData['generic_name'] ??
        'Produs necunoscut';
  }

  List<String> _extractAllergens(Map<String, dynamic> productData) {
    final allergens = <String>[];

    if (productData['allergens_tags'] != null) {
      final allergenTags = List<String>.from(productData['allergens_tags']);
      for (final tag in allergenTags) {
        final cleanTag = tag.replaceAll('en:', '').replaceAll('-', ' ');
        allergens.add(cleanTag);
      }
    }

    if (productData['allergens'] != null) {
      final allergenText = productData['allergens'].toString().toLowerCase();
      final knownAllergens = [
        'milk', 'eggs', 'fish', 'shellfish', 'tree nuts', 'peanuts',
        'wheat', 'soybeans', 'sesame', 'celery', 'mustard', 'sulphites'
      ];

      for (final allergen in knownAllergens) {
        if (allergenText.contains(allergen)) {
          allergens.add(allergen);
        }
      }
    }

    return allergens.toSet().toList(); // Elimină duplicate
  }

  String? _extractImageUrl(Map<String, dynamic> productData) {
    return productData['image_url'] ??
        productData['image_front_url'] ??
        productData['image_small_url'];
  }

  String _extractIngredients(Map<String, dynamic> productData) {
    return productData['ingredients_text'] ??
        productData['ingredients_text_en'] ??
        productData['ingredients_text_ro'] ??
        '';
  }

  String _extractBrand(Map<String, dynamic> productData) {
    return productData['brands'] ??
        productData['brand_owner'] ??
        '';
  }

 

  /// Salvează produs în favorite (local storage)
  Future<void> saveToFavorites(Product product) async {
    // TODO: Implementare cu SharedPreferences / Hive
    debugPrint('💾 Salvez în favorite: ${product.name}');
  }

  Future<List<Product>> getFavoriteProducts() async {
    debugPrint('📋 Obțin produse favorite...');
    return [];
  }

  Future<bool> isProductFavorite(String barcode) async {
    return false;
  }

  Future<void> toggleFavorite(Product product) async {
    debugPrint('⭐ Toggle favorite pentru: ${product.name}');
  }
}
