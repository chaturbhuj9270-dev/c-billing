import 'package:isar_community/isar.dart';

part 'customer_transaction_entity.g.dart';

/// Type of transaction
enum TransactionType {
  /// Payment received from customer
  payment,

  /// Bill created (increases pending)
  billCreated,

  /// Bill returned (decreases pending)
  billReturn,

  /// Adjustment (manual correction)
  adjustment,
}

/// Sync status for delta sync
enum TransactionSyncStatus {
  /// Newly created locally
  newRecord,

  /// Modified locally after sync
  updated,

  /// Marked for deletion
  deleted,

  /// Fully synced with server
  synced,
}

/// Isar Collection for Customer Transactions
/// Tracks all payment and billing transactions for a customer
@collection
class CustomerTransactionEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID
  @Index()
  String? serverId;

  /// Customer ID (indexed for fast lookup)
  @Index()
  String customerId;

  /// Customer name (for display)
  String customerName;

  /// Transaction type
  @Enumerated(EnumType.ordinal)
  TransactionType transactionType;

  /// Amount of transaction (positive for payment, negative for bill)
  double amount;

  /// Running balance after this transaction
  double balanceAfter;

  /// Reference ID (bill ID, event ID, etc.)
  String? referenceId;

  /// Reference type (bill, event_order, manual)
  String? referenceType;

  /// Description/notes
  String? description;

  /// Payment method (cash, upi, bank, card, etc.)
  String? paymentMethod;

  /// Transaction date
  @Index()
  DateTime transactionDate;

  /// Sync status
  @Enumerated(EnumType.ordinal)
  TransactionSyncStatus syncStatus;

  /// Created timestamp
  @Index()
  DateTime createdAt;

  /// Updated timestamp
  DateTime updatedAt;

  CustomerTransactionEntity({
    this.serverId,
    required this.customerId,
    required this.customerName,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    this.referenceId,
    this.referenceType,
    this.description,
    this.paymentMethod,
    required this.transactionDate,
    this.syncStatus = TransactionSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for creating a new payment transaction
  factory CustomerTransactionEntity.payment({
    required String customerId,
    required String customerName,
    required double amount,
    required double balanceAfter,
    String? description,
    String? paymentMethod,
    DateTime? transactionDate,
  }) {
    final now = DateTime.now();
    return CustomerTransactionEntity(
      customerId: customerId,
      customerName: customerName,
      transactionType: TransactionType.payment,
      amount: amount,
      balanceAfter: balanceAfter,
      description: description,
      paymentMethod: paymentMethod,
      transactionDate: transactionDate ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Factory for creating a bill transaction
  factory CustomerTransactionEntity.bill({
    required String customerId,
    required String customerName,
    required double amount,
    required double balanceAfter,
    required String billId,
    String? description,
  }) {
    final now = DateTime.now();
    return CustomerTransactionEntity(
      customerId: customerId,
      customerName: customerName,
      transactionType: TransactionType.billCreated,
      amount: amount,
      balanceAfter: balanceAfter,
      referenceId: billId,
      referenceType: 'bill',
      description: description,
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to map for API
  Map<String, dynamic> toJson() {
    return {
      'id': serverId,
      'customerId': customerId,
      'customerName': customerName,
      'transactionType': transactionType.index,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from API response
  static CustomerTransactionEntity fromJson(Map<String, dynamic> json) {
    return CustomerTransactionEntity(
      serverId: json['id'] as String?,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      transactionType:
          TransactionType.values[json['transactionType'] as int? ?? 0],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      description: json['description'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'] as String)
          : DateTime.now(),
      syncStatus: TransactionSyncStatus.synced,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
