import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyCacheDataSource {
  static const String _companiesKey = 'company_list_cache';
  static const String _suppliersKey = 'company_suppliers_cache';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Companies cache
  Future<void> saveCompanies(List<Map<String, dynamic>> companies) async {
    await init();
    
    // Deep copy and convert Timestamps to Strings for JSON
    final serializableCompanies = companies.map((company) {
      final map = Map<String, dynamic>.from(company);
      map.forEach((key, value) {
        if (value is Timestamp) {
          map[key] = value.toDate().toIso8601String();
        } else if (value is FieldValue) {
          map[key] = DateTime.now().toIso8601String();
        }
      });
      return map;
    }).toList();

    final String jsonStr = jsonEncode(serializableCompanies);
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

  // Suppliers cache
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

  Future<void> clearAll() async {
    await init();
    await _prefs?.remove(_companiesKey);
    await _prefs?.remove(_suppliersKey);
  }
}
