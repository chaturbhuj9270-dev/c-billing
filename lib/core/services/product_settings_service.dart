import 'dart:convert';
import 'package:flutter/foundation.dart';
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
class ProductSettingsService extends ChangeNotifier {
  static const String _customColumnsKey = 'product_custom_columns';
  
  static ProductSettingsService? _instance;
  
  List<CustomColumn> _customColumns = [];
  
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
  
  /// Initialize service - load saved columns
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_customColumnsKey);
    
    if (savedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(savedData);
        _customColumns = jsonList
            .map((json) => CustomColumn.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[ProductSettings] Error loading custom columns: $e');
        _customColumns = [];
      }
    }
  }
  
  /// Save columns to persistent storage
  Future<void> _saveColumns() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customColumns.map((c) => c.toJson()).toList();
    await prefs.setString(_customColumnsKey, jsonEncode(jsonList));
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
}
