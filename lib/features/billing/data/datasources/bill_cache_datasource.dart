import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bill.dart';

class BillCacheDataSource {
  static const String _cacheKey = 'bill_list_cache';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveBills(List<Bill> bills) async {
    await init();
    final List<Map<String, dynamic>> billJsonList = 
        bills.map((bill) => bill.toJson()).toList();
    final String jsonStr = jsonEncode(billJsonList);
    await _prefs?.setString(_cacheKey, jsonStr);
  }

  Future<List<Bill>?> getCachedBills() async {
    await init();
    final String? jsonStr = _prefs?.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Bill.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('[ERROR] Failed to load bills from cache: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    await init();
    await _prefs?.remove(_cacheKey);
  }
}
