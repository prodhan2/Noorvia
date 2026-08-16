import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/local/local_store.dart';

class FoodProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String ingredients;
  final List<String> allergens;
  final List<String> labels;
  final String? nutriScore;
  final List<String> concernMatches;

  const FoodProduct({
    required this.barcode,
    required this.name,
    required this.ingredients,
    this.brand,
    this.imageUrl,
    this.allergens = const [],
    this.labels = const [],
    this.nutriScore,
    this.concernMatches = const [],
  });

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
        'allergens': allergens,
        'labels': labels,
        'nutriScore': nutriScore,
        'concernMatches': concernMatches,
      };

  factory FoodProduct.fromJson(Map<String, dynamic> json) => FoodProduct(
        barcode: json['barcode']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        brand: json['brand']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
        ingredients: json['ingredients']?.toString() ?? '',
        allergens: (json['allergens'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        nutriScore: json['nutriScore']?.toString(),
        concernMatches: (json['concernMatches'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class OpenFoodFactsService {
  static const _ns = 'open_food_facts';
  static const _base = 'https://world.openfoodfacts.org';

  // This is intentionally a cautious ingredient flagger, not a halal verdict.
  static const Map<String, List<String>> _concernPatterns = {
    'Alcohol / ethanol': ['alcohol', 'ethanol', 'ethyl alcohol', 'wine', 'beer', 'rum', 'brandy', 'liqueur'],
    'Gelatin': ['gelatin', 'gelatine', 'gélatine', 'gelatina'],
    'Pork / porcine': ['pork', 'porcine', 'lard', 'pig fat', 'bacon'],
    'Carmine / E120': ['carmine', 'cochineal', 'e120', 'e 120'],
    'Animal-derived emulsifier may need source check': ['e471', 'e 471', 'mono- and diglycerides', 'mono and diglycerides'],
    'Animal-derived stearate may need source check': ['magnesium stearate', 'stearic acid'],
  };

  Future<FoodProduct> lookup(String rawBarcode, {bool forceRefresh = false}) async {
    final barcode = rawBarcode.replaceAll(RegExp(r'\D'), '');
    if (barcode.length < 8) throw Exception('Invalid barcode');

    if (!forceRefresh) {
      final cached = await LocalStore.instance.getJson(_ns, barcode);
      if (cached != null) return FoodProduct.fromJson(cached);
    }

    final fields = [
      'code', 'product_name', 'product_name_en', 'brands', 'image_front_url',
      'ingredients_text', 'ingredients_text_en', 'allergens_tags', 'labels_tags',
      'nutrition_grades', 'ingredients_analysis_tags'
    ].join(',');
    final uri = Uri.parse('$_base/api/v2/product/$barcode').replace(queryParameters: {'fields': fields});
    final response = await http.get(uri, headers: const {
      'Accept': 'application/json',
      'User-Agent': 'Noorvia/1.0 (Islamic companion; product ingredient lookup)',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Open Food Facts unavailable');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['status'] != 1 || decoded['product'] is! Map) {
      throw Exception('Product not found');
    }
    final p = Map<String, dynamic>.from(decoded['product']);
    final ingredients = (p['ingredients_text'] ?? p['ingredients_text_en'] ?? '').toString().trim();
    final lower = ingredients.toLowerCase();
    final concerns = <String>[];
    _concernPatterns.forEach((label, patterns) {
      if (patterns.any(lower.contains)) concerns.add(label);
    });

    final result = FoodProduct(
      barcode: barcode,
      name: (p['product_name'] ?? p['product_name_en'] ?? 'Unknown product').toString(),
      brand: p['brands']?.toString(),
      imageUrl: p['image_front_url']?.toString(),
      ingredients: ingredients,
      allergens: (p['allergens_tags'] as List?)?.map((e) => e.toString().replaceFirst('en:', '')).toList() ?? const [],
      labels: (p['labels_tags'] as List?)?.map((e) => e.toString().replaceFirst('en:', '')).toList() ?? const [],
      nutriScore: p['nutrition_grades']?.toString().toUpperCase(),
      concernMatches: concerns,
    );
    await LocalStore.instance.putJson(_ns, barcode, result.toJson());
    return result;
  }
}
