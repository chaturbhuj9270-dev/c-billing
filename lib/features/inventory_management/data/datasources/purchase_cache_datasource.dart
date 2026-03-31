import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/product.dart';

class PurchaseCacheDataSource {
  static const String _productsKey = 'purchase_products_cache';
  static const String _suppliersKey = 'purchase_suppliers_cache';
  static const String _companiesKey = 'purchase_companies_cache';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Products cache
  Future<void> saveProducts(List<Product> products) async {
    await init();
    final List<Map<String, dynamic>> serializableProducts = products
        .map((product) => product.toJson())
        .toList();
    final String jsonStr = jsonEncode(serializableProducts);
    await _prefs?.setString(_productsKey, jsonStr);
  }

  Future<List<Product>?> getCachedProducts() async {
    await init();
    final String? jsonStr = _prefs?.getString(_productsKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('[ERROR] Failed to deserialize cached products: $e');
      return null;
    }
  }

  // Suppliers cache
  Future<void> saveSuppliers(List<Map<String, dynamic>> suppliers) async {
    await init();
    final String jsonStr = jsonEncode(suppliers);
    await _prefs?.setString(_suppliersKey, jsonStr);
  }

  Future<List<Map<String, dynamic>>?> getCachedSuppliers() async {
    await init();
    final String? jsonStr = _prefs?.getString(_suppliersKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[ERROR] Failed to deserialize cached suppliers: $e');
      return null;
    }
  }

  // Companies cache
  Future<void> saveCompanies(List<Map<String, dynamic>> companies) async {
    await init();
    final String jsonStr = jsonEncode(companies);
    await _prefs?.setString(_companiesKey, jsonStr);
  }

  Future<List<Map<String, dynamic>>?> getCachedCompanies() async {
    await init();
    final String? jsonStr = _prefs?.getString(_companiesKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[ERROR] Failed to deserialize cached companies: $e');
      return null;
    }
  }

  Future<void> clearAll() async {
    await init();
    await _prefs?.remove(_productsKey);
    await _prefs?.remove(_suppliersKey);
    await _prefs?.remove(_companiesKey);
  }
}
