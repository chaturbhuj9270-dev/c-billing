import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'purchase_batch_entity.g.dart';

/// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Sync status for delta sync logic
enum BatchSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,

  /// Modified locally after sync
  updated,

  /// Marked for deletion, pending server delete
  deleted,

  /// Fully synced with server
  synced,
}

/// Isar Collection for Purchase Batch with offline-first support
/// Implements FIFO inventory management where each purchase creates a unique batch
@collection
class PurchaseBatchEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side batch ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Product ID (indexed for fast lookup)
  @Index()
  String productId;

  /// Product name for quick reference
  String productName;

  /// Company/Brand name
  @Index()
  String companyName;

  /// Model name or variant
  String modelName;

  /// Product category
  String category;

  /// Unique key combining productName + companyName + modelName (lowercase, trimmed)
  /// Used for identifying the same product across batches
  @Index()
  String productUniqueKey;

  /// Purchase price per unit for this batch
  double purchasePrice;

  /// Selling price per unit for this batch
  double sellingPrice;

  /// Original quantity purchased in this batch
  int quantityPurchased;

  /// Remaining quantity available for sale (FIFO tracking)
  int quantityRemaining;

  /// Date when this batch was purchased (indexed for FIFO sorting)
  @Index()
  DateTime purchaseDate;

  /// Supplier ID (optional, indexed)
  @Index()
  String? supplierId;

  /// Supplier name (optional)
  String? supplierName;

  /// Unit of measurement
  String unit;

  /// Expiry date (optional, indexed for expiry tracking)
  @Index()
  DateTime? expiryDate;

  /// Production/Manufacturing date (optional)
  DateTime? productionDate;

  /// Warranty in months (optional)
  int? warrantyMonths;

  /// Notes for this batch
  String? notes;

  /// Whether this batch is fully consumed (quantityRemaining == 0)
  @Index()
  bool isConsumed;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  BatchSyncStatus syncStatus;

  /// Created timestamp
  @Index()
  DateTime createdAt;

  /// Last update timestamp
  DateTime updatedAt;

  PurchaseBatchEntity({
    this.serverId,
    required this.productId,
    required this.productName,
    required this.companyName,
    this.modelName = '',
    this.category = '',
    required this.productUniqueKey,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantityPurchased,
    required this.quantityRemaining,
    required this.purchaseDate,
    this.supplierId,
    this.supplierName,
    this.unit = 'pcs',
    this.expiryDate,
    this.productionDate,
    this.warrantyMonths,
    this.notes,
    this.isConsumed = false,
    this.syncStatus = BatchSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating new batch with defaults
  factory PurchaseBatchEntity.create({
    String? serverId,
    required String productId,
    required String productName,
    required String companyName,
    String modelName = '',
    String category = '',
    required double purchasePrice,
    required double sellingPrice,
    required int quantity,
    DateTime? purchaseDate,
    String? supplierId,
    String? supplierName,
    String unit = 'pcs',
    DateTime? expiryDate,
    DateTime? productionDate,
    int? warrantyMonths,
    String? notes,
    BatchSyncStatus syncStatus = BatchSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    final uniqueKey =
        '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';

    return PurchaseBatchEntity(
      serverId: serverId,
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      category: category,
      productUniqueKey: uniqueKey,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      quantityPurchased: quantity,
      quantityRemaining: quantity,
      purchaseDate: purchaseDate ?? now,
      supplierId: supplierId,
      supplierName: supplierName,
      unit: unit,
      expiryDate: expiryDate,
      productionDate: productionDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      isConsumed: false,
      syncStatus: syncStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from server response (Firestore document)
  factory PurchaseBatchEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    final productName = data['productName'] as String? ?? '';
    final companyName = data['companyName'] as String? ?? '';
    final modelName = data['modelName'] as String? ?? '';
    final uniqueKey =
        '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';

    return PurchaseBatchEntity(
      serverId: data['batchId'] as String? ?? data['id'] as String?,
      productId: data['productId'] as String? ?? '',
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      category: data['category'] as String? ?? '',
      productUniqueKey: data['productUniqueKey'] as String? ?? uniqueKey,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantityPurchased: (data['quantityPurchased'] as num?)?.toInt() ?? 0,
      quantityRemaining: (data['quantityRemaining'] as num?)?.toInt() ?? 0,
      purchaseDate: _parseDateTime(data['purchaseDate']) ?? now,
      supplierId: data['supplierId'] as String?,
      supplierName: data['supplierName'] as String?,
      unit: data['unit'] as String? ?? 'pcs',
      expiryDate: _parseDateTime(data['expiryDate']),
      productionDate: _parseDateTime(data['productionDate']),
      warrantyMonths: (data['warrantyMonths'] as num?)?.toInt(),
      notes: data['notes'] as String?,
      isConsumed: data['isConsumed'] as bool? ?? false,
      syncStatus: BatchSyncStatus.synced,
      createdAt: _parseDateTime(data['createdAt']) ?? now,
      updatedAt: _parseDateTime(data['updatedAt']) ?? now,
    );
  }

  /// Convert to Map for API sync
  Map<String, dynamic> toSyncPayload() {
    return {
      'batchId': serverId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'category': category,
      'productUniqueKey': productUniqueKey,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantityPurchased': quantityPurchased,
      'quantityRemaining': quantityRemaining,
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'unit': unit,
      'expiryDate': expiryDate?.toIso8601String(),
      'productionDate': productionDate?.toIso8601String(),
      'warrantyMonths': warrantyMonths,
      'notes': notes,
      'isConsumed': isConsumed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Map for UI
  Map<String, dynamic> toBatchMap() {
    return {
      'batchId': serverId ?? 'local_$id',
      'localId': id,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'category': category,
      'productUniqueKey': productUniqueKey,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantityPurchased': quantityPurchased,
      'quantityRemaining': quantityRemaining,
      'quantitySold': quantityPurchased - quantityRemaining,
      'purchaseDate': purchaseDate,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'unit': unit,
      'expiryDate': expiryDate,
      'productionDate': productionDate,
      'warrantyMonths': warrantyMonths,
      'notes': notes,
      'isConsumed': isConsumed,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == BatchSyncStatus.synced,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalPurchaseValue': purchasePrice * quantityPurchased,
      'remainingValue': purchasePrice * quantityRemaining,
    };
  }

  /// Copy with modifications
  PurchaseBatchEntity copyWith({
    Id? id,
    String? serverId,
    String? productId,
    String? productName,
    String? companyName,
    String? modelName,
    String? category,
    String? productUniqueKey,
    double? purchasePrice,
    double? sellingPrice,
    int? quantityPurchased,
    int? quantityRemaining,
    DateTime? purchaseDate,
    String? supplierId,
    String? supplierName,
    String? unit,
    DateTime? expiryDate,
    DateTime? productionDate,
    int? warrantyMonths,
    String? notes,
    bool? isConsumed,
    BatchSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final entity = PurchaseBatchEntity(
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      modelName: modelName ?? this.modelName,
      category: category ?? this.category,
      productUniqueKey: productUniqueKey ?? this.productUniqueKey,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantityPurchased: quantityPurchased ?? this.quantityPurchased,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      productionDate: productionDate ?? this.productionDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      notes: notes ?? this.notes,
      isConsumed: isConsumed ?? this.isConsumed,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    entity.id = id ?? this.id;
    return entity;
  }

  /// Check if batch needs sync
  bool get needsSync => syncStatus != BatchSyncStatus.synced;

  /// Check if batch is marked for deletion
  bool get isMarkedForDeletion => syncStatus == BatchSyncStatus.deleted;

  /// Check if batch has stock available
  bool get hasStock => quantityRemaining > 0;

  @override
  String toString() {
    return 'PurchaseBatchEntity(id: $id, serverId: $serverId, product: $productName, company: $companyName, remaining: $quantityRemaining/$quantityPurchased, syncStatus: $syncStatus)';
  }
}
