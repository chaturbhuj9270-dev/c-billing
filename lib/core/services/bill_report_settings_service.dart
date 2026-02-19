import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for a bill report column configuration
class BillReportColumn {
  final String id;
  final String name;
  final bool isDefault;
  bool isVisible;

  BillReportColumn({
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

  factory BillReportColumn.fromJson(Map<String, dynamic> json) => BillReportColumn(
    id: json['id'] as String,
    name: json['name'] as String,
    isDefault: json['isDefault'] as bool? ?? true,
    isVisible: json['isVisible'] as bool? ?? true,
  );

  BillReportColumn copyWith({bool? isVisible}) => BillReportColumn(
    id: id,
    name: name,
    isDefault: isDefault,
    isVisible: isVisible ?? this.isVisible,
  );
}

/// Service to manage bill print/report column visibility settings
/// Stored in Firestore per user with SharedPreferences fallback
class BillReportSettingsService {
  BillReportSettingsService._();
  static final BillReportSettingsService instance = BillReportSettingsService._();

  static const String _prefsKey = 'bill_report_columns';
  
  // Default columns for bill/invoice
  static const List<Map<String, dynamic>> _defaultColumns = [
    {'id': 'sr_no', 'name': 'Sr No', 'isDefault': true, 'isVisible': true},
    {'id': 'product_name', 'name': 'Product Name', 'isDefault': true, 'isVisible': true},
    {'id': 'hsn_code', 'name': 'HSN Code', 'isDefault': true, 'isVisible': false},
    {'id': 'company', 'name': 'Company', 'isDefault': true, 'isVisible': false},
    {'id': 'quantity', 'name': 'Quantity', 'isDefault': true, 'isVisible': true},
    {'id': 'unit', 'name': 'Unit', 'isDefault': true, 'isVisible': false},
    {'id': 'rate', 'name': 'Rate', 'isDefault': true, 'isVisible': true},
    {'id': 'discount', 'name': 'Discount', 'isDefault': true, 'isVisible': false},
    {'id': 'tax', 'name': 'Tax', 'isDefault': true, 'isVisible': false},
    {'id': 'amount', 'name': 'Amount', 'isDefault': true, 'isVisible': true},
  ];

  List<BillReportColumn> _columns = [];
  bool _initialized = false;

  /// Get all report columns
  List<BillReportColumn> get columns => List.unmodifiable(_columns);

  /// Get only visible columns
  List<BillReportColumn> get visibleColumns => 
      _columns.where((c) => c.isVisible).toList();

  /// Check if a column is visible by ID
  bool isColumnVisible(String columnId) {
    final column = _columns.firstWhere(
      (c) => c.id == columnId,
      orElse: () => BillReportColumn(id: columnId, name: '', isVisible: false),
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
            .doc('bill_report_columns')
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final savedColumns = (data['columns'] as List<dynamic>?)
              ?.map((e) => BillReportColumn.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
          
          // Merge with defaults to ensure new columns are included
          _columns = _mergeWithDefaults(savedColumns);
          debugPrint('[BillReportSettings] Loaded ${_columns.length} columns from Firestore');
          
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
            ?.map((e) => BillReportColumn.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        
        _columns = _mergeWithDefaults(savedColumns);
        debugPrint('[BillReportSettings] Loaded ${_columns.length} columns from SharedPreferences');
      } else {
        // Initialize with defaults
        _columns = _defaultColumns
            .map((e) => BillReportColumn.fromJson(e))
            .toList();
        
        debugPrint('[BillReportSettings] Initialized with ${_columns.length} default columns');
      }
    } catch (e) {
      debugPrint('[BillReportSettings] Error loading columns: $e');
      _columns = _defaultColumns
          .map((e) => BillReportColumn.fromJson(e))
          .toList();
    }
  }

  /// Merge saved columns with defaults (to handle new columns added later)
  List<BillReportColumn> _mergeWithDefaults(List<BillReportColumn> saved) {
    final result = <BillReportColumn>[];
    
    // Add all default columns, using saved visibility if available
    for (final defaultCol in _defaultColumns) {
      final savedCol = saved.firstWhere(
        (c) => c.id == defaultCol['id'],
        orElse: () => BillReportColumn.fromJson(defaultCol),
      );
      result.add(savedCol);
    }
    
    // Add any saved non-default columns (custom columns)
    for (final savedCol in saved) {
      if (!_defaultColumns.any((d) => d['id'] == savedCol.id)) {
        result.add(savedCol);
      }
    }
    
    return result;
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
            .doc('bill_report_columns')
            .set({
          'columns': _columns.map((c) => c.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[BillReportSettings] Saved to Firestore');
      }
      
      await _saveToPrefs();
    } catch (e) {
      debugPrint('[BillReportSettings] Error saving columns: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode({
        'columns': _columns.map((c) => c.toJson()).toList(),
      }));
    } catch (e) {
      debugPrint('[BillReportSettings] Error saving to prefs: $e');
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _columns = _defaultColumns
        .map((e) => BillReportColumn.fromJson(e))
        .toList();
    await _saveColumns();
  }
}
