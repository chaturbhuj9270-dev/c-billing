import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../../domain/utils/purchase_tax_calculator.dart';

// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

// Sync status for delta sync logic Only purchases with status != SYNCED will be pushed to server
enum PurchaseSyncStatus {
  // Newly created locally, not yet on server
  newRecord,

  // Modified locally after sync
  updated,

  // Marked for deletion, pending server delete
  deleted,

  // Fully synced with server
  synced,
}

// Local record for Purchase with offline-first support Optimized with proper indexes for high-performance queries
class PurchaseEntity {
  // Local row id
  int id = 0;

  // Server-side ID (null for locally created, not yet synced records)
  String? serverId;

  // Product ID (indexed for fast lookup)
  String productId;

  // Product name (for display purposes)
  String productName;

  // Supplier ID (indexed for filtering)
  String? supplierId;

  // Supplier name (for display purposes)
  String? supplierName;

  // Company ID (indexed for filtering)
  String? companyId;

  // Company name (for display purposes)
  String? companyName;

  // Quantity purchased (base units; may be fractional)
  double quantity;

  // Unit of measurement
  String unit;

  // Purchase price per unit (exclusive COGS — never includes GST)
  double purchasePrice;

  // Sales price per unit
  double salesPrice;

  // Invoice grand total (taxable + GST when applied; else qty * purchasePrice)
  double totalAmount;

  // Production date (optional)
  DateTime? productionDate;

  // Expiry date (optional)
  DateTime? expiryDate;

  // Warranty in months (optional)
  int? warrantyMonths;

  // Notes
  String? notes;

  // ── Purchase GST / ITC snapshot (defaults keep legacy qty×price behaviour) ──
  bool isGstApplied;
  bool isTaxInclusive;
  bool isInterstate;
  double taxableValue;
  double cgstPercent;
  double sgstPercent;
  double igstPercent;
  double otherTaxPercent;
  String? otherTaxName;
  double cgstAmount;
  double sgstAmount;
  double igstAmount;
  double otherTaxAmount;
  double totalTaxAmount;
  String? hsnCode;
  String? supplierGstin;

  // Sync status for delta sync
  PurchaseSyncStatus syncStatus;

  // Created timestamp (indexed for sorting)
  DateTime createdAt;

  // Last update timestamp for conflict resolution
  DateTime updatedAt;

  PurchaseEntity({
    this.serverId,
    required this.productId,
    required this.productName,
    this.supplierId,
    this.supplierName,
    this.companyId,
    this.companyName,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.salesPrice,
    required this.totalAmount,
    this.productionDate,
    this.expiryDate,
    this.warrantyMonths,
    this.notes,
    this.isGstApplied = false,
    this.isTaxInclusive = false,
    this.isInterstate = false,
    this.taxableValue = 0,
    this.cgstPercent = 0,
    this.sgstPercent = 0,
    this.igstPercent = 0,
    this.otherTaxPercent = 0,
    this.otherTaxName,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.otherTaxAmount = 0,
    this.totalTaxAmount = 0,
    this.hsnCode,
    this.supplierGstin,
    this.syncStatus = PurchaseSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display / report total: prefer stored invoice total; legacy fallback qty×price.
  double get displayTotalAmount {
    if (totalAmount > 0) return totalAmount;
    return quantity * purchasePrice;
  }

  // Factory constructor for creating new purchase with defaults
  factory PurchaseEntity.create({
    String? serverId,
    required String productId,
    required String productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    required double quantity,
    required String unit,
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
    PurchaseTaxResult? tax,
    PurchaseSyncStatus syncStatus = PurchaseSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    final taxResult = tax ??
        PurchaseTaxCalculator.calculate(
          quantity: quantity,
          purchasePrice: purchasePrice,
          isGstApplied: false,
        );
    return PurchaseEntity(
      serverId: serverId,
      productId: productId,
      productName: productName,
      supplierId: supplierId,
      supplierName: supplierName,
      companyId: companyId,
      companyName: companyName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      totalAmount: taxResult.totalAmount,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      isGstApplied: taxResult.isGstApplied,
      isTaxInclusive: taxResult.isTaxInclusive,
      isInterstate: taxResult.isInterstate,
      taxableValue: taxResult.taxableValue,
      cgstPercent: taxResult.cgstPercent,
      sgstPercent: taxResult.sgstPercent,
      igstPercent: taxResult.igstPercent,
      otherTaxPercent: taxResult.otherTaxPercent,
      otherTaxName: taxResult.otherTaxName,
      cgstAmount: taxResult.cgstAmount,
      sgstAmount: taxResult.sgstAmount,
      igstAmount: taxResult.igstAmount,
      otherTaxAmount: taxResult.otherTaxAmount,
      totalTaxAmount: taxResult.totalTaxAmount,
      hsnCode: taxResult.hsnCode,
      supplierGstin: taxResult.supplierGstin,
      syncStatus: syncStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create from server response (Firestore document)
  factory PurchaseEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    final quantity = _asDouble(data['quantity']);
    final purchasePrice = _asDouble(data['purchasePrice']);
    final isGstApplied = _asBool(data['isGstApplied']);
    final storedTotal = _asDouble(data['totalAmount']);
    final fallbackTotal = quantity * purchasePrice;
    return PurchaseEntity(
      serverId: data['id'] as String?,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      supplierId: data['supplierId'] as String?,
      supplierName: data['supplierName'] as String?,
      companyId: data['companyId'] as String?,
      companyName: data['companyName'] as String?,
      quantity: quantity,
      unit: data['unit'] as String? ?? 'pcs',
      purchasePrice: purchasePrice,
      salesPrice: _asDouble(data['salesPrice']),
      totalAmount: storedTotal > 0 ? storedTotal : fallbackTotal,
      productionDate: _parseDateTime(data['productionDate']),
      expiryDate: _parseDateTime(data['expiryDate']),
      warrantyMonths: (data['warrantyMonths'] as num?)?.toInt(),
      notes: data['notes'] as String?,
      isGstApplied: isGstApplied,
      isTaxInclusive: _asBool(data['isTaxInclusive']),
      isInterstate: _asBool(data['isInterstate']),
      taxableValue: _asDouble(
        data['taxableValue'],
        isGstApplied ? 0 : fallbackTotal,
      ),
      cgstPercent: _asDouble(data['cgstPercent']),
      sgstPercent: _asDouble(data['sgstPercent']),
      igstPercent: _asDouble(data['igstPercent']),
      otherTaxPercent: _asDouble(data['otherTaxPercent']),
      otherTaxName: data['otherTaxName'] as String?,
      cgstAmount: _asDouble(data['cgstAmount']),
      sgstAmount: _asDouble(data['sgstAmount']),
      igstAmount: _asDouble(data['igstAmount']),
      otherTaxAmount: _asDouble(data['otherTaxAmount']),
      totalTaxAmount: _asDouble(data['totalTaxAmount']),
      hsnCode: data['hsnCode'] as String?,
      supplierGstin: data['supplierGstin'] as String?,
      syncStatus: PurchaseSyncStatus.synced,
      createdAt: _parseDateTime(data['createdAt']) ?? now,
      updatedAt: _parseDateTime(data['updatedAt']) ?? now,
    );
  }

  // Convert to Map for API sync
  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'productId': productId,
      'productName': productName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'companyId': companyId,
      'companyName': companyName,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'totalAmount': totalAmount,
      'productionDate': productionDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'warrantyMonths': warrantyMonths,
      'notes': notes,
      'isGstApplied': isGstApplied,
      'isTaxInclusive': isTaxInclusive,
      'isInterstate': isInterstate,
      'taxableValue': taxableValue,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'igstPercent': igstPercent,
      'otherTaxPercent': otherTaxPercent,
      'otherTaxName': otherTaxName,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'otherTaxAmount': otherTaxAmount,
      'totalTaxAmount': totalTaxAmount,
      'hsnCode': hsnCode,
      'supplierGstin': supplierGstin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert to Map for UI (compatible with existing purchase page)
  Map<String, dynamic> toPurchaseMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'productId': productId,
      'productName': productName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'companyId': companyId,
      'companyName': companyName,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'totalAmount': displayTotalAmount,
      'productionDate': productionDate,
      'expiryDate': expiryDate,
      'warrantyMonths': warrantyMonths,
      'notes': notes,
      'isGstApplied': isGstApplied,
      'isTaxInclusive': isTaxInclusive,
      'isInterstate': isInterstate,
      'taxableValue': taxableValue,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'igstPercent': igstPercent,
      'otherTaxPercent': otherTaxPercent,
      'otherTaxName': otherTaxName,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'otherTaxAmount': otherTaxAmount,
      'totalTaxAmount': totalTaxAmount,
      'hsnCode': hsnCode,
      'supplierGstin': supplierGstin,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == PurchaseSyncStatus.synced,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with modifications
  PurchaseEntity copyWith({
    int? id,
    String? serverId,
    String? productId,
    String? productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    double? quantity,
    String? unit,
    double? purchasePrice,
    double? salesPrice,
    double? totalAmount,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
    bool? isGstApplied,
    bool? isTaxInclusive,
    bool? isInterstate,
    double? taxableValue,
    double? cgstPercent,
    double? sgstPercent,
    double? igstPercent,
    double? otherTaxPercent,
    String? otherTaxName,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? otherTaxAmount,
    double? totalTaxAmount,
    String? hsnCode,
    String? supplierGstin,
    PurchaseSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final entity = PurchaseEntity(
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      notes: notes ?? this.notes,
      isGstApplied: isGstApplied ?? this.isGstApplied,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      isInterstate: isInterstate ?? this.isInterstate,
      taxableValue: taxableValue ?? this.taxableValue,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      igstPercent: igstPercent ?? this.igstPercent,
      otherTaxPercent: otherTaxPercent ?? this.otherTaxPercent,
      otherTaxName: otherTaxName ?? this.otherTaxName,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      otherTaxAmount: otherTaxAmount ?? this.otherTaxAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      hsnCode: hsnCode ?? this.hsnCode,
      supplierGstin: supplierGstin ?? this.supplierGstin,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    entity.id = id ?? this.id;
    return entity;
  }

  // Check if purchase needs sync
  bool get needsSync => syncStatus != PurchaseSyncStatus.synced;

  // Check if purchase is marked for deletion
  bool get isMarkedForDeletion => syncStatus == PurchaseSyncStatus.deleted;

  @override
  String toString() {
    return 'PurchaseEntity(id: $id, serverId: $serverId, product: $productName, qty: $quantity, syncStatus: $syncStatus)';
  }
}
