import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseSettingsService extends ChangeNotifier {
  static const String _showManufacturingDateKey = 'purchase_show_manufacturing_date';
  static const String _showExpiryDateKey = 'purchase_show_expiry_date';
  static const String _availableUnitsKey = 'purchase_available_units';
  static const String _defaultUnitKey = 'purchase_default_unit';
  static const String _customUnitsKey = 'purchase_custom_units';
  static const String _showWarrantyKey = 'purchase_show_warranty';
  static const String _warrantyOptionsKey = 'purchase_warranty_options';
  static const String _defaultWarrantyKey = 'purchase_default_warranty';
  
  // All possible measurement units (built-in)
  static const List<String> builtInUnits = [
    'Item',
    'Qty',
    'Kg',
    'Grams',
    'Feet',
    'Meter',
    'Ltr',
    'Ml',
    'Pcs',
    'Box',
    'Dozen',
  ];
  
  // Built-in warranty options (in months, 0 = No Warranty)
  static const List<int> builtInWarrantyOptions = [0, 3, 6, 12, 24, 36];
  
  static PurchaseSettingsService? _instance;
  
  bool _showManufacturingDate = true;
  bool _showExpiryDate = true;
  bool _showWarranty = false;
  List<String> _availableUnits = ['Item', 'Qty', 'Kg', 'Grams', 'Ltr']; // Default available units
  List<String> _customUnits = []; // User-added custom units
  String _defaultUnit = 'Item';
  List<int> _warrantyOptions = [0, 3, 6, 12]; // Available warranty options
  int _defaultWarranty = 0; // Default warranty in months (0 = No Warranty)
  
  PurchaseSettingsService._();
  
  static PurchaseSettingsService get instance {
    _instance ??= PurchaseSettingsService._();
    return _instance!;
  }
  
  bool get showManufacturingDate => _showManufacturingDate;
  bool get showExpiryDate => _showExpiryDate;
  bool get showWarranty => _showWarranty;
  List<String> get availableUnits => _availableUnits;
  List<String> get customUnits => _customUnits;
  String get defaultUnit => _defaultUnit;
  List<int> get warrantyOptions => _warrantyOptions;
  int get defaultWarranty => _defaultWarranty;
  
  // Get all units (built-in + custom)
  List<String> get allUnits => [...builtInUnits, ..._customUnits];
  
  // Get all warranty options
  List<int> get allWarrantyOptions => builtInWarrantyOptions;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _showManufacturingDate = prefs.getBool(_showManufacturingDateKey) ?? true;
    _showExpiryDate = prefs.getBool(_showExpiryDateKey) ?? true;
    _showWarranty = prefs.getBool(_showWarrantyKey) ?? false;
    
    // Load custom units first
    final savedCustomUnits = prefs.getStringList(_customUnitsKey);
    if (savedCustomUnits != null) {
      _customUnits = savedCustomUnits;
    }
    
    // Load available units
    final savedUnits = prefs.getStringList(_availableUnitsKey);
    if (savedUnits != null && savedUnits.isNotEmpty) {
      _availableUnits = savedUnits;
    }
    
    // Load default unit
    _defaultUnit = prefs.getString(_defaultUnitKey) ?? 'Item';
    // Ensure default unit is in available units
    if (!_availableUnits.contains(_defaultUnit)) {
      _defaultUnit = _availableUnits.isNotEmpty ? _availableUnits.first : 'Item';
    }
    
    // Load warranty options
    final savedWarrantyOptions = prefs.getStringList(_warrantyOptionsKey);
    if (savedWarrantyOptions != null && savedWarrantyOptions.isNotEmpty) {
      _warrantyOptions = savedWarrantyOptions.map((e) => int.tryParse(e) ?? 0).toList();
    }
    
    // Load default warranty
    _defaultWarranty = prefs.getInt(_defaultWarrantyKey) ?? 0;
    if (!_warrantyOptions.contains(_defaultWarranty)) {
      _defaultWarranty = _warrantyOptions.isNotEmpty ? _warrantyOptions.first : 0;
    }
  }
  
  Future<void> setShowManufacturingDate(bool value) async {
    _showManufacturingDate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showManufacturingDateKey, value);
    notifyListeners();
  }
  
  Future<void> setShowExpiryDate(bool value) async {
    _showExpiryDate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showExpiryDateKey, value);
    notifyListeners();
  }
  
  Future<void> setShowWarranty(bool value) async {
    _showWarranty = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showWarrantyKey, value);
    notifyListeners();
  }
  
  Future<void> setWarrantyOptions(List<int> options) async {
    _warrantyOptions = options;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_warrantyOptionsKey, options.map((e) => e.toString()).toList());
    
    // If default warranty is no longer available, update it
    if (!_warrantyOptions.contains(_defaultWarranty)) {
      _defaultWarranty = _warrantyOptions.isNotEmpty ? _warrantyOptions.first : 0;
      await prefs.setInt(_defaultWarrantyKey, _defaultWarranty);
    }
    notifyListeners();
  }
  
  Future<void> setDefaultWarranty(int months) async {
    if (_warrantyOptions.contains(months)) {
      _defaultWarranty = months;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_defaultWarrantyKey, months);
      notifyListeners();
    }
  }
  
  String getWarrantyLabel(int months) {
    if (months == 0) return 'No Warranty';
    if (months == 1) return '1 Month';
    if (months < 12) return '$months Months';
    if (months == 12) return '1 Year';
    if (months == 24) return '2 Years';
    if (months == 36) return '3 Years';
    return '$months Months';
  }
  
  Future<void> setAvailableUnits(List<String> units) async {
    _availableUnits = units;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_availableUnitsKey, units);
    
    // If default unit is no longer available, update it
    if (!_availableUnits.contains(_defaultUnit)) {
      _defaultUnit = _availableUnits.isNotEmpty ? _availableUnits.first : 'Item';
      await prefs.setString(_defaultUnitKey, _defaultUnit);
    }
    notifyListeners();
  }
  
  Future<void> setDefaultUnit(String unit) async {
    if (_availableUnits.contains(unit)) {
      _defaultUnit = unit;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultUnitKey, unit);
      notifyListeners();
    }
  }
  
  bool isUnitAvailable(String unit) {
    return _availableUnits.contains(unit);
  }
  
  bool isCustomUnit(String unit) {
    return _customUnits.contains(unit);
  }
  
  Future<void> addCustomUnit(String unit) async {
    final trimmedUnit = unit.trim();
    if (trimmedUnit.isEmpty) return;
    
    // Check if unit already exists (built-in or custom)
    if (builtInUnits.contains(trimmedUnit) || _customUnits.contains(trimmedUnit)) {
      return;
    }
    
    _customUnits.add(trimmedUnit);
    _availableUnits.add(trimmedUnit); // Auto-add to available
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customUnitsKey, _customUnits);
    await prefs.setStringList(_availableUnitsKey, _availableUnits);
    notifyListeners();
  }
  
  Future<void> removeCustomUnit(String unit) async {
    if (!_customUnits.contains(unit)) return;
    
    // Don't allow removing if it's the default unit
    if (_defaultUnit == unit) return;
    
    _customUnits.remove(unit);
    _availableUnits.remove(unit);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customUnitsKey, _customUnits);
    await prefs.setStringList(_availableUnitsKey, _availableUnits);
    notifyListeners();
  }
  
  Future<void> toggleUnit(String unit) async {
    if (_availableUnits.contains(unit)) {
      // Don't allow removing the last unit or the default unit
      if (_availableUnits.length > 1 && unit != _defaultUnit) {
        _availableUnits.remove(unit);
      }
    } else {
      _availableUnits.add(unit);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_availableUnitsKey, _availableUnits);
    notifyListeners();
  }
}
