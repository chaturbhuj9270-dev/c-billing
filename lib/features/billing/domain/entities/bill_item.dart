/// Represents an individual item in a bill
class BillItem {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final double
  purchasePrice; // Cost price at time of sale for profit calculation
  final double sellingPrice;
  final int quantity;
  final double subtotal;
  final int returnedQuantity; // Track how many units have been returned

  BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    this.purchasePrice = 0.0,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
    this.returnedQuantity = 0,
  });

  /// Calculate profit for this item (before any bill-level discount)
  double get itemProfit => (sellingPrice - purchasePrice) * quantity;

  /// Get remaining quantity that can still be returned
  int get remainingQuantity => quantity - returnedQuantity;

  /// Check if this item is fully returned
  bool get isFullyReturned => returnedQuantity >= quantity;

  /// Check if this item has been partially returned
  bool get isPartiallyReturned =>
      returnedQuantity > 0 && returnedQuantity < quantity;

  /// Factory constructor to create from JSON (for Firebase)
  factory BillItem.fromJson(Map<String, dynamic> json) {
    try {
      return BillItem(
        id: (json['id'] ?? '') as String,
        billId: (json['billId'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        productName: (json['productName'] ?? '') as String,
        purchasePrice: ((json['purchasePrice'] ?? 0) as num).toDouble(),
        sellingPrice: ((json['sellingPrice'] ?? 0) as num).toDouble(),
        quantity: (json['quantity'] ?? 0) as int,
        subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
        returnedQuantity: (json['returnedQuantity'] ?? 0) as int,
      );
    } catch (e) {
      print('[ERROR] Failed to parse BillItem from JSON: $json');
      print('[ERROR] Error details: $e');
      return BillItem(
        id: json['id']?.toString() ?? '',
        billId: json['billId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Unknown Product',
        purchasePrice: 0.0,
        sellingPrice: 0.0,
        quantity: 0,
        subtotal: 0.0,
        returnedQuantity: 0,
      );
    }
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billId': billId,
      'productId': productId,
      'productName': productName,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'returnedQuantity': returnedQuantity,
    };
  }

  /// Copy with modifications
  BillItem copyWith({
    String? id,
    String? billId,
    String? productId,
    String? productName,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    double? subtotal,
    int? returnedQuantity,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    );
  }

  /// Create a bill item with auto-calculated subtotal
  static BillItem create({
    String id = '',
    String billId = '',
    required String productId,
    required String productName,
    double purchasePrice = 0.0,
    required double sellingPrice,
    required int quantity,
    int returnedQuantity = 0,
  }) {
    return BillItem(
      id: id,
      billId: billId,
      productId: productId,
      productName: productName,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      subtotal: sellingPrice * quantity,
      returnedQuantity: returnedQuantity,
    );
  }

  @override
  String toString() {
    return 'BillItem(id: $id, productName: $productName, qty: $quantity, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillItem &&
        other.id == id &&
        other.billId == billId &&
        other.productId == productId;
  }

  @override
  int get hashCode => id.hashCode ^ billId.hashCode ^ productId.hashCode;
}
