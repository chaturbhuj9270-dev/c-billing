import 'package:flutter/foundation.dart';
import 'package:c_billing/features/product/offline/entities/product_entity.dart';

class Product {
  final String id;
  final int
  indexNo; // Unique index number for quick lookup (e.g., 101, 102, 103)
  final String name;
  final String companyName;
  final String category;
  final double purchasePrice;
  final double salesPrice;
  final int currentStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? defaultSupplierId;
  final String? defaultSupplierName;
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;
  final bool isSynced;
  final String? customFieldsJson;
  final String? unit; // Measurement unit (kg, ltr, pcs, etc.)
  final String? barcode; // Manufacturer or app-generated barcode / QR payload
  /// Garment size (e.g. S, M, L, 42)
  final String? size;
  /// Garment / item color
  final String? color;
  /// Maximum retail price (medical / regulated retail)
  final double? mrp;
  /// Drug / product composition (medical)
  final String? composition;
  /// Schedule H / H1 / X etc. (medical)
  final String? drugSchedule;
  /// Pack label when buying bulk / selling pack (e.g. Strip, Bag, Box).
  final String? packUnit;
  /// Base [unit] count in one pack (e.g. 10 tablets per strip). Stock is always base units.
  final int unitsPerPack;

  Product({
    required this.id,
    required this.indexNo,
    required this.name,
    required this.companyName,
    required this.category,
    required this.purchasePrice,
    required this.salesPrice,
    required this.currentStock,
    required this.createdAt,
    required this.updatedAt,
    this.defaultSupplierId,
    this.defaultSupplierName,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
    this.isSynced = true,
    this.customFieldsJson,
    this.unit,
    this.barcode,
    this.size,
    this.color,
    this.mrp,
    this.composition,
    this.drugSchedule,
    this.packUnit,
    this.unitsPerPack = 1,
  });

  bool get hasPackSell =>
      unitsPerPack > 1 && packUnit != null && packUnit!.trim().isNotEmpty;

  /// Name with size/color for billing and lists.
  String get displayName => formatBillName(name, size: size, color: color);

  /// Builds a bill/list label with optional garment + medical lot details.
  static String formatBillName(
    String name, {
    String? size,
    String? color,
    String? batchNumber,
  }) {
    final parts = <String>[];
    if (size != null && size.trim().isNotEmpty) parts.add(size.trim());
    if (color != null && color.trim().isNotEmpty) parts.add(color.trim());
    var label = parts.isEmpty ? name : '$name (${parts.join(' / ')})';
    if (batchNumber != null && batchNumber.trim().isNotEmpty) {
      label = '$label · Lot ${batchNumber.trim()}';
    }
    return label;
  }

  // Factory constructor to create from ProductEntity (offline entity)
  factory Product.fromProductEntity(dynamic entity) {
    return Product(
      id: entity.serverId ?? 'local_${entity.id}',
      indexNo: entity.indexNo ?? 0,
      name: entity.name ?? '',
      companyName: entity.companyName ?? '',
      category: entity.category ?? '',
      purchasePrice: entity.purchasePrice ?? 0.0,
      salesPrice: entity.salesPrice ?? 0.0,
      currentStock: entity.currentStock ?? 0,
      createdAt: entity.createdAt ?? DateTime.now(),
      updatedAt: entity.updatedAt ?? DateTime.now(),
      defaultSupplierId: entity.defaultSupplierId,
      defaultSupplierName: entity.defaultSupplierName,
      cgstPercent: (entity.cgstPercent as num?)?.toDouble() ?? 0.0,
      sgstPercent: (entity.sgstPercent as num?)?.toDouble() ?? 0.0,
      hsnCode: entity.hsnCode as String?,
      isSynced: entity.syncStatus == SyncStatus.synced,
      customFieldsJson: entity.customFieldsJson as String?,
      unit: entity.unit as String?,
      barcode: entity.barcode as String?,
      size: entity.size as String?,
      color: entity.color as String?,
      mrp: (entity.mrp as num?)?.toDouble(),
      composition: entity.composition as String?,
      drugSchedule: entity.drugSchedule as String?,
      packUnit: entity.packUnit as String?,
      unitsPerPack: (entity.unitsPerPack as int?) ?? 1,
    );
  }
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: (json['id'] ?? '') as String,
        indexNo: (json['indexNo'] ?? 0) as int,
        name: (json['name'] ?? '') as String,
        companyName: (json['companyName'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        purchasePrice: ((json['purchasePrice'] ?? 0) as num).toDouble(),
        salesPrice: ((json['salesPrice'] ?? 0) as num).toDouble(),
        currentStock: (json['currentStock'] ?? 0) as int,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        defaultSupplierId: json['defaultSupplierId'] as String?,
        defaultSupplierName: json['defaultSupplierName'] as String?,
        cgstPercent: ((json['cgstPercent'] ?? 0) as num).toDouble(),
        sgstPercent: ((json['sgstPercent'] ?? 0) as num).toDouble(),
        hsnCode: json['hsnCode'] as String?,
        customFieldsJson: json['customFieldsJson'] as String?,
        unit: json['unit'] as String?,
        barcode: json['barcode'] as String?,
        size: json['size'] as String?,
        color: json['color'] as String?,
        mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
        composition: json['composition'] as String?,
        drugSchedule: json['drugSchedule'] as String?,
        packUnit: json['packUnit'] as String?,
        unitsPerPack: (json['unitsPerPack'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      debugPrint('[ERROR] Failed to parse Product from JSON: $json');
      debugPrint('[ERROR] Error details: $e');
      // Return a default product to prevent crashes
      return Product(
        id: json['id']?.toString() ?? '',
        indexNo: 0,
        name: json['name']?.toString() ?? 'Unknown Product',
        companyName: json['companyName']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Uncategorized',
        purchasePrice: 0.0,
        salesPrice: 0.0,
        currentStock: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'indexNo': indexNo,
      'name': name,
      'companyName': companyName,
      'category': category,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'currentStock': currentStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'defaultSupplierId': defaultSupplierId,
      'defaultSupplierName': defaultSupplierName,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'hsnCode': hsnCode,
      'customFieldsJson': customFieldsJson,
      'unit': unit,
      'barcode': barcode,
      'size': size,
      'color': color,
      'mrp': mrp,
      'composition': composition,
      'drugSchedule': drugSchedule,
      'packUnit': packUnit,
      'unitsPerPack': unitsPerPack,
    };
  }

  // Copy with modifications
  Product copyWith({
    String? id,
    int? indexNo,
    String? name,
    String? companyName,
    String? category,
    double? purchasePrice,
    double? salesPrice,
    int? currentStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? defaultSupplierId,
    String? defaultSupplierName,
    double? cgstPercent,
    double? sgstPercent,
    String? hsnCode,
    bool? isSynced,
    String? customFieldsJson,
    String? unit,
    String? barcode,
    String? size,
    String? color,
    double? mrp,
    String? composition,
    String? drugSchedule,
    String? packUnit,
    int? unitsPerPack,
  }) {
    return Product(
      id: id ?? this.id,
      indexNo: indexNo ?? this.indexNo,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      currentStock: currentStock ?? this.currentStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultSupplierId: defaultSupplierId ?? this.defaultSupplierId,
      defaultSupplierName: defaultSupplierName ?? this.defaultSupplierName,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      hsnCode: hsnCode ?? this.hsnCode,
      isSynced: isSynced ?? this.isSynced,
      customFieldsJson: customFieldsJson ?? this.customFieldsJson,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      size: size ?? this.size,
      color: color ?? this.color,
      mrp: mrp ?? this.mrp,
      composition: composition ?? this.composition,
      drugSchedule: drugSchedule ?? this.drugSchedule,
      packUnit: packUnit ?? this.packUnit,
      unitsPerPack: unitsPerPack ?? this.unitsPerPack,
    );
  }

  // Get total stock value based on purchase price
  double getStockValue() {
    return currentStock * purchasePrice;
  }

  // Check if low stock
  bool isLowStock({int threshold = 10}) {
    return currentStock <= threshold;
  }
}
