import 'package:isar_community/isar.dart';

part 'stock_ledger_entity.g.dart';

/// Type of ledger transaction
enum LedgerTransactionType {
  /// Stock increased due to purchase
  PURCHASE,
  
  /// Stock decreased due to sale
  SALE,
  
  /// Stock adjustment (manual correction)
  ADJUSTMENT,
  
  /// Stock returned from customer
  SALE_RETURN,
  
  /// Stock returned to supplier
  PURCHASE_RETURN,
  
  /// Stock transferred between locations
  TRANSFER,
  
  /// Initial stock entry
  OPENING_STOCK,
}

/// Sync status for delta sync logic
enum LedgerSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,
  
  /// Modified locally after sync
  updated,
  
  /// Marked for deletion, pending server delete
  deleted,
  
  /// Fully synced with server
  synced,
}

/// Isar Collection for Stock Ledger with offline-first support
/// Tracks all stock movements with batch reference for COGS calculation
@collection
class StockLedgerEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ledger ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Product ID (indexed for fast lookup)
  @Index()
  String productId;

  /// Product name for quick reference
  String productName;

  /// Company/Brand name
  String companyName;

  /// Model name or variant
  String modelName;

  /// Unique key combining productName + companyName + modelName
  @Index()
  String productUniqueKey;

  /// Batch ID this transaction belongs to (for FIFO tracking)
  @Index()
  String batchId;

  /// Local batch ID (Isar ID of the batch)
  int? localBatchId;

  /// Type of transaction
  @Index()
  @Enumerated(EnumType.ordinal)
  LedgerTransactionType ledgerType;

  /// Reference ID (e.g., Bill ID for sales, Purchase ID for purchases)
  @Index()
  String referenceId;

  /// Reference type (BILL, PURCHASE, ADJUSTMENT, etc.)
  String referenceType;

  /// Quantity moved in this transaction (always positive)
  int quantity;

  /// Cost price per unit from the batch (for COGS calculation)
  double costPrice;

  /// Selling price per unit (for sales transactions)
  double sellingPrice;

  /// Total cost = costPrice * quantity
  double totalCost;

  /// Total revenue = sellingPrice * quantity (for sales)
  double totalRevenue;

  /// Profit for this transaction (for sales)
  double profit;

  /// Balance quantity after this transaction
  int balanceQuantity;

  /// Balance value after this transaction
  double balanceValue;

  /// Date of transaction (indexed for sorting and filtering)
  @Index()
  DateTime transactionDate;

  /// Notes for this entry
  String? notes;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  LedgerSyncStatus syncStatus;

  /// Created timestamp
  @Index()
  DateTime createdAt;

  StockLedgerEntity({
    this.serverId,
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.productUniqueKey,
    required this.batchId,
    this.localBatchId,
    required this.ledgerType,
    required this.referenceId,
    this.referenceType = '',
    required this.quantity,
    required this.costPrice,
    this.sellingPrice = 0.0,
    required this.totalCost,
    this.totalRevenue = 0.0,
    this.profit = 0.0,
    required this.balanceQuantity,
    required this.balanceValue,
    required this.transactionDate,
    this.notes,
    this.syncStatus = LedgerSyncStatus.newRecord,
    required this.createdAt,
  });

  /// Factory for creating a PURCHASE ledger entry
  factory StockLedgerEntity.forPurchase({
    String? serverId,
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required String purchaseReferenceId,
    required int quantity,
    required double costPrice,
    required int balanceQuantity,
    required double balanceValue,
    String? notes,
    LedgerSyncStatus syncStatus = LedgerSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    final uniqueKey = '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';
    
    return StockLedgerEntity(
      serverId: serverId,
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      productUniqueKey: uniqueKey,
      batchId: batchId,
      localBatchId: localBatchId,
      ledgerType: LedgerTransactionType.PURCHASE,
      referenceId: purchaseReferenceId,
      referenceType: 'PURCHASE',
      quantity: quantity,
      costPrice: costPrice,
      sellingPrice: 0.0,
      totalCost: costPrice * quantity,
      totalRevenue: 0.0,
      profit: 0.0,
      balanceQuantity: balanceQuantity,
      balanceValue: balanceValue,
      transactionDate: now,
      notes: notes,
      syncStatus: syncStatus,
      createdAt: now,
    );
  }

  /// Factory for creating a SALE ledger entry
  factory StockLedgerEntity.forSale({
    String? serverId,
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required String billId,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
    required int balanceQuantity,
    required double balanceValue,
    String? notes,
    LedgerSyncStatus syncStatus = LedgerSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    final uniqueKey = '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';
    final totalCost = costPrice * quantity;
    final totalRevenue = sellingPrice * quantity;
    
    return StockLedgerEntity(
      serverId: serverId,
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      productUniqueKey: uniqueKey,
      batchId: batchId,
      localBatchId: localBatchId,
      ledgerType: LedgerTransactionType.SALE,
      referenceId: billId,
      referenceType: 'BILL',
      quantity: quantity,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      totalCost: totalCost,
      totalRevenue: totalRevenue,
      profit: totalRevenue - totalCost,
      balanceQuantity: balanceQuantity,
      balanceValue: balanceValue,
      transactionDate: now,
      notes: notes,
      syncStatus: syncStatus,
      createdAt: now,
    );
  }

  /// Factory for creating a SALE_RETURN ledger entry
  factory StockLedgerEntity.forSaleReturn({
    String? serverId,
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required String returnReferenceId,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
    required int balanceQuantity,
    required double balanceValue,
    String? notes,
    LedgerSyncStatus syncStatus = LedgerSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    final uniqueKey = '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';
    final totalCost = costPrice * quantity;
    final totalRevenue = sellingPrice * quantity;
    
    return StockLedgerEntity(
      serverId: serverId,
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      productUniqueKey: uniqueKey,
      batchId: batchId,
      localBatchId: localBatchId,
      ledgerType: LedgerTransactionType.SALE_RETURN,
      referenceId: returnReferenceId,
      referenceType: 'RETURN',
      quantity: quantity,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      totalCost: totalCost,
      totalRevenue: totalRevenue,
      profit: -(totalRevenue - totalCost), // Negative profit for returns
      balanceQuantity: balanceQuantity,
      balanceValue: balanceValue,
      transactionDate: now,
      notes: notes,
      syncStatus: syncStatus,
      createdAt: now,
    );
  }

  /// Create from server response (Firestore document)
  factory StockLedgerEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    final productName = data['productName'] as String? ?? '';
    final companyName = data['companyName'] as String? ?? '';
    final modelName = data['modelName'] as String? ?? '';
    final uniqueKey = '${productName.toLowerCase().trim()}_${companyName.toLowerCase().trim()}_${modelName.toLowerCase().trim()}';
    
    LedgerTransactionType ledgerType;
    final typeString = data['ledgerType'] as String? ?? 'ADJUSTMENT';
    try {
      ledgerType = LedgerTransactionType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => LedgerTransactionType.ADJUSTMENT,
      );
    } catch (_) {
      ledgerType = LedgerTransactionType.ADJUSTMENT;
    }
    
    return StockLedgerEntity(
      serverId: data['ledgerId'] as String? ?? data['id'] as String?,
      productId: data['productId'] as String? ?? '',
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      productUniqueKey: data['productUniqueKey'] as String? ?? uniqueKey,
      batchId: data['batchId'] as String? ?? '',
      localBatchId: (data['localBatchId'] as num?)?.toInt(),
      ledgerType: ledgerType,
      referenceId: data['referenceId'] as String? ?? '',
      referenceType: data['referenceType'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      profit: (data['profit'] as num?)?.toDouble() ?? 0.0,
      balanceQuantity: (data['balanceQuantity'] as num?)?.toInt() ?? 0,
      balanceValue: (data['balanceValue'] as num?)?.toDouble() ?? 0.0,
      transactionDate: DateTime.tryParse(data['transactionDate']?.toString() ?? '') ?? now,
      notes: data['notes'] as String?,
      syncStatus: LedgerSyncStatus.synced,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? now,
    );
  }

  /// Convert to Map for API sync
  Map<String, dynamic> toSyncPayload() {
    return {
      'ledgerId': serverId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'productUniqueKey': productUniqueKey,
      'batchId': batchId,
      'localBatchId': localBatchId,
      'ledgerType': ledgerType.name,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'totalCost': totalCost,
      'totalRevenue': totalRevenue,
      'profit': profit,
      'balanceQuantity': balanceQuantity,
      'balanceValue': balanceValue,
      'transactionDate': transactionDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Map for UI
  Map<String, dynamic> toLedgerMap() {
    return {
      'ledgerId': serverId ?? 'local_$id',
      'localId': id,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'productUniqueKey': productUniqueKey,
      'batchId': batchId,
      'localBatchId': localBatchId,
      'ledgerType': ledgerType.name,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'totalCost': totalCost,
      'totalRevenue': totalRevenue,
      'profit': profit,
      'balanceQuantity': balanceQuantity,
      'balanceValue': balanceValue,
      'transactionDate': transactionDate,
      'notes': notes,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == LedgerSyncStatus.synced,
      'createdAt': createdAt,
      'isInbound': ledgerType == LedgerTransactionType.PURCHASE ||
                  ledgerType == LedgerTransactionType.SALE_RETURN ||
                  ledgerType == LedgerTransactionType.OPENING_STOCK,
      'isOutbound': ledgerType == LedgerTransactionType.SALE ||
                   ledgerType == LedgerTransactionType.PURCHASE_RETURN,
    };
  }

  /// Copy with modifications
  StockLedgerEntity copyWith({
    Id? id,
    String? serverId,
    String? productId,
    String? productName,
    String? companyName,
    String? modelName,
    String? productUniqueKey,
    String? batchId,
    int? localBatchId,
    LedgerTransactionType? ledgerType,
    String? referenceId,
    String? referenceType,
    int? quantity,
    double? costPrice,
    double? sellingPrice,
    double? totalCost,
    double? totalRevenue,
    double? profit,
    int? balanceQuantity,
    double? balanceValue,
    DateTime? transactionDate,
    String? notes,
    LedgerSyncStatus? syncStatus,
    DateTime? createdAt,
  }) {
    final entity = StockLedgerEntity(
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      modelName: modelName ?? this.modelName,
      productUniqueKey: productUniqueKey ?? this.productUniqueKey,
      batchId: batchId ?? this.batchId,
      localBatchId: localBatchId ?? this.localBatchId,
      ledgerType: ledgerType ?? this.ledgerType,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      totalCost: totalCost ?? this.totalCost,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      profit: profit ?? this.profit,
      balanceQuantity: balanceQuantity ?? this.balanceQuantity,
      balanceValue: balanceValue ?? this.balanceValue,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
    entity.id = id ?? this.id;
    return entity;
  }

  /// Check if ledger entry needs sync
  bool get needsSync => syncStatus != LedgerSyncStatus.synced;

  /// Check if ledger is marked for deletion
  bool get isMarkedForDeletion => syncStatus == LedgerSyncStatus.deleted;

  /// Check if this is an inbound transaction (increases stock)
  bool get isInbound => 
      ledgerType == LedgerTransactionType.PURCHASE ||
      ledgerType == LedgerTransactionType.SALE_RETURN ||
      ledgerType == LedgerTransactionType.OPENING_STOCK;

  /// Check if this is an outbound transaction (decreases stock)
  bool get isOutbound =>
      ledgerType == LedgerTransactionType.SALE ||
      ledgerType == LedgerTransactionType.PURCHASE_RETURN;

  @override
  String toString() {
    return 'StockLedgerEntity(id: $id, type: $ledgerType, product: $productName, qty: $quantity, cost: $totalCost, syncStatus: $syncStatus)';
  }
}
