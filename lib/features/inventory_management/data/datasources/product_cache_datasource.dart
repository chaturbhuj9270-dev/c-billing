import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../inventory_management/domain/entities/product.dart';

class ProductCacheDataSource {
  static const String _cacheKey = 'product_list_cache';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveProducts(List<Product> products) async {
    await init();
    
    final List<Map<String, dynamic>> serializableProducts = products
        .map((product) => product.toJson())
        .toList();

    final String jsonStr = jsonEncode(serializableProducts);
    await _prefs?.setString(_cacheKey, jsonStr);
  }

  Future<List<Product>?> getCachedProducts() async {
    await init();
    final String? jsonStr = _prefs?.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('[ERROR] Failed to deserialize cached products: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    await init();
    await _prefs?.remove(_cacheKey);
  }
}
