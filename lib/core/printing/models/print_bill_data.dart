/// Model representing a single item for printing on POS bill
class PrintBillItem {
  final String name;
  final String? companyName; // Product company/brand name
  final int quantity;
  final double rate;
  final double amount;
  final int returnedQuantity;

  const PrintBillItem({
    required this.name,
    this.companyName,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.returnedQuantity = 0,
  });

  /// Whether some units of this item have been returned
  bool get hasReturns => returnedQuantity > 0;

  /// Quantity still held by the customer
  int get effectiveQuantity => quantity - returnedQuantity;

  /// Refund amount for the returned units
  double get returnedAmount => rate * returnedQuantity;

  /// Create from BillItem entity
  factory PrintBillItem.fromBillItem(dynamic billItem) {
    return PrintBillItem(
      name: billItem.productName as String,
      companyName: billItem.companyName as String?,
      quantity: billItem.quantity as int,
      rate: billItem.sellingPrice as double,
      amount: billItem.subtotal as double,
      returnedQuantity: (billItem.returnedQuantity as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'companyName': companyName,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'returnedQuantity': returnedQuantity,
    };
  }
}

/// Model representing complete bill data for POS printing
class PrintBillData {
  final String billNumber;
  final DateTime dateTime;
  final String? customerName;
  final String? customerPhone;
  final List<PrintBillItem> items;
  final double subtotal;
  final double? discountAmount;
  final double? discountPercent;
  final double? taxAmount;
  final double? taxPercent;
  final double grandTotal;
  final String? paymentMethod;
  final String? notes;
  final bool isReturnBill;
  final double? refundAmount;

  /// Amount paid for this bill
  final double? paidAmount;

  /// Amount pending for this bill
  final double? pendingAmount;

  /// Customer's total due amount (running balance)
  final double? totalDueAmount;

  const PrintBillData({
    required this.billNumber,
    required this.dateTime,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discountAmount,
    this.discountPercent,
    this.taxAmount,
    this.taxPercent,
    required this.grandTotal,
    this.paymentMethod,
    this.notes,
    this.isReturnBill = false,
    this.refundAmount,
    this.paidAmount,
    this.pendingAmount,
    this.totalDueAmount,
  });

  /// Create from Bill entity
  factory PrintBillData.fromBill(
    dynamic bill, {
    bool isReturn = false,
    double? refund,
    double? totalDueAmount,
  }) {
    // Extract payment info from bill if available
    final double? paidAmount = bill.paidAmount as double?;
    final double? pendingAmount = bill.pendingAmount as double?;

    return PrintBillData(
      billNumber: bill.billNumber as String,
      dateTime: bill.billDate as DateTime,
      customerName: bill.customerName as String?,
      customerPhone: bill.customerContact as String?,
      items: (bill.items as List)
          .map((item) => PrintBillItem.fromBillItem(item))
          .toList(),
      subtotal: bill.totalAmount as double,
      discountAmount: bill.discountAmount as double?,
      discountPercent: bill.discountPercent as double?,
      grandTotal: bill.finalAmount as double,
      notes: bill.notes as String?,
      isReturnBill: isReturn,
      refundAmount: refund,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      totalDueAmount: totalDueAmount,
    );
  }

  /// Get total quantity of items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total returned quantity across all items
  int get totalReturnedQuantity =>
      items.fold(0, (sum, item) => sum + item.returnedQuantity);

  /// Total refund amount for all returned items
  double get totalReturnedAmount =>
      items.fold(0.0, (sum, item) => sum + item.returnedAmount);

  /// Whether any item in this bill has returns
  bool get hasAnyReturns => items.any((item) => item.hasReturns);

  /// Check if discount is applied
  bool get hasDiscount => discountAmount != null && discountAmount! > 0;

  /// Check if tax is applied
  bool get hasTax => taxAmount != null && taxAmount! > 0;

  /// Check if payment info is available
  bool get hasPaymentInfo => paidAmount != null || pendingAmount != null;

  /// Check if there's pending amount
  bool get hasPendingAmount => pendingAmount != null && pendingAmount! > 0;

  Map<String, dynamic> toJson() {
    return {
      'billNumber': billNumber,
      'dateTime': dateTime.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'taxAmount': taxAmount,
      'taxPercent': taxPercent,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'isReturnBill': isReturnBill,
      'refundAmount': refundAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'totalDueAmount': totalDueAmount,
    };
  }
}
