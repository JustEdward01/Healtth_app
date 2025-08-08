import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shelf_scan_models.dart';

class ProductInfo {
  final String name;
  final String brand;
  final List<String> ingredients;
  final List<String> allergens;
  final String? imageUrl;

  ProductInfo({
    required this.name,
    required this.brand,
    required this.ingredients,
    required this.allergens,
    this.imageUrl,
  });
}

class OpenFoodService {
  static const String baseUrl = 'https://world.openfoodfacts.org';

  List<String> _generateSearchQueries(String name, String? brand) {
    List<String> queries = [];
    if (brand != null && brand.isNotEmpty) {
      queries.add('$brand $name');
    }
    queries.add(name);
    final cleanName = name.replaceAll(RegExp(r'\b(zero|light|diet|bio)\b', caseSensitive: false), '').trim();
    queries.add(cleanName);
    return queries;
  }

  Future<ProductInfo?> searchProduct(String productName, String? brand) async {
    final queries = _generateSearchQueries(productName, brand);
    for (final q in queries) {
      try {
        final info = await _searchSingle(q);
        if (info != null) return info;
      } catch (e) {
        // ignoră și încearcă următorul query
      }
    }
    return null;
  }

  Future<ProductInfo?> _searchSingle(String query) async {
    final url = Uri.parse('$baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=20');
    final resp = await http.get(url).timeout(Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final products = (data['products'] as List<dynamic>? ) ?? [];
    if (products.isEmpty) return null;

    final p = products.first as Map<String, dynamic>;

    final ingredientsText = p['ingredients_text'] ?? p['ingredients_text_en'] ?? '';
    final allergensText = p['allergens'] ?? '';
    final allergensHierarchy = (p['allergens_hierarchy'] as List<dynamic>?) ?? [];

    final ingredients = _extractIngredients(ingredientsText);
    final allergens = _extractAllergens(allergensText, allergensHierarchy);

    return ProductInfo(
      name: (p['product_name'] ?? query).toString(),
      brand: (p['brands'] ?? '').toString(),
      ingredients: ingredients,
      allergens: allergens,
      imageUrl: p['image_url'],
    );
  }

  List<String> _extractIngredients(String product) {
    if (product.isEmpty) return [];
    return product.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
  }

  List<String> _extractAllergens(String allergensText, List<dynamic> hierarchy) {
    Set<String> out = {};
    if ((allergensText ?? '').isNotEmpty) {
      out.addAll(allergensText.split(',').map((e) => e.trim().toLowerCase()));
    }
    for (final h in hierarchy) {
      final s = h.toString();
      out.add(s.replaceAll(RegExp(r'^[a-z]{2}:'), '').trim().toLowerCase());
    }
    return out.toList();
  }
}
