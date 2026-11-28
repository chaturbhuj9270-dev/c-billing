import 'package:c_billing/core/printing/bill_print_math.dart';
import 'package:c_billing/features/billing/domain/entities/bill_extra_charge.dart';
import 'package:c_billing/features/billing/domain/entities/bill_service_charge.dart';

// Model representing a single item for printing on POS bill
class PrintBillItem {
  final String name;
  final String? companyName; // Product company/brand name
  final double quantity; // Changed to double to support decimal quantities
  final double rate;
  final double amount;
  final double returnedQuantity; // Changed to double to match quantity
  final double cgstPercent;
  final double sgstPercent;
  final String? hsnCode;
  final String? unit; // Base unit (kg, ltr, pcs)
  final String? sellUnit; // Unit used for sale (gm, ml, kg, ltr, pcs)

  const PrintBillItem({
    required this.name,
    this.companyName,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.returnedQuantity = 0,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.hsnCode,
    this.unit,
    this.sellUnit,
  });

  // CGST amount computed from amount
  double get cgstAmount => amount * cgstPercent / 100;

  // SGST amount computed from amount
  double get sgstAmount => amount * sgstPercent / 100;

  // Whether this item has per-product GST
  bool get hasItemGst => cgstPercent > 0 || sgstPercent > 0;

  // Whether some units of this item have been returned
  bool get hasReturns => returnedQuantity > 0;

  // Quantity still held by the customer
  double get effectiveQuantity => quantity - returnedQuantity;

  // Refund amount for the returned units
  double get returnedAmount => rate * returnedQuantity;

  // Get display quantity with unit conversion (for printing)
  String get displayQuantity {
    if (sellUnit == 'gm' && unit == 'kg') {
      final gmQty = quantity * 1000;
      return '${gmQty == gmQty.roundToDouble() ? gmQty.toInt() : gmQty.toStringAsFixed(1)} gm';
    } else if (sellUnit == 'ml' && unit == 'ltr') {
      final mlQty = quantity * 1000;
      return '${mlQty == mlQty.roundToDouble() ? mlQty.toInt() : mlQty.toStringAsFixed(1)} ml';
    } else if (quantity == quantity.roundToDouble()) {
      return '${quantity.toInt()}';
    } else {
      return quantity.toStringAsFixed(2);
    }
  }

  // Create from OrderItem (quotations / event orders).
  factory PrintBillItem.fromOrderItem(dynamic orderItem) {
    return PrintBillItem(
      name: orderItem.productName as String,
      quantity: ((orderItem.quantity as num?) ?? 0).toDouble(),
      rate: (orderItem.rate as num).toDouble(),
      amount: (orderItem.subtotal as num).toDouble(),
      cgstPercent: (orderItem.cgstPercent as num?)?.toDouble() ?? 0.0,
      sgstPercent: (orderItem.sgstPercent as num?)?.toDouble() ?? 0.0,
      hsnCode: orderItem.hsnCode as String?,
    );
  }

  // Create from BillItem entity
  factory PrintBillItem.fromBillItem(dynamic billItem) {
    return PrintBillItem(
      name: billItem.productName as String,
      companyName: billItem.companyName as String?,
      quantity: (billItem.quantity as num).toDouble(),
      rate: billItem.sellingPrice as double,
      amount: billItem.subtotal as double,
      returnedQuantity: ((billItem.returnedQuantity as num?) ?? 0).toDouble(),
      cgstPercent: (billItem.cgstPercent as double?) ?? 0.0,
      sgstPercent: (billItem.sgstPercent as double?) ?? 0.0,
      hsnCode: billItem.hsnCode as String?,
      unit: billItem.unit as String?,
      sellUnit: billItem.sellUnit as String?,
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
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'hsnCode': hsnCode,
      'unit': unit,
      'sellUnit': sellUnit,
    };
  }
}

// Model representing complete bill data for POS printing
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
  // When true, PDF/thermal output uses Quotation labels instead of Bill/Invoice.
  final bool isQuotation;
  final DateTime? validUntil;
  // Event/order date for quotations (replaces valid-until on print).
  final DateTime? eventOrderDate;
  final String? quotationTitle;
  // Other document kinds (e.g. event / sales orders) reuse the billing layout.
  // `pos` or `normal` – overrides the bill/quotation format preference.
  final String? formatOverride;
  // Header title shown instead of INVOICE (e.g. EVENT INVOICE).
  final String? documentTitle;
  // Label for the document number (default: Bill No / Quotation No).
  final String? numberLabelText;
  // Amount the payment QR should ask for (e.g. balance due). When set and not
  // positive, no payment QR is printed.
  final double? qrAmountOverride;
  final double? refundAmount;

  // Amount paid for this bill
  final double? paidAmount;

  // Amount pending for this bill
  final double? pendingAmount;

  // Customer's total due amount (running balance)
  final double? totalDueAmount;

  // ═══════════════════ GST Fields ═══════════════════ Whether GST was applied
  final bool isGstApplied;

  // Whether GST is inclusive
  final bool isTaxInclusive;

  // CGST percentage
  final double cgstPercent;

  // SGST percentage
  final double sgstPercent;

  // IGST percentage
  final double igstPercent;

  // Other tax percentage
  final double otherTaxPercent;

  // Other tax name
  final String otherTaxName;

  // CGST amount
  final double cgstAmount;

  // SGST amount
  final double sgstAmount;

  // IGST amount
  final double igstAmount;

  // Other tax amount
  final double otherTaxAmount;

  // Total tax amount
  final double totalTaxAmount;

  final String? customerGstin;

  // Extra charges (labour, service, etc.)
  final List<BillExtraCharge> extraCharges;

  // Employee counter token printed on the bill (1, 2, 3…).
  final int? employeeToken;

  // Customer key (serverId / local id) used at print time to look up the
  // customer's total pending till date. Null for walk-in bills / other docs.
  final String? customerId;

  // Rounding applied to reach the grand total (shown as "Round off" when
  // non-zero). 0 for documents that do not round.
  final double roundOff;

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
    this.isQuotation = false,
    this.validUntil,
    this.eventOrderDate,
    this.quotationTitle,
    this.formatOverride,
    this.documentTitle,
    this.numberLabelText,
    this.qrAmountOverride,
    this.refundAmount,
    this.paidAmount,
    this.pendingAmount,
    this.totalDueAmount,
    this.employeeToken,
    this.isGstApplied = false,
    this.isTaxInclusive = false,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.igstPercent = 0.0,
    this.otherTaxPercent = 0.0,
    this.otherTaxName = '',
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    this.otherTaxAmount = 0.0,
    this.totalTaxAmount = 0.0,
    this.customerGstin,
    this.extraCharges = const [],
    this.customerId,
    this.roundOff = 0.0,
  });

  /// Copy with a different customer total-due (null clears it).
  PrintBillData withTotalDue(double? totalDue) => PrintBillData(
        billNumber: billNumber,
        dateTime: dateTime,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        subtotal: subtotal,
        discountAmount: discountAmount,
        discountPercent: discountPercent,
        taxAmount: taxAmount,
        taxPercent: taxPercent,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod,
        notes: notes,
        isReturnBill: isReturnBill,
        isQuotation: isQuotation,
        validUntil: validUntil,
        eventOrderDate: eventOrderDate,
        quotationTitle: quotationTitle,
        formatOverride: formatOverride,
        documentTitle: documentTitle,
        numberLabelText: numberLabelText,
        qrAmountOverride: qrAmountOverride,
        refundAmount: refundAmount,
        paidAmount: paidAmount,
        pendingAmount: pendingAmount,
        totalDueAmount: totalDue,
        employeeToken: employeeToken,
        isGstApplied: isGstApplied,
        isTaxInclusive: isTaxInclusive,
        cgstPercent: cgstPercent,
        sgstPercent: sgstPercent,
        igstPercent: igstPercent,
        otherTaxPercent: otherTaxPercent,
        otherTaxName: otherTaxName,
        cgstAmount: cgstAmount,
        sgstAmount: sgstAmount,
        igstAmount: igstAmount,
        otherTaxAmount: otherTaxAmount,
        totalTaxAmount: totalTaxAmount,
        customerGstin: customerGstin,
        extraCharges: extraCharges,
        customerId: customerId,
        roundOff: roundOff,
      );

  /// Whether a "Round off" row should be printed.
  bool get hasRoundOff => roundOff.abs() >= 0.005;

  /// Portion of [totalDueAmount] owed from earlier bills (0 when none).
  double get previousDueAmount =>
      previousDueOf(totalDue: totalDueAmount, billPending: pendingAmount);

  /// Customer has a running balance to print ("TOTAL DUE till date").
  bool get hasTotalDue => totalDueAmount != null && totalDueAmount! > 0;

  double get extraChargesTotal =>
      extraCharges.fold(0.0, (sum, c) => sum + c.amount);

  bool get hasExtraCharges => extraCharges.any((c) => c.amount > 0);

  String get numberLabel =>
      numberLabelText ?? (isQuotation ? 'Quotation No' : 'Bill No');

  String get documentHeaderTitle =>
      documentTitle ?? (isQuotation ? 'QUOTATION' : 'INVOICE');

  // Create from Bill entity
  factory PrintBillData.fromBill(
    dynamic bill, {
    bool isReturn = false,
    double? refund,
    double? totalDueAmount,
    int? employeeToken,
  }) {
    // Extract payment info from bill if available
    final double? paidAmount = bill.paidAmount as double?;
    final double? pendingAmount = bill.pendingAmount as double?;

    final extras = _extraChargesFrom(bill);
    final extrasTotal = extras.fold<double>(0.0, (t, c) => t + c.amount);
    // Service charges are stored as bill items but are NOT in bill.totalAmount.
    var serviceTotal = 0.0;
    try {
      for (final item in (bill.items as List)) {
        if (BillServiceCharge.isServiceItem(
          productId: item.productId as String?,
        )) {
          serviceTotal += (item.subtotal as num).toDouble();
        }
      }
    } catch (_) {}
    final exclusiveTax = ((bill.isGstApplied as bool?) ?? false) &&
        !((bill.isTaxInclusive as bool?) ?? false);
    final totals = computeBillPrintTotals(
      productsTotal: (bill.totalAmount as num).toDouble(),
      serviceChargesTotal: serviceTotal,
      extraChargesTotal: extrasTotal,
      discountAmount: ((bill.discountAmount as num?) ?? 0).toDouble(),
      exclusiveTax: exclusiveTax,
      taxAmount: ((bill.totalTaxAmount as num?) ?? 0).toDouble(),
      finalAmount: (bill.finalAmount as num).toDouble(),
    );
    String? customerKey;
    try {
      final raw = (bill.customerId as String?)?.trim();
      if (raw != null && raw.isNotEmpty) customerKey = raw;
    } catch (_) {}

    return PrintBillData(
      billNumber: bill.billNumber as String,
      dateTime: bill.billDate as DateTime,
      customerName: bill.customerName as String?,
      customerPhone: bill.customerContact as String?,
      items: (bill.items as List)
          .map((item) => PrintBillItem.fromBillItem(item))
          .toList(),
      subtotal: totals.subtotal,
      discountAmount: bill.discountAmount as double?,
      discountPercent: bill.discountPercent as double?,
      taxAmount: ((bill.totalTaxAmount as num?)?.toDouble() ?? 0) > 0
          ? (bill.totalTaxAmount as num).toDouble()
          : null,
      taxPercent: () {
        final c = (bill.cgstPercent as num?)?.toDouble() ?? 0;
        final s = (bill.sgstPercent as num?)?.toDouble() ?? 0;
        final i = (bill.igstPercent as num?)?.toDouble() ?? 0;
        final t = c + s + i;
        return t > 0 ? t : null;
      }(),
      grandTotal: bill.finalAmount as double,
      notes: bill.notes as String?,
      paymentMethod: _paymentModeLabel(bill),
      isReturnBill: isReturn,
      refundAmount: refund,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      totalDueAmount: totalDueAmount,
      employeeToken: employeeToken,
      isGstApplied: (bill.isGstApplied as bool?) ?? false,
      isTaxInclusive: (bill.isTaxInclusive as bool?) ?? false,
      cgstPercent: (bill.cgstPercent as double?) ?? 0.0,
      sgstPercent: (bill.sgstPercent as double?) ?? 0.0,
      igstPercent: (bill.igstPercent as double?) ?? 0.0,
      otherTaxPercent: (bill.otherTaxPercent as double?) ?? 0.0,
      otherTaxName: (bill.otherTaxName as String?) ?? '',
      cgstAmount: (bill.cgstAmount as double?) ?? 0.0,
      sgstAmount: (bill.sgstAmount as double?) ?? 0.0,
      igstAmount: (bill.igstAmount as double?) ?? 0.0,
      otherTaxAmount: (bill.otherTaxAmount as double?) ?? 0.0,
      totalTaxAmount: (bill.totalTaxAmount as double?) ?? 0.0,
      customerGstin: bill.customerGstin as String?,
      extraCharges: extras,
      customerId: customerKey,
      roundOff: totals.roundOff,
    );
  }

  static List<BillExtraCharge> _extraChargesFrom(dynamic bill) {
    try {
      final raw = bill.extraCharges;
      if (raw is List<BillExtraCharge>) {
        return List<BillExtraCharge>.from(raw)
            .where((c) => c.label.trim().isNotEmpty && c.amount > 0)
            .toList();
      }
      if (raw is List) {
        final out = <BillExtraCharge>[];
        for (final e in raw) {
          if (e is BillExtraCharge) {
            if (e.label.trim().isNotEmpty && e.amount > 0) out.add(e);
          } else if (e is Map) {
            final c = BillExtraCharge.fromJson(Map<String, dynamic>.from(e));
            if (c.label.trim().isNotEmpty && c.amount > 0) out.add(c);
          }
        }
        return out;
      }
    } catch (_) {}
    return const [];
  }

  static String? _paymentModeLabel(dynamic bill) {
    try {
      final raw = bill.paymentMode;
      if (raw is! String || raw.trim().isEmpty) return null;
      switch (raw.trim().toUpperCase()) {
        case 'CASH':
          return 'Cash';
        case 'UPI':
          return 'UPI';
        case 'CARD':
          return 'Card';
        case 'ONLINE':
          return 'Online Transfer';
        case 'CHEQUE':
          return 'Cheque';
        case 'OTHER':
          return 'Other';
        default:
          return raw.trim();
      }
    } catch (_) {
      return null;
    }
  }

  // Get total quantity of items (as double to support decimal quantities)
  double get totalQuantity =>
      items.fold(0.0, (total, item) => total + item.quantity);

  // Get total quantity as int (for backward compatibility)
  int get totalQuantityInt => totalQuantity.round();

  // Total returned quantity across all items (as double)
  double get totalReturnedQuantity =>
      items.fold(0.0, (total, item) => total + item.returnedQuantity);

  // Total returned quantity as int (for backward compatibility)
  int get totalReturnedQuantityInt => totalReturnedQuantity.round();

  // Total refund amount for all returned items
  double get totalReturnedAmount =>
      items.fold(0.0, (total, item) => total + item.returnedAmount);

  // Whether any item in this bill has returns
  bool get hasAnyReturns => items.any((item) => item.hasReturns);

  // Check if discount is applied
  bool get hasDiscount => discountAmount != null && discountAmount! > 0;

  // Check if tax is applied
  bool get hasTax =>
      (taxAmount != null && taxAmount! > 0) || totalTaxAmount > 0;

  // Check if payment info is available
  bool get hasPaymentInfo =>
      !isQuotation && (paidAmount != null || pendingAmount != null);

  // Check if there's pending amount
  bool get hasPendingAmount => pendingAmount != null && pendingAmount! > 0;

  // Whether GST breakdown should be displayed
  bool get hasGst =>
      totalTaxAmount > 0 ||
      (isGstApplied &&
          (cgstAmount > 0 ||
              sgstAmount > 0 ||
              igstAmount > 0 ||
              otherTaxAmount > 0));

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
