import 'package:isar_community/isar.dart';

part 'stock_ledger_entity.g.dart';

/// Type of stock transaction
enum TransactionType {
  /// Stock added via purchase
  purchaseIn,

  /// Stock removed via sale
  saleOut,

  /// Manual stock increase (adjustment)
  adjustmentIn,

  /// Manual stock decrease (adjustment)
  adjustmentOut,

  /// Stock returned by customer
  returnIn,

  /// Stock returned to supplier
  returnOut,

  /// Stock marked as damaged
  damaged,

  /// Stock marked as expired
  expired,
}

/// Sync status for ledger entries
enum LedgerSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,

  /// Fully synced with server
  synced,

  /// Marked for deletion, pending server delete
  deleted,
}

/// Isar Collection for Stock Ledger with offline-first support
/// Records every stock movement for complete audit trail
/// Positive quantity = stock IN, Negative quantity = stock OUT
@collection
class StockLedgerEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Product ID (indexed for filtering by product)
  @Index()
  String productId;

  /// Product name (denormalized for display)
  String productName;

  /// Batch ID - which batch was affected (local Isar ID as string)
  @Index()
  String batchId;

  /// Batch number (denormalized for display)
  String batchNumber;

  /// Type of transaction
  @Enumerated(EnumType.ordinal)
  TransactionType transactionType;

  /// Date/time of the transaction
  @Index()
  DateTime transactionDate;

  /// Quantity: positive for IN transactions, negative for OUT transactions
  double quantity;

  /// Running balance of the batch after this transaction
  double balanceAfter;

  /// Reference to source purchase record (nullable)
  String? purchaseId;

  /// Reference to source bill record (nullable)
  String? billId;

  /// Price per unit at the time of transaction
  double pricePerUnit;

  /// Total amount of this transaction (quantity * pricePerUnit)
  double totalAmount;

  /// External reference number (bill number, GRN number, etc.)
  String? reference;

  /// Additional notes
  String? notes;

  /// Created timestamp
  @Index()
  DateTime createdAt;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  LedgerSyncStatus syncStatus;

  StockLedgerEntity({
    this.serverId,
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.batchNumber,
    required this.transactionType,
    required this.transactionDate,
    required this.quantity,
    required this.balanceAfter,
    this.purchaseId,
    this.billId,
    required this.pricePerUnit,
    required this.totalAmount,
    this.reference,
    this.notes,
    required this.createdAt,
    this.syncStatus = LedgerSyncStatus.newRecord,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Check if this is an inflow (stock increase) transaction
  bool get isInflow =>
      transactionType == TransactionType.purchaseIn ||
      transactionType == TransactionType.adjustmentIn ||
      transactionType == TransactionType.returnIn;

  /// Check if this is an outflow (stock decrease) transaction
  bool get isOutflow =>
      transactionType == TransactionType.saleOut ||
      transactionType == TransactionType.adjustmentOut ||
      transactionType == TransactionType.returnOut ||
      transactionType == TransactionType.damaged ||
      transactionType == TransactionType.expired;

  /// Human-readable transaction type label
  String get transactionTypeLabel {
    switch (transactionType) {
      case TransactionType.purchaseIn:
        return 'Purchase';
      case TransactionType.saleOut:
        return 'Sale';
      case TransactionType.adjustmentIn:
        return 'Adjustment (+)';
      case TransactionType.adjustmentOut:
        return 'Adjustment (-)';
      case TransactionType.returnIn:
        return 'Customer Return';
      case TransactionType.returnOut:
        return 'Supplier Return';
      case TransactionType.damaged:
        return 'Damaged';
      case TransactionType.expired:
        return 'Expired';
    }
  }

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Factory constructor for creating a new ledger entry
  factory StockLedgerEntity.create({
    required String productId,
    required String productName,
    required String batchId,
    required String batchNumber,
    required TransactionType transactionType,
    required double quantity,
    required double balanceAfter,
    String? purchaseId,
    String? billId,
    required double pricePerUnit,
    String? reference,
    String? notes,
    LedgerSyncStatus syncStatus = LedgerSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return StockLedgerEntity(
      productId: productId,
      productName: productName,
      batchId: batchId,
      batchNumber: batchNumber,
      transactionType: transactionType,
      transactionDate: now,
      quantity: quantity,
      balanceAfter: balanceAfter,
      purchaseId: purchaseId,
      billId: billId,
      pricePerUnit: pricePerUnit,
      totalAmount: quantity.abs() * pricePerUnit,
      reference: reference,
      notes: notes,
      createdAt: now,
      syncStatus: syncStatus,
    );
  }

  /// Create from server response (Firestore document)
  factory StockLedgerEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return StockLedgerEntity(
      serverId: data['id'] as String?,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      batchId: data['batchId'] as String? ?? '',
      batchNumber: data['batchNumber'] as String? ?? '',
      transactionType: _parseTransactionType(data['transactionType'] as String?),
      transactionDate: DateTime.tryParse(data['transactionDate']?.toString() ?? '') ?? now,
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (data['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      purchaseId: data['purchaseId'] as String?,
      billId: data['billId'] as String?,
      pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      reference: data['reference'] as String?,
      notes: data['notes'] as String?,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? now,
      syncStatus: LedgerSyncStatus.synced,
    );
  }

  static TransactionType _parseTransactionType(String? type) {
    switch (type) {
      case 'purchaseIn':
        return TransactionType.purchaseIn;
      case 'saleOut':
        return TransactionType.saleOut;
      case 'adjustmentIn':
        return TransactionType.adjustmentIn;
      case 'adjustmentOut':
        return TransactionType.adjustmentOut;
      case 'returnIn':
        return TransactionType.returnIn;
      case 'returnOut':
        return TransactionType.returnOut;
      case 'damaged':
        return TransactionType.damaged;
      case 'expired':
        return TransactionType.expired;
      default:
        return TransactionType.purchaseIn;
    }
  }

  // ==================== SERIALIZATION ====================

  /// Convert to Map for API sync (Firebase)
  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'productId': productId,
      'productName': productName,
      'batchId': batchId,
      'batchNumber': batchNumber,
      'transactionType': transactionType.name,
      'transactionDate': transactionDate.toIso8601String(),
      'quantity': quantity,
      'balanceAfter': balanceAfter,
      'purchaseId': purchaseId,
      'billId': billId,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Map for UI display
  Map<String, dynamic> toLedgerMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'productId': productId,
      'productName': productName,
      'batchId': batchId,
      'batchNumber': batchNumber,
      'transactionType': transactionType.name,
      'transactionTypeLabel': transactionTypeLabel,
      'transactionDate': transactionDate,
      'quantity': quantity,
      'balanceAfter': balanceAfter,
      'purchaseId': purchaseId,
      'billId': billId,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'reference': reference,
      'notes': notes,
      'isInflow': isInflow,
      'isOutflow': isOutflow,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == LedgerSyncStatus.synced,
      'createdAt': createdAt,
    };
  }

  /// Check if entry needs sync
  bool get needsSync => syncStatus != LedgerSyncStatus.synced;

  /// Check if entry is marked for deletion
  bool get isMarkedForDeletion => syncStatus == LedgerSyncStatus.deleted;

  @override
  String toString() {
    return 'StockLedgerEntity(id: $id, product: $productName, batch: $batchNumber, '
        'type: ${transactionType.name}, qty: $quantity, balance: $balanceAfter, '
        'syncStatus: $syncStatus)';
  }
}
