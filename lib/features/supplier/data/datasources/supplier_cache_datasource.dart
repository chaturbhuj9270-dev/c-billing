import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierCacheDataSource {
  static const String _cacheKey = 'supplier_list_cache';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveSuppliers(List<Map<String, dynamic>> suppliers) async {
    await init();
    
    // Deep copy and convert Timestamps to Strings for JSON
    final serializableSuppliers = suppliers.map((supplier) {
      final map = Map<String, dynamic>.from(supplier);
      map.forEach((key, value) {
        if (value is Timestamp) {
          map[key] = value.toDate().toIso8601String();
        } else if (value is FieldValue) {
          map[key] = DateTime.now().toIso8601String();
        }
      });
      return map;
    }).toList();

    final String jsonStr = jsonEncode(serializableSuppliers);
    await _prefs?.setString(_cacheKey, jsonStr);
  }

  Future<List<Map<String, dynamic>>?> getCachedSuppliers() async {
    await init();
    final String? jsonStr = _prefs?.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('[ERROR] Failed to deserialize cached suppliers: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    await init();
    await _prefs?.remove(_cacheKey);
  }
}
