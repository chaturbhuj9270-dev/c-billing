import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported data types for custom product columns
enum CustomColumnType {
  text,
  number,
  decimal,
  date,
  dropdown,
  boolean,
}

/// Model for a custom column definition
class CustomColumn {
  final String id;
  final String name;
  final CustomColumnType type;
  final bool isRequired;
  final String? defaultValue;
  final List<String>? dropdownOptions; // For dropdown type
  final String? placeholder;
  final bool isActive;

  CustomColumn({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
    this.defaultValue,
    this.dropdownOptions,
    this.placeholder,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'isRequired': isRequired,
    'defaultValue': defaultValue,
    'dropdownOptions': dropdownOptions,
    'placeholder': placeholder,
    'isActive': isActive,
  };

  factory CustomColumn.fromJson(Map<String, dynamic> json) => CustomColumn(
    id: json['id'] as String,
    name: json['name'] as String,
    type: CustomColumnType.values[json['type'] as int],
    isRequired: json['isRequired'] as bool? ?? false,
    defaultValue: json['defaultValue'] as String?,
    dropdownOptions: (json['dropdownOptions'] as List<dynamic>?)?.cast<String>(),
    placeholder: json['placeholder'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );

  CustomColumn copyWith({
    String? id,
    String? name,
    CustomColumnType? type,
    bool? isRequired,
    String? defaultValue,
    List<String>? dropdownOptions,
    String? placeholder,
    bool? isActive,
  }) => CustomColumn(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    isRequired: isRequired ?? this.isRequired,
    defaultValue: defaultValue ?? this.defaultValue,
    dropdownOptions: dropdownOptions ?? this.dropdownOptions,
    placeholder: placeholder ?? this.placeholder,
    isActive: isActive ?? this.isActive,
  );

  /// Get display name for column type
  static String getTypeDisplayName(CustomColumnType type) {
    switch (type) {
      case CustomColumnType.text:
        return 'Text';
      case CustomColumnType.number:
        return 'Number (Integer)';
      case CustomColumnType.decimal:
        return 'Decimal Number';
      case CustomColumnType.date:
        return 'Date';
      case CustomColumnType.dropdown:
        return 'Dropdown';
      case CustomColumnType.boolean:
        return 'Yes/No';
    }
  }
}

/// Service for managing product custom columns settings
/// Stores in Firestore per user so data persists across app reinstalls
class ProductSettingsService extends ChangeNotifier {
  static const String _localCacheKey = 'product_custom_columns_cache';
  static const String _firestoreCollection = 'product_settings';
  static const String _customColumnsDoc = 'custom_columns';
  
  static ProductSettingsService? _instance;
  
  List<CustomColumn> _customColumns = [];
  bool _isLoading = false;
  String? _currentUserId;
  
  ProductSettingsService._();
  
  static ProductSettingsService get instance {
    _instance ??= ProductSettingsService._();
    return _instance!;
  }
  
  /// Get all custom columns
  List<CustomColumn> get customColumns => _customColumns;
  
  /// Get only active custom columns
  List<CustomColumn> get activeCustomColumns => 
      _customColumns.where((c) => c.isActive).toList();
  
  /// Check if loading
  bool get isLoading => _isLoading;
  
  /// Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  
  /// Get Firestore reference for user's custom columns
  DocumentReference? get _userSettingsDoc {
    final uid = _userId;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_firestoreCollection)
        .doc(_customColumnsDoc);
  }
  
  /// Initialize service - load from Firestore (with local cache fallback)
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final uid = _userId;
      if (uid == null) {
        debugPrint('[ProductSettings] No user logged in, loading from local cache');
        await _loadFromLocalCache();
        return;
      }
      
      _currentUserId = uid;
      
      // Try to load from Firestore first
      final doc = await _userSettingsDoc?.get();
      
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['columns'] != null) {
          final List<dynamic> jsonList = data['columns'] as List<dynamic>;
          _customColumns = jsonList
              .map((json) => CustomColumn.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint('[ProductSettings] Loaded ${_customColumns.length} columns from Firestore');
          
          // Update local cache
          await _saveToLocalCache();
        }
      } else {
        debugPrint('[ProductSettings] No Firestore data, checking local cache');
        await _loadFromLocalCache();
        
        // If we have local data, sync it to Firestore
        if (_customColumns.isNotEmpty) {
          await _saveToFirestore();
        }
      }
    } catch (e) {
      debugPrint('[ProductSettings] Error loading from Firestore: $e');
      // Fallback to local cache
      await _loadFromLocalCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Reload data (useful when user changes)
  Future<void> reload() async {
    final newUserId = _userId;
    if (newUserId != _currentUserId) {
      _customColumns = [];
      _currentUserId = newUserId;
    }
    await init();
  }
  
  /// Load from local cache (SharedPreferences)
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _userId ?? 'anonymous';
      final cacheKey = '${_localCacheKey}_$uid';
      final savedData = prefs.getString(cacheKey);
      
      if (savedData != null) {
        final List<dynamic> jsonList = jsonDecode(savedData);
        _customColumns = jsonList
            .map((json) => CustomColumn.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('[ProductSettings] Loaded ${_customColumns.length} columns from local cache');
      }
    } catch (e) {
      debugPrint('[ProductSettings] Error loading from local cache: $e');
      _customColumns = [];
    }
  }
  
  /// Save to local cache
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _userId ?? 'anonymous';
      final cacheKey = '${_localCacheKey}_$uid';
      final jsonList = _customColumns.map((c) => c.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[ProductSettings] Error saving to local cache: $e');
    }
  }
  
  /// Save to Firestore
  Future<void> _saveToFirestore() async {
    try {
      final docRef = _userSettingsDoc;
      if (docRef == null) {
        debugPrint('[ProductSettings] No user logged in, cannot save to Firestore');
        return;
      }
      
      final jsonList = _customColumns.map((c) => c.toJson()).toList();
      await docRef.set({
        'columns': jsonList,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('[ProductSettings] Saved ${_customColumns.length} columns to Firestore');
    } catch (e) {
      debugPrint('[ProductSettings] Error saving to Firestore: $e');
    }
  }
  
  /// Save columns (to both Firestore and local cache)
  Future<void> _saveColumns() async {
    await Future.wait([
      _saveToFirestore(),
      _saveToLocalCache(),
    ]);
  }
  
  /// Add a new custom column
  Future<void> addColumn(CustomColumn column) async {
    _customColumns.add(column);
    await _saveColumns();
    notifyListeners();
  }
  
  /// Update an existing column
  Future<void> updateColumn(String id, CustomColumn updatedColumn) async {
    final index = _customColumns.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customColumns[index] = updatedColumn;
      await _saveColumns();
      notifyListeners();
    }
  }
  
  /// Delete a column
  Future<void> deleteColumn(String id) async {
    _customColumns.removeWhere((c) => c.id == id);
    await _saveColumns();
    notifyListeners();
  }
  
  /// Toggle column active status
  Future<void> toggleColumnActive(String id) async {
    final index = _customColumns.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customColumns[index] = _customColumns[index].copyWith(
        isActive: !_customColumns[index].isActive,
      );
      await _saveColumns();
      notifyListeners();
    }
  }
  
  /// Reorder columns
  Future<void> reorderColumns(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final column = _customColumns.removeAt(oldIndex);
    _customColumns.insert(newIndex, column);
    await _saveColumns();
    notifyListeners();
  }
  
  /// Generate unique ID for new column
  String generateColumnId() {
    return 'custom_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Validate custom field value based on column type
  String? validateFieldValue(CustomColumn column, String? value) {
    if (column.isRequired && (value == null || value.isEmpty)) {
      return '${column.name} is required';
    }
    
    if (value == null || value.isEmpty) return null;
    
    switch (column.type) {
      case CustomColumnType.number:
        if (int.tryParse(value) == null) {
          return '${column.name} must be a valid number';
        }
        break;
      case CustomColumnType.decimal:
        if (double.tryParse(value) == null) {
          return '${column.name} must be a valid decimal';
        }
        break;
      case CustomColumnType.date:
        if (DateTime.tryParse(value) == null) {
          return '${column.name} must be a valid date';
        }
        break;
      default:
        break;
    }
    return null;
  }
  
  /// Clear all data (for logout)
  Future<void> clear() async {
    _customColumns = [];
    _currentUserId = null;
    notifyListeners();
  }
}
