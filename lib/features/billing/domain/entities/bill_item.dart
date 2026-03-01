/// Represents an individual item in a bill
class BillItem {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final String? companyName; // Product company/brand name
  final double
  purchasePrice; // Cost price at time of sale for profit calculation
  final double sellingPrice;
  final double
  quantity; // Changed to double to support decimal quantities (e.g., 0.5 kg)
  final double subtotal;
  final double
  returnedQuantity; // Track how many units have been returned (changed to double)
  final double cgstPercent; // Per-product CGST percentage
  final double sgstPercent; // Per-product SGST percentage
  final String? hsnCode; // HSN code for GST compliance
  final String? unit; // Base unit (kg, ltr, pcs, etc.)
  final String? sellUnit; // Unit used for sale (kg, gm, ltr, ml, pcs)

  BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    this.companyName,
    this.purchasePrice = 0.0,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
    this.returnedQuantity = 0,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
    this.unit,
    this.sellUnit,
  });

  /// CGST amount computed from subtotal
  double get cgstAmount => subtotal * cgstPercent / 100;

  /// SGST amount computed from subtotal
  double get sgstAmount => subtotal * sgstPercent / 100;

  /// Total GST amount for this item
  double get totalGstAmount => cgstAmount + sgstAmount;

  /// Calculate profit for this item (before any bill-level discount)
  double get itemProfit => (sellingPrice - purchasePrice) * quantity;

  /// Get remaining quantity that can still be returned
  double get remainingQuantity => quantity - returnedQuantity;

  /// Get quantity as int (for backward compatibility)
  int get quantityInt => quantity.round();

  /// Get display quantity with appropriate unit conversion
  /// If sold in gm, shows gm value; if sold in ml, shows ml value
  String get displayQuantity {
    if (sellUnit == 'gm' && unit == 'kg') {
      return '${(quantity * 1000).toStringAsFixed(quantity * 1000 == (quantity * 1000).roundToDouble() ? 0 : 1)} gm';
    } else if (sellUnit == 'ml' && unit == 'ltr') {
      return '${(quantity * 1000).toStringAsFixed(quantity * 1000 == (quantity * 1000).roundToDouble() ? 0 : 1)} ml';
    } else if (unit != null && unit!.isNotEmpty) {
      return '${quantity == quantity.roundToDouble() ? quantity.toInt() : quantity.toStringAsFixed(2)} ${sellUnit ?? unit}';
    }
    return quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
  }

  /// Get the display unit string
  String get displayUnit => sellUnit ?? unit ?? '';

  /// Check if this item is fully returned
  bool get isFullyReturned =>
      returnedQuantity >=
      quantity - 0.001; // Small tolerance for floating point

  /// Check if this item has been partially returned
  bool get isPartiallyReturned =>
      returnedQuantity > 0.001 &&
      returnedQuantity < quantity - 0.001; // Small tolerance for floating point

  /// Factory constructor to create from JSON (for Firebase)
  factory BillItem.fromJson(Map<String, dynamic> json) {
    try {
      return BillItem(
        id: (json['id'] ?? '') as String,
        billId: (json['billId'] ?? '') as String,
        productId: (json['productId'] ?? '') as String,
        productName: (json['productName'] ?? '') as String,
        companyName: json['companyName'] as String?,
        purchasePrice: ((json['purchasePrice'] ?? 0) as num).toDouble(),
        sellingPrice: ((json['sellingPrice'] ?? 0) as num).toDouble(),
        quantity: ((json['quantity'] ?? 0) as num).toDouble(),
        subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
        returnedQuantity: ((json['returnedQuantity'] ?? 0) as num).toDouble(),
        cgstPercent: ((json['cgstPercent'] ?? 0) as num).toDouble(),
        sgstPercent: ((json['sgstPercent'] ?? 0) as num).toDouble(),
        hsnCode: json['hsnCode'] as String?,
        unit: json['unit'] as String?,
        sellUnit: json['sellUnit'] as String?,
      );
    } catch (e) {
      print('[ERROR] Failed to parse BillItem from JSON: $json');
      print('[ERROR] Error details: $e');
      return BillItem(
        id: json['id']?.toString() ?? '',
        billId: json['billId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Unknown Product',
        companyName: json['companyName']?.toString(),
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
      'companyName': companyName,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'returnedQuantity': returnedQuantity,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'hsnCode': hsnCode,
      'unit': unit,
      'sellUnit': sellUnit,
    };
  }

  /// Copy with modifications
  BillItem copyWith({
    String? id,
    String? billId,
    String? productId,
    String? productName,
    String? companyName,
    double? purchasePrice,
    double? sellingPrice,
    double? quantity,
    double? subtotal,
    double? returnedQuantity,
    double? cgstPercent,
    double? sgstPercent,
    String? hsnCode,
    String? unit,
    String? sellUnit,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      sellUnit: sellUnit ?? this.sellUnit,
    );
  }

  /// Create a bill item with auto-calculated subtotal
  static BillItem create({
    String id = '',
    String billId = '',
    required String productId,
    required String productName,
    String? companyName,
    double purchasePrice = 0.0,
    required double sellingPrice,
    required double quantity,
    double returnedQuantity = 0,
    double cgstPercent = 0.0,
    double sgstPercent = 0.0,
    String? hsnCode,
    String? unit,
    String? sellUnit,
  }) {
    return BillItem(
      id: id,
      billId: billId,
      productId: productId,
      productName: productName,
      companyName: companyName,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      subtotal: sellingPrice * quantity,
      returnedQuantity: returnedQuantity,
      cgstPercent: cgstPercent,
      sgstPercent: sgstPercent,
      hsnCode: hsnCode,
      unit: unit,
      sellUnit: sellUnit,
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
