import 'package:isar_community/isar.dart';

part 'product_batch_entity.g.dart';

/// Status of a product batch
enum BatchStatus {
  /// Batch has stock available
  active,

  /// All stock consumed (currentQuantity <= 0)
  exhausted,

  /// Batch has expired (past expiryDate)
  expired,
}

/// Sync status for delta sync logic
/// Only batches with status != SYNCED will be pushed to server
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

/// Isar Collection for Product Batch with offline-first support
/// Tracks individual purchase batches for FIFO/LIFO stock management
/// Supports same product from different companies with different prices
@collection
class ProductBatchEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Product ID (indexed for fast lookup)
  @Index()
  String productId;

  /// Product name (denormalized for display)
  String productName;

  /// Company/Brand ID (indexed for filtering)
  @Index()
  String companyId;

  /// Company/Brand name (denormalized for display)
  String companyName;

  /// Supplier ID
  String supplierId;

  /// Supplier name (denormalized for display)
  String supplierName;

  /// Auto-generated unique batch number (e.g., BATCH1707123456789)
  @Index(unique: true)
  String batchNumber;

  /// Date this batch was purchased
  @Index()
  DateTime purchaseDate;

  /// Purchase price per unit for this batch
  double purchasePrice;

  /// Sales price per unit for this batch
  double salesPrice;

  /// Original quantity when batch was created
  double initialQuantity;

  /// Current remaining quantity in this batch
  double currentQuantity;

  /// Unit of measurement (kg, pcs, ltr, etc.)
  String unit;

  /// Production/manufacturing date (optional)
  DateTime? productionDate;

  /// Expiry date (optional)
  DateTime? expiryDate;

  /// Warranty in months (optional)
  int? warrantyMonths;

  /// Batch status: active, exhausted, expired
  @Index()
  @Enumerated(EnumType.ordinal)
  BatchStatus status;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  BatchSyncStatus syncStatus;

  /// Created timestamp
  @Index()
  DateTime createdAt;

  /// Last update timestamp for conflict resolution
  DateTime updatedAt;

  /// Additional notes
  String? notes;

  /// Reference to the purchase record that created this batch
  String? purchaseId;

  ProductBatchEntity({
    this.serverId,
    required this.productId,
    required this.productName,
    required this.companyId,
    required this.companyName,
    required this.supplierId,
    required this.supplierName,
    required this.batchNumber,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.salesPrice,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.unit,
    this.productionDate,
    this.expiryDate,
    this.warrantyMonths,
    this.status = BatchStatus.active,
    this.syncStatus = BatchSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.purchaseId,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Check if batch has expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if batch stock is exhausted
  bool get isExhausted => currentQuantity <= 0;

  /// Total value of remaining stock at purchase price
  double get totalValue => currentQuantity * purchasePrice;

  /// Total value of remaining stock at sales price
  double get totalSalesValue => currentQuantity * salesPrice;

  /// Profit margin percentage
  double get profitMargin =>
      salesPrice > 0 ? ((salesPrice - purchasePrice) / salesPrice) * 100 : 0;

  /// Quantity sold from this batch
  double get quantitySold => initialQuantity - currentQuantity;

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Factory constructor for creating a new batch with defaults
  factory ProductBatchEntity.create({
    String? serverId,
    required String productId,
    required String productName,
    required String companyId,
    required String companyName,
    required String supplierId,
    required String supplierName,
    String? batchNumber,
    required double quantity,
    required String unit,
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
    String? purchaseId,
    BatchSyncStatus syncStatus = BatchSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return ProductBatchEntity(
      serverId: serverId,
      productId: productId,
      productName: productName,
      companyId: companyId,
      companyName: companyName,
      supplierId: supplierId,
      supplierName: supplierName,
      batchNumber: batchNumber ?? 'BATCH${now.millisecondsSinceEpoch}',
      purchaseDate: now,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      initialQuantity: quantity,
      currentQuantity: quantity,
      unit: unit,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      status: BatchStatus.active,
      syncStatus: syncStatus,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      purchaseId: purchaseId,
    );
  }

  /// Create from server response (Firestore document)
  factory ProductBatchEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return ProductBatchEntity(
      serverId: data['id'] as String?,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      supplierId: data['supplierId'] as String? ?? '',
      supplierName: data['supplierName'] as String? ?? '',
      batchNumber: data['batchNumber'] as String? ?? 'BATCH_UNKNOWN',
      purchaseDate: DateTime.tryParse(data['purchaseDate']?.toString() ?? '') ?? now,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salesPrice: (data['salesPrice'] as num?)?.toDouble() ?? 0.0,
      initialQuantity: (data['initialQuantity'] as num?)?.toDouble() ?? 0.0,
      currentQuantity: (data['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] as String? ?? 'pcs',
      productionDate: data['productionDate'] != null
          ? DateTime.tryParse(data['productionDate'].toString())
          : null,
      expiryDate: data['expiryDate'] != null
          ? DateTime.tryParse(data['expiryDate'].toString())
          : null,
      warrantyMonths: (data['warrantyMonths'] as num?)?.toInt(),
      status: _parseBatchStatus(data['status'] as String?),
      syncStatus: BatchSyncStatus.synced,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? now,
      notes: data['notes'] as String?,
      purchaseId: data['purchaseId'] as String?,
    );
  }

  static BatchStatus _parseBatchStatus(String? status) {
    switch (status) {
      case 'active':
        return BatchStatus.active;
      case 'exhausted':
        return BatchStatus.exhausted;
      case 'expired':
        return BatchStatus.expired;
      default:
        return BatchStatus.active;
    }
  }

  // ==================== SERIALIZATION ====================

  /// Convert to Map for API sync (Firebase)
  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'productId': productId,
      'productName': productName,
      'companyId': companyId,
      'companyName': companyName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'batchNumber': batchNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'initialQuantity': initialQuantity,
      'currentQuantity': currentQuantity,
      'unit': unit,
      'productionDate': productionDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'warrantyMonths': warrantyMonths,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'purchaseId': purchaseId,
    };
  }

  /// Convert to Map for UI display
  Map<String, dynamic> toBatchMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'productId': productId,
      'productName': productName,
      'companyId': companyId,
      'companyName': companyName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'batchNumber': batchNumber,
      'purchaseDate': purchaseDate,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'initialQuantity': initialQuantity,
      'currentQuantity': currentQuantity,
      'unit': unit,
      'productionDate': productionDate,
      'expiryDate': expiryDate,
      'warrantyMonths': warrantyMonths,
      'status': status.name,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == BatchSyncStatus.synced,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'notes': notes,
      'purchaseId': purchaseId,
    };
  }

  // ==================== COPY WITH ====================

  /// Copy with modifications
  ProductBatchEntity copyWith({
    Id? id,
    String? serverId,
    String? productId,
    String? productName,
    String? companyId,
    String? companyName,
    String? supplierId,
    String? supplierName,
    String? batchNumber,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? salesPrice,
    double? initialQuantity,
    double? currentQuantity,
    String? unit,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    BatchStatus? status,
    BatchSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? purchaseId,
  }) {
    final entity = ProductBatchEntity(
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      batchNumber: batchNumber ?? this.batchNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      unit: unit ?? this.unit,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
      purchaseId: purchaseId ?? this.purchaseId,
    );
    entity.id = id ?? this.id;
    return entity;
  }

  /// Check if batch needs sync
  bool get needsSync => syncStatus != BatchSyncStatus.synced;

  /// Check if batch is marked for deletion
  bool get isMarkedForDeletion => syncStatus == BatchSyncStatus.deleted;

  @override
  String toString() {
    return 'ProductBatchEntity(id: $id, serverId: $serverId, product: $productName, '
        'company: $companyName, batch: $batchNumber, stock: $currentQuantity/$initialQuantity, '
        'syncStatus: $syncStatus)';
  }
}
