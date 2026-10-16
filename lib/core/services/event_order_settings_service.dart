import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported data types for custom event/subevent columns
enum EventCustomColumnType {
  text,
  number,
  decimal,
  date,
  dropdown,
  boolean,
}

/// Target type for the custom column
enum EventColumnTarget {
  event,    // For main event orders
  subEvent, // For sub-events within an event
}

/// Model for a custom column definition for events/subevents
class EventCustomColumn {
  final String id;
  final String name;
  final EventCustomColumnType type;
  final EventColumnTarget target;
  final bool isRequired;
  final String? defaultValue;
  final List<String>? dropdownOptions; // For dropdown type
  final String? placeholder;
  final bool isActive;

  EventCustomColumn({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
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
    'target': target.index,
    'isRequired': isRequired,
    'defaultValue': defaultValue,
    'dropdownOptions': dropdownOptions,
    'placeholder': placeholder,
    'isActive': isActive,
  };

  factory EventCustomColumn.fromJson(Map<String, dynamic> json) => EventCustomColumn(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EventCustomColumnType.values[json['type'] as int],
    target: EventColumnTarget.values[json['target'] as int? ?? 0],
    isRequired: json['isRequired'] as bool? ?? false,
    defaultValue: json['defaultValue'] as String?,
    dropdownOptions: (json['dropdownOptions'] as List<dynamic>?)?.cast<String>(),
    placeholder: json['placeholder'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );

  EventCustomColumn copyWith({
    String? id,
    String? name,
    EventCustomColumnType? type,
    EventColumnTarget? target,
    bool? isRequired,
    String? defaultValue,
    List<String>? dropdownOptions,
    String? placeholder,
    bool? isActive,
  }) => EventCustomColumn(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    target: target ?? this.target,
    isRequired: isRequired ?? this.isRequired,
    defaultValue: defaultValue ?? this.defaultValue,
    dropdownOptions: dropdownOptions ?? this.dropdownOptions,
    placeholder: placeholder ?? this.placeholder,
    isActive: isActive ?? this.isActive,
  );

  /// Get display name for column type
  static String getTypeDisplayName(EventCustomColumnType type) {
    switch (type) {
      case EventCustomColumnType.text:
        return 'Text';
      case EventCustomColumnType.number:
        return 'Number (Integer)';
      case EventCustomColumnType.decimal:
        return 'Decimal Number';
      case EventCustomColumnType.date:
        return 'Date';
      case EventCustomColumnType.dropdown:
        return 'Dropdown';
      case EventCustomColumnType.boolean:
        return 'Yes/No';
    }
  }

  /// Get display name for column target
  static String getTargetDisplayName(EventColumnTarget target) {
    switch (target) {
      case EventColumnTarget.event:
        return 'Event';
      case EventColumnTarget.subEvent:
        return 'Sub-Event';
    }
  }
}

/// Service for managing event/subevent custom columns settings
/// Stores in Firestore per user so data persists across app reinstalls
class EventOrderSettingsService extends ChangeNotifier {
  static const String _localCacheKey = 'event_order_custom_columns_cache';
  static const String _firestoreCollection = 'event_order_settings';
  static const String _customColumnsDoc = 'custom_columns';
  
  static EventOrderSettingsService? _instance;
  
  List<EventCustomColumn> _customColumns = [];
  bool _isLoading = false;
  String? _currentUserId;
  
  EventOrderSettingsService._();
  
  static EventOrderSettingsService get instance {
    _instance ??= EventOrderSettingsService._();
    return _instance!;
  }
  
  /// Get all custom columns
  List<EventCustomColumn> get customColumns => _customColumns;
  
  /// Get only active custom columns
  List<EventCustomColumn> get activeCustomColumns => 
      _customColumns.where((c) => c.isActive).toList();
  
  /// Get active columns for events only
  List<EventCustomColumn> get activeEventColumns =>
      _customColumns.where((c) => c.isActive && c.target == EventColumnTarget.event).toList();
  
  /// Get active columns for sub-events only
  List<EventCustomColumn> get activeSubEventColumns =>
      _customColumns.where((c) => c.isActive && c.target == EventColumnTarget.subEvent).toList();
  
  /// Get columns for events only
  List<EventCustomColumn> get eventColumns =>
      _customColumns.where((c) => c.target == EventColumnTarget.event).toList();
  
  /// Get columns for sub-events only
  List<EventCustomColumn> get subEventColumns =>
      _customColumns.where((c) => c.target == EventColumnTarget.subEvent).toList();
  
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
        debugPrint('[EventOrderSettings] No user logged in, loading from local cache');
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
              .map((json) => EventCustomColumn.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint('[EventOrderSettings] Loaded ${_customColumns.length} columns from Firestore');
          
          // Update local cache
          await _saveToLocalCache();
        }
      } else {
        debugPrint('[EventOrderSettings] No Firestore data, checking local cache');
        await _loadFromLocalCache();
        
        // If we have local data, sync it to Firestore
        if (_customColumns.isNotEmpty) {
          await _saveToFirestore();
        }
      }
    } catch (e) {
      debugPrint('[EventOrderSettings] Error loading from Firestore: $e');
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
            .map((json) => EventCustomColumn.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('[EventOrderSettings] Loaded ${_customColumns.length} columns from local cache');
      }
    } catch (e) {
      debugPrint('[EventOrderSettings] Error loading from local cache: $e');
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
      debugPrint('[EventOrderSettings] Error saving to local cache: $e');
    }
  }
  
  /// Save to Firestore
  Future<void> _saveToFirestore() async {
    try {
      final docRef = _userSettingsDoc;
      if (docRef == null) {
        debugPrint('[EventOrderSettings] No user logged in, cannot save to Firestore');
        return;
      }
      
      final jsonList = _customColumns.map((c) => c.toJson()).toList();
      await docRef.set({
        'columns': jsonList,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('[EventOrderSettings] Saved ${_customColumns.length} columns to Firestore');
    } catch (e) {
      debugPrint('[EventOrderSettings] Error saving to Firestore: $e');
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
  Future<void> addColumn(EventCustomColumn column) async {
    _customColumns.add(column);
    await _saveColumns();
    notifyListeners();
  }
  
  /// Update an existing column
  Future<void> updateColumn(String id, EventCustomColumn updatedColumn) async {
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
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final column = _customColumns.removeAt(oldIndex);
    _customColumns.insert(newIndex, column);
    await _saveColumns();
    notifyListeners();
  }
  
  /// Generate unique column ID
  String generateColumnId() {
    return 'col_${DateTime.now().millisecondsSinceEpoch}_${_customColumns.length}';
  }
}
