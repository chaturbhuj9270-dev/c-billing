import 'package:isar_community/isar.dart';

part 'product_entity.g.dart';

/// Sync status for delta sync logic
/// Only products with status != SYNCED will be pushed to server
enum SyncStatus {
  /// Newly created locally, not yet on server
  newRecord,
  
  /// Modified locally after sync
  updated,
  
  /// Marked for deletion, pending server delete
  deleted,
  
  /// Fully synced with server
  synced,
}

/// Isar Collection for Product with offline-first support
/// Optimized with proper indexes for high-performance queries
@collection
class ProductEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Unique index number for quick lookup (e.g., 101, 102, 103)
  int indexNo;

  /// Product name (indexed for fast search)
  @Index(type: IndexType.value, caseSensitive: false)
  String name;

  /// Company name
  String companyName;

  /// Product category
  String category;

  /// Barcode (indexed for fast lookup)
  @Index(unique: false)
  String? barcode;

  /// Purchase price
  double purchasePrice;

  /// Sales price
  double salesPrice;

  /// Current stock quantity (as int to match domain model)
  int currentStock;

  /// Measurement unit (kg, pcs, ltr, etc.)
  String? unit;

  /// Whether product is active/available
  bool isActive;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  SyncStatus syncStatus;

  /// Last update timestamp for conflict resolution
  @Index()
  DateTime updatedAt;

  /// Created timestamp
  DateTime createdAt;

  /// Optional: Minimum stock level for alerts
  int? minStockLevel;

  /// Optional: Product description
  String? description;

  /// Optional: Product image URL
  String? imageUrl;

  /// Default supplier ID (for auto-population on purchase page)
  String? defaultSupplierId;

  /// Default supplier name (for display)
  String? defaultSupplierName;

  /// CGST percentage for this product
  double cgstPercent;

  /// SGST percentage for this product
  double sgstPercent;

  ProductEntity({
    this.serverId,
    this.indexNo = 0,
    required this.name,
    this.companyName = '',
    this.category = '',
    this.barcode,
    required this.purchasePrice,
    required this.salesPrice,
    this.currentStock = 0,
    this.unit,
    this.isActive = true,
    this.syncStatus = SyncStatus.newRecord,
    required this.updatedAt,
    required this.createdAt,
    this.minStockLevel,
    this.description,
    this.imageUrl,
    this.defaultSupplierId,
    this.defaultSupplierName,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
  });

  /// Factory constructor for creating new product with defaults
  factory ProductEntity.create({
    String? serverId,
    int indexNo = 0,
    required String name,
    String companyName = '',
    String category = '',
    String? barcode,
    required double purchasePrice,
    required double salesPrice,
    int currentStock = 0,
    String? unit,
    bool isActive = true,
    SyncStatus syncStatus = SyncStatus.newRecord,
    String? description,
    String? imageUrl,
    int? minStockLevel,
    String? defaultSupplierId,
    String? defaultSupplierName,
    double cgstPercent = 0.0,
    double sgstPercent = 0.0,
  }) {
    final now = DateTime.now();
    return ProductEntity(
      serverId: serverId,
      indexNo: indexNo,
      name: name,
      companyName: companyName,
      category: category,
      barcode: barcode,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      currentStock: currentStock,
      unit: unit,
      isActive: isActive,
      syncStatus: syncStatus,
      updatedAt: now,
      createdAt: now,
      description: description,
      imageUrl: imageUrl,
      minStockLevel: minStockLevel,
      defaultSupplierId: defaultSupplierId,
      defaultSupplierName: defaultSupplierName,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
    );
  }

  /// Create from server response (Firestore document)
  factory ProductEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return ProductEntity(
      serverId: data['id'] as String?,
      indexNo: (data['indexNo'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      category: data['category'] as String? ?? '',
      barcode: data['barcode'] as String?,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salesPrice: (data['salesPrice'] as num?)?.toDouble() ?? 0.0,
      currentStock: (data['currentStock'] as num?)?.toInt() ?? 0,
      unit: data['unit'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      syncStatus: SyncStatus.synced,
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? now,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? now,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      minStockLevel: (data['minStockLevel'] as num?)?.toInt(),
      defaultSupplierId: data['defaultSupplierId'] as String?,
      defaultSupplierName: data['defaultSupplierName'] as String?,
      cgstPercent: (data['cgstPercent'] as num?)?.toDouble() ?? 0.0,
      sgstPercent: (data['sgstPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to Map for API sync
  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'indexNo': indexNo,
      'name': name,
      'companyName': companyName,
      'category': category,
      'barcode': barcode,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'currentStock': currentStock,
      'unit': unit,
      'isActive': isActive,
      'description': description,
      'imageUrl': imageUrl,
      'minStockLevel': minStockLevel,
      'defaultSupplierId': defaultSupplierId,
      'defaultSupplierName': defaultSupplierName,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain Product map (for use with existing Product class)
  Map<String, dynamic> toProductMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'indexNo': indexNo,
      'name': name,
      'companyName': companyName,
      'category': category,
      'barcode': barcode,
      'purchasePrice': purchasePrice,
      'salesPrice': salesPrice,
      'currentStock': currentStock,
      'unit': unit,
      'isActive': isActive,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == SyncStatus.synced,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
      'description': description,
      'imageUrl': imageUrl,
      'minStockLevel': minStockLevel,
      'defaultSupplierId': defaultSupplierId,
      'defaultSupplierName': defaultSupplierName,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
    };
  }

  /// Copy with modifications (marks as updated if already synced)
  ProductEntity copyWith({
    Id? id,
    String? serverId,
    int? indexNo,
    String? name,
    String? companyName,
    String? category,
    String? barcode,
    double? purchasePrice,
    double? salesPrice,
    int? currentStock,
    String? unit,
    bool? isActive,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? description,
    String? imageUrl,
    int? minStockLevel,
    String? defaultSupplierId,
    String? defaultSupplierName,
    double? cgstPercent,
    double? sgstPercent,
  }) {
    final entity = ProductEntity(
      serverId: serverId ?? this.serverId,
      indexNo: indexNo ?? this.indexNo,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salesPrice: salesPrice ?? this.salesPrice,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      defaultSupplierId: defaultSupplierId ?? this.defaultSupplierId,
      defaultSupplierName: defaultSupplierName ?? this.defaultSupplierName,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
    );
    entity.id = id ?? this.id;
    return entity;
  }

  /// Check if product needs sync
  bool get needsSync => syncStatus != SyncStatus.synced;

  /// Check if product is marked for deletion
  bool get isMarkedForDeletion => syncStatus == SyncStatus.deleted;

  @override
  String toString() {
    return 'ProductEntity(id: $id, serverId: $serverId, name: $name, syncStatus: $syncStatus)';
  }
}
