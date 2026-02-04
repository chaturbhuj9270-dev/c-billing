/// Represents an individual item in a bill
class BillItem {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final double sellingPrice;
  final int quantity;
  final double subtotal;

  BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
  });

  /// Factory constructor to create from JSON (for Firebase)
  factory BillItem.fromJson(Map<String, dynamic> json) {
    try {
      return BillItem(
        id: (json['id'] ?? '') as String,
        billId: (json['billId'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        productName: (json['productName'] ?? '') as String,
        sellingPrice: ((json['sellingPrice'] ?? 0) as num).toDouble(),
        quantity: (json['quantity'] ?? 0) as int,
        subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse BillItem from JSON: $json');
      print('[ERROR] Error details: $e');
      return BillItem(
        id: json['id']?.toString() ?? '',
        billId: json['billId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Unknown Product',
        sellingPrice: 0.0,
        quantity: 0,
        subtotal: 0.0,
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
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  /// Copy with modifications
  BillItem copyWith({
    String? id,
    String? billId,
    String? productId,
    String? productName,
    double? sellingPrice,
    int? quantity,
    double? subtotal,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  /// Create a bill item with auto-calculated subtotal
  static BillItem create({
    String id = '',
    String billId = '',
    required String productId,
    required String productName,
    required double sellingPrice,
    required int quantity,
  }) {
    return BillItem(
      id: id,
      billId: billId,
      productId: productId,
      productName: productName,
      sellingPrice: sellingPrice,
      quantity: quantity,
      subtotal: sellingPrice * quantity,
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
