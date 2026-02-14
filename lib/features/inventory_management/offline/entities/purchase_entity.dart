import 'package:isar_community/isar.dart';

part 'purchase_entity.g.dart';

/// Sync status for delta sync logic
/// Only purchases with status != SYNCED will be pushed to server
enum PurchaseSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,
  
  /// Modified locally after sync
  updated,
  
  /// Marked for deletion, pending server delete
  deleted,
  
  /// Fully synced with server
  synced,
}

/// Isar Collection for Purchase with offline-first support
/// Optimized with proper indexes for high-performance queries
@collection
class PurchaseEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Product ID (indexed for fast lookup)
  @Index()
  String productId;

  /// Product name (for display purposes)
  String productName;

  /// Supplier ID (indexed for filtering)
  @Index()
  String? supplierId;

  /// Supplier name (for display purposes)
  String? supplierName;

  /// Company ID (indexed for filtering)
  @Index()
  String? companyId;

  /// Company name (for display purposes)
  String? companyName;

  /// Quantity purchased
  int quantity;

  /// Unit of measurement
  String unit;

  /// Purchase price per unit
  double purchasePrice;

  /// Sales price per unit
  double salesPrice;

  /// Total amount (quantity * purchasePrice)
  double totalAmount;

  /// Production date (optional)
  DateTime? productionDate;

  /// Expiry date (optional)
  DateTime? expiryDate;

  /// Warranty in months (optional)
  int? warrantyMonths;

  /// Notes
  String? notes;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  PurchaseSyncStatus syncStatus;

  /// Created timestamp (indexed for sorting)
  @Index()
  DateTime createdAt;

  /// Last update timestamp for conflict resolution
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
    this.syncStatus = PurchaseSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating new purchase with defaults
  factory PurchaseEntity.create({
    String? serverId,
    required String productId,
    required String productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    required int quantity,
    required String unit,
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
    PurchaseSyncStatus syncStatus = PurchaseSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
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
      totalAmount: quantity * purchasePrice,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: syncStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from server response (Firestore document)
  factory PurchaseEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return PurchaseEntity(
      serverId: data['id'] as String?,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      supplierId: data['supplierId'] as String?,
      supplierName: data['supplierName'] as String?,
      companyId: data['companyId'] as String?,
      companyName: data['companyName'] as String?,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unit: data['unit'] as String? ?? 'pcs',
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salesPrice: (data['salesPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      productionDate: data['productionDate'] != null
          ? DateTime.tryParse(data['productionDate'].toString())
          : null,
      expiryDate: data['expiryDate'] != null
          ? DateTime.tryParse(data['expiryDate'].toString())
          : null,
      warrantyMonths: (data['warrantyMonths'] as num?)?.toInt(),
      notes: data['notes'] as String?,
      syncStatus: PurchaseSyncStatus.synced,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  /// Convert to Map for API sync
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Map for UI (compatible with existing purchase page)
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
      'totalAmount': totalAmount,
      'productionDate': productionDate,
      'expiryDate': expiryDate,
      'warrantyMonths': warrantyMonths,
      'notes': notes,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == PurchaseSyncStatus.synced,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copy with modifications
  PurchaseEntity copyWith({
    Id? id,
    String? serverId,
    String? productId,
    String? productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    int? quantity,
    String? unit,
    double? purchasePrice,
    double? salesPrice,
    double? totalAmount,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
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
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    entity.id = id ?? this.id;
    return entity;
  }

  /// Check if purchase needs sync
  bool get needsSync => syncStatus != PurchaseSyncStatus.synced;

  /// Check if purchase is marked for deletion
  bool get isMarkedForDeletion => syncStatus == PurchaseSyncStatus.deleted;

  @override
  String toString() {
    return 'PurchaseEntity(id: $id, serverId: $serverId, product: $productName, qty: $quantity, syncStatus: $syncStatus)';
  }
}
