/// Represents a purchase return transaction.
/// A return deducts stock from the latest available batches (reverse FIFO)
/// and credits the supplier.
class PurchaseReturn {
  final String id;
  final String supplierId;
  final String supplierName;
  final DateTime returnDate;
  final double totalAmount;
  final String reason;
  final String status; // 'completed', 'pending', 'cancelled'
  final List<PurchaseReturnItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseReturn({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.returnDate,
    required this.totalAmount,
    this.reason = '',
    this.status = 'completed',
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (s, i) => s + i.quantity);

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) =>
                PurchaseReturnItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PurchaseReturn(
      id: (json['id'] ?? '') as String,
      supplierId: (json['supplierId'] ?? '') as String,
      supplierName: (json['supplierName'] ?? '') as String,
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'] as String)
          : DateTime.now(),
      totalAmount: ((json['totalAmount'] ?? 0) as num).toDouble(),
      reason: (json['reason'] ?? '') as String,
      status: (json['status'] ?? 'completed') as String,
      items: itemsList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'returnDate': returnDate.toIso8601String(),
      'totalAmount': totalAmount,
      'reason': reason,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PurchaseReturn copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    DateTime? returnDate,
    double? totalAmount,
    String? reason,
    String? status,
    List<PurchaseReturnItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      returnDate: returnDate ?? this.returnDate,
      totalAmount: totalAmount ?? this.totalAmount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a single item in a purchase return.
class PurchaseReturnItem {
  final String id;
  final String purchaseReturnId;
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final String batchId;
  final int localBatchId;
  final int quantity;
  final double rate;
  final double amount;
  final DateTime? purchaseDate;

  PurchaseReturnItem({
    required this.id,
    this.purchaseReturnId = '',
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.batchId,
    this.localBatchId = 0,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.purchaseDate,
  });

  factory PurchaseReturnItem.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItem(
      id: (json['id'] ?? '') as String,
      purchaseReturnId: (json['purchaseReturnId'] ?? '') as String,
      productId: (json['productId'] ?? '') as String,
      productName: (json['productName'] ?? '') as String,
      companyName: (json['companyName'] ?? '') as String,
      modelName: (json['modelName'] ?? '') as String,
      batchId: (json['batchId'] ?? '') as String,
      localBatchId: (json['localBatchId'] ?? 0) as int,
      quantity: (json['quantity'] ?? 0) as int,
      rate: ((json['rate'] ?? 0) as num).toDouble(),
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseReturnId': purchaseReturnId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'batchId': batchId,
      'localBatchId': localBatchId,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'purchaseDate': purchaseDate?.toIso8601String(),
    };
  }
}
