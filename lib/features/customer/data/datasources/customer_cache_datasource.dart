import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerCacheDataSource {
  static const String _cacheKey = 'customer_list_cache';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveCustomers(List<Map<String, dynamic>> customers) async {
    await init();
    
    // Deep copy and convert Timestamps/FieldValues to Strings for JSON
    final serializableCustomers = customers.map((customer) {
      final map = Map<String, dynamic>.from(customer);
      map.forEach((key, value) {
        if (value is Timestamp) {
          map[key] = value.toDate().toIso8601String();
        } else if (value is FieldValue) {
          // FieldValue can't be easily converted, use current time as placeholder
          map[key] = DateTime.now().toIso8601String();
        }
      });
      return map;
    }).toList();

    final String jsonStr = jsonEncode(serializableCustomers);
    await _prefs?.setString(_cacheKey, jsonStr);
  }

  Future<List<Map<String, dynamic>>?> getCachedCustomers() async {
    await init();
    final String? jsonStr = _prefs?.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await init();
    await _prefs?.remove(_cacheKey);
  }
}
