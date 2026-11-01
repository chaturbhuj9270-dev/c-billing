import '../../../billing/domain/entities/bill_tax_settings.dart';

/// Snapshot of purchase-invoice tax used for ITC and display.
///
/// Batch / FIFO [purchasePrice] stays exclusive COGS; [totalAmount] is the
/// invoice grand total when GST is applied.
class PurchaseTaxResult {
  final bool isGstApplied;
  final bool isTaxInclusive;
  final bool isInterstate;
  final double taxableValue;
  final double cgstPercent;
  final double sgstPercent;
  final double igstPercent;
  final double otherTaxPercent;
  final String? otherTaxName;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double otherTaxAmount;
  final double totalTaxAmount;
  /// Invoice grand total (taxable + tax when exclusive GST).
  final double totalAmount;
  final String? hsnCode;
  final String? supplierGstin;

  const PurchaseTaxResult({
    required this.isGstApplied,
    required this.isTaxInclusive,
    required this.isInterstate,
    required this.taxableValue,
    required this.cgstPercent,
    required this.sgstPercent,
    required this.igstPercent,
    required this.otherTaxPercent,
    this.otherTaxName,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.otherTaxAmount,
    required this.totalTaxAmount,
    required this.totalAmount,
    this.hsnCode,
    this.supplierGstin,
  });

  factory PurchaseTaxResult.untaxed({
    required double lineTotal,
    String? hsnCode,
    String? supplierGstin,
  }) {
    return PurchaseTaxResult(
      isGstApplied: false,
      isTaxInclusive: false,
      isInterstate: false,
      taxableValue: lineTotal,
      cgstPercent: 0,
      sgstPercent: 0,
      igstPercent: 0,
      otherTaxPercent: 0,
      otherTaxName: null,
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      otherTaxAmount: 0,
      totalTaxAmount: 0,
      totalAmount: lineTotal,
      hsnCode: hsnCode,
      supplierGstin: supplierGstin,
    );
  }
}

/// ITC-style purchase tax. Reuses [BillTaxSettings.fromItemTaxes] / [TaxBreakdown].
class PurchaseTaxCalculator {
  PurchaseTaxCalculator._();

  static PurchaseTaxResult calculate({
    required double quantity,
    required double purchasePrice,
    double cgstPercent = 0,
    double sgstPercent = 0,
    bool isInterstate = false,
    bool isGstApplied = false,
    double otherTaxPercent = 0,
    String otherTaxName = '',
    GstMode gstMode = GstMode.excludeGst,
    String? hsnCode,
    String? supplierGstin,
  }) {
    final lineSubtotal = quantity * purchasePrice;
    final hasRates =
        cgstPercent > 0 || sgstPercent > 0 || otherTaxPercent > 0;

    if (!isGstApplied || !hasRates || gstMode == GstMode.noGst) {
      return PurchaseTaxResult.untaxed(
        lineTotal: lineSubtotal,
        hsnCode: hsnCode,
        supplierGstin: supplierGstin,
      );
    }

    final breakdown = BillTaxSettings.fromItemTaxes(
      items: [
        (
          subtotal: lineSubtotal,
          cgstPercent: cgstPercent,
          sgstPercent: sgstPercent,
        ),
      ],
      discountAmount: 0,
      gstMode: gstMode,
      forceIgst: isInterstate,
      otherTaxPercent: otherTaxPercent,
      otherTaxName: otherTaxName,
    );

    // Exclusive ITC: invoice total = taxable + tax. Inclusive uses extracted base.
    final invoiceTotal = gstMode == GstMode.includeGst
        ? breakdown.grandTotal()
        : breakdown.taxableValue + breakdown.totalTaxAmount;

    return PurchaseTaxResult(
      isGstApplied: true,
      isTaxInclusive: gstMode == GstMode.includeGst,
      isInterstate: isInterstate,
      taxableValue: breakdown.taxableValue,
      cgstPercent: isInterstate ? 0 : breakdown.cgstPercent,
      sgstPercent: isInterstate ? 0 : breakdown.sgstPercent,
      igstPercent: isInterstate
          ? (breakdown.igstPercent > 0
              ? breakdown.igstPercent
              : cgstPercent + sgstPercent)
          : breakdown.igstPercent,
      otherTaxPercent: breakdown.otherTaxPercent,
      otherTaxName: breakdown.otherTaxName.isEmpty
          ? null
          : breakdown.otherTaxName,
      cgstAmount: breakdown.cgstAmount,
      sgstAmount: breakdown.sgstAmount,
      igstAmount: breakdown.igstAmount,
      otherTaxAmount: breakdown.otherTaxAmount,
      totalTaxAmount: breakdown.totalTaxAmount,
      totalAmount: invoiceTotal,
      hsnCode: hsnCode,
      supplierGstin: supplierGstin,
    );
  }
}
