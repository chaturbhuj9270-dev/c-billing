import 'package:isar_community/isar.dart';

part 'bill_entity.g.dart';

/// Sync status for delta sync logic
enum BillSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,
  
  /// Modified locally after sync
  updated,
  
  /// Marked for deletion, pending server delete
  deleted,
  
  /// Fully synced with server
  synced,
}

/// Payment status of a bill
enum BillPaymentStatus {
  /// Full amount received at time of sale
  paid,

  /// Partial payment received, some amount pending
  partiallyPaid,

  /// No payment received, full amount pending
  pending,
}

/// Embedded entity for bill items (stored within BillEntity)
@embedded
class BillItemEmbedded {
  String? itemId;
  String? productId;
  String? productName;
  double purchasePrice;
  double sellingPrice;
  int quantity;
  double subtotal;
  int returnedQuantity;

  BillItemEmbedded({
    this.itemId,
    this.productId,
    this.productName,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.quantity = 0,
    this.subtotal = 0.0,
    this.returnedQuantity = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': itemId ?? '',
      'productId': productId ?? '',
      'productName': productName ?? '',
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'returnedQuantity': returnedQuantity,
    };
  }

  static BillItemEmbedded fromJson(Map<String, dynamic> json) {
    return BillItemEmbedded(
      itemId: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      returnedQuantity: (json['returnedQuantity'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Isar Collection for Bill with offline-first support
@collection
class BillEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Customer ID (indexed for filtering)
  @Index()
  String? customerId;

  /// Customer name (for display purposes)
  String? customerName;

  /// Customer contact
  String? customerContact;

  /// Bill items (embedded list)
  List<BillItemEmbedded> items;

  /// Total quantity of all items
  int totalQuantity;

  /// Total amount before discount
  double totalAmount;

  /// Discount amount
  double discountAmount;

  /// Discount percentage
  double discountPercent;

  /// Final amount after discount
  double finalAmount;

  /// Bill date
  @Index()
  DateTime billDate;

  /// Notes
  String? notes;

  /// Return status
  bool returnStatus;

  /// Return date
  DateTime? returnDate;

  /// Payment status
  @Enumerated(EnumType.ordinal)
  BillPaymentStatus paymentStatus;

  /// Amount already paid
  double paidAmount;

  /// Amount still pending
  double pendingAmount;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  BillSyncStatus syncStatus;

  /// Created timestamp (indexed for sorting)
  @Index()
  DateTime createdAt;

  /// Last update timestamp
  DateTime updatedAt;

  BillEntity({
    this.serverId,
    this.customerId,
    this.customerName,
    this.customerContact,
    this.items = const [],
    this.totalQuantity = 0,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    this.finalAmount = 0.0,
    required this.billDate,
    this.notes,
    this.returnStatus = false,
    this.returnDate,
    this.paymentStatus = BillPaymentStatus.paid,
    this.paidAmount = 0.0,
    this.pendingAmount = 0.0,
    this.syncStatus = BillSyncStatus.newRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating new bill with defaults
  factory BillEntity.create({
    String? serverId,
    String? customerId,
    String? customerName,
    String? customerContact,
    List<BillItemEmbedded> items = const [],
    int totalQuantity = 0,
    double totalAmount = 0.0,
    double discountAmount = 0.0,
    double discountPercent = 0.0,
    double finalAmount = 0.0,
    DateTime? billDate,
    String? notes,
    bool returnStatus = false,
    DateTime? returnDate,
    BillPaymentStatus paymentStatus = BillPaymentStatus.paid,
    double paidAmount = 0.0,
    double pendingAmount = 0.0,
    BillSyncStatus syncStatus = BillSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return BillEntity(
      serverId: serverId,
      customerId: customerId,
      customerName: customerName,
      customerContact: customerContact,
      items: items,
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountPercent: discountPercent,
      finalAmount: finalAmount,
      billDate: billDate ?? now,
      notes: notes,
      returnStatus: returnStatus,
      returnDate: returnDate,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      syncStatus: syncStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from server response (Firestore document)
  factory BillEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    
    List<BillItemEmbedded> billItems = [];
    if (data['items'] != null) {
      billItems = (data['items'] as List)
          .map((item) => BillItemEmbedded.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return BillEntity(
      serverId: data['id'] as String?,
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String?,
      customerContact: data['customerContact'] as String?,
      items: billItems,
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (data['finalAmount'] as num?)?.toDouble() ?? 0.0,
      billDate: data['billDate'] != null
          ? DateTime.tryParse(data['billDate'].toString()) ?? now
          : now,
      notes: data['notes'] as String?,
      returnStatus: data['returnStatus'] as bool? ?? false,
      returnDate: data['returnDate'] != null
          ? DateTime.tryParse(data['returnDate'].toString())
          : null,
      paymentStatus: _parsePaymentStatus(data['paymentStatus'] as String?),
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (data['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      syncStatus: BillSyncStatus.synced,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? now
          : now,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString()) ?? now
          : now,
    );
  }

  /// Parse payment status from string
  static BillPaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'paid':
        return BillPaymentStatus.paid;
      case 'partiallyPaid':
        return BillPaymentStatus.partiallyPaid;
      case 'pending':
        return BillPaymentStatus.pending;
      default:
        return BillPaymentStatus.paid;
    }
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toBillMap() {
    return {
      'id': serverId ?? '',
      'customerId': customerId,
      'customerName': customerName,
      'customerContact': customerContact,
      'items': items.map((item) => item.toJson()).toList(),
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'finalAmount': finalAmount,
      'billDate': billDate.toIso8601String(),
      'notes': notes,
      'returnStatus': returnStatus,
      'returnDate': returnDate?.toIso8601String(),
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to sync payload (for creating/updating on server)
  Map<String, dynamic> toSyncPayload() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerContact': customerContact,
      'items': items.map((item) => item.toJson()).toList(),
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'finalAmount': finalAmount,
      'billDate': billDate.toIso8601String(),
      'notes': notes,
      'returnStatus': returnStatus,
      'returnDate': returnDate?.toIso8601String(),
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Helper getters for sync status
  bool get needsSync => syncStatus != BillSyncStatus.synced;
  bool get isMarkedForDeletion => syncStatus == BillSyncStatus.deleted;

  /// Copy with modifications
  BillEntity copyWith({
    String? serverId,
    String? customerId,
    String? customerName,
    String? customerContact,
    List<BillItemEmbedded>? items,
    int? totalQuantity,
    double? totalAmount,
    double? discountAmount,
    double? discountPercent,
    double? finalAmount,
    DateTime? billDate,
    String? notes,
    bool? returnStatus,
    DateTime? returnDate,
    BillPaymentStatus? paymentStatus,
    double? paidAmount,
    double? pendingAmount,
    BillSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final entity = BillEntity(
      serverId: serverId ?? this.serverId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      items: items ?? this.items,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      finalAmount: finalAmount ?? this.finalAmount,
      billDate: billDate ?? this.billDate,
      notes: notes ?? this.notes,
      returnStatus: returnStatus ?? this.returnStatus,
      returnDate: returnDate ?? this.returnDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    entity.id = id;
    return entity;
  }
}
