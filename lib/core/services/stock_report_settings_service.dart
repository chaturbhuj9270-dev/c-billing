import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_settings_service.dart';

/// Model for a stock report column configuration
class StockReportColumn {
  final String id;
  final String name;
  final bool isDefault; // true = built-in column, false = custom column
  bool isVisible;

  StockReportColumn({
    required this.id,
    required this.name,
    this.isDefault = true,
    this.isVisible = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isDefault': isDefault,
    'isVisible': isVisible,
  };

  factory StockReportColumn.fromJson(Map<String, dynamic> json) => StockReportColumn(
    id: json['id'] as String,
    name: json['name'] as String,
    isDefault: json['isDefault'] as bool? ?? true,
    isVisible: json['isVisible'] as bool? ?? true,
  );

  StockReportColumn copyWith({bool? isVisible}) => StockReportColumn(
    id: id,
    name: name,
    isDefault: isDefault,
    isVisible: isVisible ?? this.isVisible,
  );
}

/// Service to manage stock report column visibility settings
/// Stored in Firestore per user with SharedPreferences fallback
class StockReportSettingsService {
  StockReportSettingsService._();
  static final StockReportSettingsService instance = StockReportSettingsService._();

  static const String _prefsKey = 'stock_report_columns';
  
  // Default columns for stock report
  static const List<Map<String, dynamic>> _defaultColumns = [
    {'id': 'sr_no', 'name': 'Sr No', 'isDefault': true, 'isVisible': true},
    {'id': 'product_name', 'name': 'Product Name', 'isDefault': true, 'isVisible': true},
    {'id': 'category', 'name': 'Category', 'isDefault': true, 'isVisible': true},
    {'id': 'company', 'name': 'Company', 'isDefault': true, 'isVisible': true},
    {'id': 'hsn_code', 'name': 'HSN Code', 'isDefault': true, 'isVisible': false},
    {'id': 'purchase_price', 'name': 'Purchase Price', 'isDefault': true, 'isVisible': false},
    {'id': 'selling_price', 'name': 'Selling Price', 'isDefault': true, 'isVisible': false},
    {'id': 'stock', 'name': 'Stock', 'isDefault': true, 'isVisible': true},
    {'id': 'stock_value', 'name': 'Stock Value', 'isDefault': true, 'isVisible': false},
    {'id': 'status', 'name': 'Status', 'isDefault': true, 'isVisible': true},
    {'id': 'order_qty', 'name': 'Order Qty', 'isDefault': true, 'isVisible': true},
    {'id': 'supplier', 'name': 'Supplier', 'isDefault': true, 'isVisible': false},
    {'id': 'cgst', 'name': 'CGST %', 'isDefault': true, 'isVisible': false},
    {'id': 'sgst', 'name': 'SGST %', 'isDefault': true, 'isVisible': false},
  ];

  List<StockReportColumn> _columns = [];
  bool _initialized = false;

  /// Get all report columns (default + custom)
  List<StockReportColumn> get columns => List.unmodifiable(_columns);

  /// Get only visible columns
  List<StockReportColumn> get visibleColumns => 
      _columns.where((c) => c.isVisible).toList();

  /// Check if a column is visible by ID
  bool isColumnVisible(String columnId) {
    // Return default visibility if not initialized
    if (!_initialized || _columns.isEmpty) {
      final defaultCol = _defaultColumns.firstWhere(
        (c) => c['id'] == columnId,
        orElse: () => {'isVisible': false},
      );
      return defaultCol['isVisible'] as bool? ?? false;
    }
    
    final column = _columns.firstWhere(
      (c) => c.id == columnId,
      orElse: () => StockReportColumn(id: columnId, name: '', isVisible: false),
    );
    return column.isVisible;
  }

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    await _loadColumns();
    _initialized = true;
  }

  /// Reload columns (call after login)
  Future<void> reload() async {
    _initialized = false;
    await _loadColumns();
    _initialized = true;
  }

  /// Load columns from Firestore or SharedPreferences
  Future<void> _loadColumns() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to load from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('stock_report_columns')
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final savedColumns = (data['columns'] as List<dynamic>?)
              ?.map((e) => StockReportColumn.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
          
          // Merge with defaults to ensure new columns are included
          _columns = _mergeWithDefaults(savedColumns);
          debugPrint('[StockReportSettings] Loaded ${_columns.length} columns from Firestore');
          
          // Also save to SharedPreferences as cache
          await _saveToPrefs();
          return;
        }
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      
      if (savedJson != null) {
        final savedData = jsonDecode(savedJson) as Map<String, dynamic>;
        final savedColumns = (savedData['columns'] as List<dynamic>?)
            ?.map((e) => StockReportColumn.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        
        _columns = _mergeWithDefaults(savedColumns);
        debugPrint('[StockReportSettings] Loaded ${_columns.length} columns from SharedPreferences');
      } else {
        // Initialize with defaults
        _columns = _defaultColumns
            .map((e) => StockReportColumn.fromJson(e))
            .toList();
        
        // Add custom columns from ProductSettingsService
        _addCustomColumns();
        
        debugPrint('[StockReportSettings] Initialized with ${_columns.length} default columns');
      }
    } catch (e) {
      debugPrint('[StockReportSettings] Error loading columns: $e');
      _columns = _defaultColumns
          .map((e) => StockReportColumn.fromJson(e))
          .toList();
      _addCustomColumns();
    }
  }

  /// Merge saved columns with defaults (to handle new columns added later)
  List<StockReportColumn> _mergeWithDefaults(List<StockReportColumn> saved) {
    final result = <StockReportColumn>[];
    
    // Add all default columns, using saved visibility if available
    for (final defaultCol in _defaultColumns) {
      final savedCol = saved.firstWhere(
        (c) => c.id == defaultCol['id'],
        orElse: () => StockReportColumn.fromJson(defaultCol),
      );
      result.add(savedCol);
    }
    
    // Add any saved non-default columns (custom columns)
    for (final savedCol in saved) {
      if (!_defaultColumns.any((d) => d['id'] == savedCol.id)) {
        result.add(savedCol);
      }
    }
    
    // Add any new custom columns from ProductSettingsService
    _addCustomColumnsToList(result);
    
    return result;
  }

  /// Add custom columns from ProductSettingsService
  void _addCustomColumns() {
    _addCustomColumnsToList(_columns);
  }

  void _addCustomColumnsToList(List<StockReportColumn> list) {
    final customColumns = ProductSettingsService.instance.activeCustomColumns;
    for (final custom in customColumns) {
      if (!list.any((c) => c.id == 'custom_${custom.id}')) {
        list.add(StockReportColumn(
          id: 'custom_${custom.id}',
          name: custom.name,
          isDefault: false,
          isVisible: false,
        ));
      }
    }
  }

  /// Refresh custom columns (call when custom columns change)
  Future<void> refreshCustomColumns() async {
    _addCustomColumns();
    await _saveColumns();
  }

  /// Update column visibility
  Future<void> setColumnVisibility(String columnId, bool isVisible) async {
    final index = _columns.indexWhere((c) => c.id == columnId);
    if (index != -1) {
      _columns[index] = _columns[index].copyWith(isVisible: isVisible);
      await _saveColumns();
    }
  }

  /// Save columns to Firestore and SharedPreferences
  Future<void> _saveColumns() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('stock_report_columns')
            .set({
          'columns': _columns.map((c) => c.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[StockReportSettings] Saved to Firestore');
      }
      
      await _saveToPrefs();
    } catch (e) {
      debugPrint('[StockReportSettings] Error saving columns: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode({
        'columns': _columns.map((c) => c.toJson()).toList(),
      }));
    } catch (e) {
      debugPrint('[StockReportSettings] Error saving to prefs: $e');
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _columns = _defaultColumns
        .map((e) => StockReportColumn.fromJson(e))
        .toList();
    _addCustomColumns();
    await _saveColumns();
  }
}
