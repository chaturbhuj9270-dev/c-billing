import 'bill_item.dart';
import 'package:c_billing/features/billing/offline/entities/bill_entity.dart';

/// Payment status of a bill
enum PaymentStatus {
  /// Full amount received at time of sale
  paid,

  /// Partial payment received, some amount pending
  partiallyPaid,

  /// No payment received, full amount pending
  pending,
}

/// Represents a sales bill containing multiple items sold to a customer
class Bill {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? customerContact;
  final List<BillItem> items;
  final int totalQuantity;
  final double totalAmount;
  final double discountAmount;
  final double discountPercent;
  final double finalAmount;
  final DateTime billDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool returnStatus;
  final DateTime? returnDate;

  /// Payment status of the bill
  final PaymentStatus paymentStatus;

  /// Amount already paid for this bill
  final double paidAmount;

  /// Amount still pending for this bill
  final double pendingAmount;

  // ═══════════════════ GST Fields ═══════════════════
  /// Whether GST was applied to this bill
  final bool isGstApplied;

  /// Whether GST is inclusive (true) or exclusive (false)
  final bool isTaxInclusive;

  /// CGST percentage applied
  final double cgstPercent;

  /// SGST percentage applied
  final double sgstPercent;

  /// Other tax percentage applied
  final double otherTaxPercent;

  /// Other tax name (e.g., "Cess")
  final String otherTaxName;

  /// Calculated CGST amount
  final double cgstAmount;

  /// Calculated SGST amount
  final double sgstAmount;

  /// Calculated other tax amount
  final double otherTaxAmount;

  /// Total tax amount (CGST + SGST + Other)
  final double totalTaxAmount;

  Bill({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerContact,
    required this.items,
    required this.totalQuantity,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.discountPercent = 0.0,
    required this.finalAmount,
    required this.billDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.returnStatus = false,
    this.returnDate,
    this.paymentStatus = PaymentStatus.paid,
    this.paidAmount = 0.0,
    this.pendingAmount = 0.0,
    this.isGstApplied = false,
    this.isTaxInclusive = false,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.otherTaxPercent = 0.0,
    this.otherTaxName = '',
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.otherTaxAmount = 0.0,
    this.totalTaxAmount = 0.0,
  });

  /// Factory constructor to create from JSON (for Firebase)
  factory Bill.fromJson(Map<String, dynamic> json) {
    try {
      List<BillItem> billItems = [];
      if (json['items'] != null) {
        billItems = (json['items'] as List)
            .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      final totalAmount = ((json['totalAmount'] ?? 0) as num).toDouble();
      final discountAmount = ((json['discountAmount'] ?? 0) as num).toDouble();
      final discountPercent = ((json['discountPercent'] ?? 0) as num)
          .toDouble();
      final finalAmount = ((json['finalAmount'] ?? totalAmount) as num)
          .toDouble();

      return Bill(
        id: (json['id'] ?? '') as String,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String?,
        customerContact: json['customerContact'] as String?,
        items: billItems,
        totalQuantity: (json['totalQuantity'] ?? 0) as int,
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        discountPercent: discountPercent,
        finalAmount: finalAmount,
        billDate: json['billDate'] != null
            ? DateTime.parse(json['billDate'] as String)
            : DateTime.now(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        notes: json['notes'] as String?,
        returnStatus: (json['returnStatus'] ?? false) as bool,
        returnDate: json['returnDate'] != null
            ? DateTime.parse(json['returnDate'] as String)
            : null,
        paymentStatus: _parsePaymentStatus(json['paymentStatus'] as String?),
        paidAmount: ((json['paidAmount'] ?? 0) as num).toDouble(),
        pendingAmount: ((json['pendingAmount'] ?? 0) as num).toDouble(),
        isGstApplied: (json['isGstApplied'] ?? false) as bool,
        isTaxInclusive: (json['isTaxInclusive'] ?? false) as bool,
        cgstPercent: ((json['cgstPercent'] ?? 0) as num).toDouble(),
        sgstPercent: ((json['sgstPercent'] ?? 0) as num).toDouble(),
        otherTaxPercent: ((json['otherTaxPercent'] ?? 0) as num).toDouble(),
        otherTaxName: (json['otherTaxName'] ?? '') as String,
        cgstAmount: ((json['cgstAmount'] ?? 0) as num).toDouble(),
        sgstAmount: ((json['sgstAmount'] ?? 0) as num).toDouble(),
        otherTaxAmount: ((json['otherTaxAmount'] ?? 0) as num).toDouble(),
        totalTaxAmount: ((json['totalTaxAmount'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      print('[ERROR] Failed to parse Bill from JSON: $json');
      print('[ERROR] Error details: $e');
      return Bill(
        id: json['id']?.toString() ?? '',
        customerId: null,
        customerName: null,
        customerContact: null,
        items: [],
        totalQuantity: 0,
        totalAmount: 0.0,
        discountAmount: 0.0,
        discountPercent: 0.0,
        finalAmount: 0.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: null,
        returnStatus: false,
        returnDate: null,
        paymentStatus: PaymentStatus.paid,
        paidAmount: 0.0,
        pendingAmount: 0.0,
      );
    }
  }

  /// Factory constructor to create from BillEntity (for offline-first)
  factory Bill.fromBillEntity(BillEntity entity) {
    // Convert embedded bill items to domain BillItem
    final billItems = entity.items
        .map(
          (item) => BillItem(
            id: item.itemId ?? '',
            billId: entity.serverId ?? entity.id.toString(),
            productId: item.productId ?? '',
            productName: item.productName ?? '',
            purchasePrice: item.purchasePrice,
            sellingPrice: item.sellingPrice,
            quantity: item.quantity,
            subtotal: item.subtotal,
            returnedQuantity: item.returnedQuantity,
            hsnCode: item.hsnCode,
            unit: item.unit,
            sellUnit: item.sellUnit,
          ),
        )
        .toList();

    // Convert BillPaymentStatus to PaymentStatus
    PaymentStatus paymentStatus;
    switch (entity.paymentStatus) {
      case BillPaymentStatus.paid:
        paymentStatus = PaymentStatus.paid;
        break;
      case BillPaymentStatus.partiallyPaid:
        paymentStatus = PaymentStatus.partiallyPaid;
        break;
      case BillPaymentStatus.pending:
        paymentStatus = PaymentStatus.pending;
        break;
    }

    return Bill(
      id: entity.serverId ?? entity.id.toString(),
      customerId: entity.customerId,
      customerName: entity.customerName,
      customerContact: entity.customerContact,
      items: billItems,
      totalQuantity: entity.totalQuantity,
      totalAmount: entity.totalAmount,
      discountAmount: entity.discountAmount,
      discountPercent: entity.discountPercent,
      finalAmount: entity.finalAmount,
      billDate: entity.billDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      notes: entity.notes,
      returnStatus: entity.returnStatus,
      returnDate: entity.returnDate,
      paymentStatus: paymentStatus,
      paidAmount: entity.paidAmount,
      pendingAmount: entity.pendingAmount,
      isGstApplied: entity.isGstApplied,
      isTaxInclusive: entity.isTaxInclusive,
      cgstPercent: entity.cgstPercent,
      sgstPercent: entity.sgstPercent,
      otherTaxPercent: entity.otherTaxPercent,
      otherTaxName: entity.otherTaxName ?? '',
      cgstAmount: entity.cgstAmount,
      sgstAmount: entity.sgstAmount,
      otherTaxAmount: entity.otherTaxAmount,
      totalTaxAmount: entity.totalTaxAmount,
    );
  }

  /// Parse payment status from string
  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partiallyPaid':
        return PaymentStatus.partiallyPaid;
      case 'pending':
        return PaymentStatus.pending;
      default:
        return PaymentStatus.paid;
    }
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'returnStatus': returnStatus,
      'returnDate': returnDate?.toIso8601String(),
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'isGstApplied': isGstApplied,
      'isTaxInclusive': isTaxInclusive,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'otherTaxPercent': otherTaxPercent,
      'otherTaxName': otherTaxName,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'otherTaxAmount': otherTaxAmount,
      'totalTaxAmount': totalTaxAmount,
    };
  }

  /// Copy with modifications
  Bill copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerContact,
    List<BillItem>? items,
    int? totalQuantity,
    double? totalAmount,
    double? discountAmount,
    double? discountPercent,
    double? finalAmount,
    DateTime? billDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? returnStatus,
    DateTime? returnDate,
    PaymentStatus? paymentStatus,
    double? paidAmount,
    double? pendingAmount,
    bool? isGstApplied,
    bool? isTaxInclusive,
    double? cgstPercent,
    double? sgstPercent,
    double? otherTaxPercent,
    String? otherTaxName,
    double? cgstAmount,
    double? sgstAmount,
    double? otherTaxAmount,
    double? totalTaxAmount,
  }) {
    return Bill(
      id: id ?? this.id,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      returnStatus: returnStatus ?? this.returnStatus,
      returnDate: returnDate ?? this.returnDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      isGstApplied: isGstApplied ?? this.isGstApplied,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      otherTaxPercent: otherTaxPercent ?? this.otherTaxPercent,
      otherTaxName: otherTaxName ?? this.otherTaxName,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      otherTaxAmount: otherTaxAmount ?? this.otherTaxAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
    );
  }

  /// Get a formatted bill number
  String get billNumber {
    final dateStr = billDate
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    return 'BILL-$dateStr-${id.substring(0, id.length > 6 ? 6 : id.length).toUpperCase()}';
  }

  /// Check if bill has customer information
  bool get hasCustomerInfo =>
      (customerName != null && customerName!.isNotEmpty) ||
      (customerContact != null && customerContact!.isNotEmpty);

  /// Check if all items in the bill are fully returned
  bool get isFullyReturned => items.every((item) => item.isFullyReturned);

  /// Check if any item has been partially or fully returned
  bool get hasAnyReturns => items.any((item) => item.returnedQuantity > 0.001);

  /// Check if there are any items that can still be returned
  bool get hasReturnableItems =>
      items.any((item) => item.remainingQuantity > 0.001);

  /// Get total returned quantity across all items
  double get totalReturnedQuantity =>
      items.fold(0.0, (sum, item) => sum + item.returnedQuantity);

  /// Get total returned quantity as int (for display)
  int get totalReturnedQuantityInt => totalReturnedQuantity.round();

  /// Get total refund amount based on returned quantities
  double get totalReturnedAmount => items.fold(
    0.0,
    (sum, item) => sum + (item.sellingPrice * item.returnedQuantity),
  );

  @override
  String toString() {
    return 'Bill(id: $id, customer: $customerName, items: ${items.length}, total: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
