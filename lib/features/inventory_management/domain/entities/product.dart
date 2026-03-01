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
  });

  // Factory constructor to create from ProductEntity (Isar offline entity)
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
      );
    } catch (e) {
      print('[ERROR] Failed to parse Product from JSON: $json');
      print('[ERROR] Error details: $e');
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
