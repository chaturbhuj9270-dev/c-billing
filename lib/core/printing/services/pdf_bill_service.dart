import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_bill_data.dart';
import '../../../features/shop/domain/entities/shop.dart';

/// Service for generating PDF bills and sharing them
class PdfBillService {
  static final PdfBillService _instance = PdfBillService._internal();
  factory PdfBillService() => _instance;
  PdfBillService._internal();

  /// Generate a PDF document from bill data (POS receipt format)
  Future<pw.Document> generateBillPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    final pdf = pw.Document();

    // Check if customer details should be shown
    final prefs = await SharedPreferences.getInstance();
    final showCustomer = prefs.getBool('bill_show_customer_details') ?? true;
    final generateViaContact =
        prefs.getBool('bill_generate_via_contact') ?? false;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => _buildBillContent(
          billData,
          shopDetails,
          showCustomer,
          generateViaContact,
        ),
      ),
    );

    return pdf;
  }

  /// Generate a Normal/Tabular A4 bill PDF (Krushi Seva Kendra style — half A4 page, compact)
  Future<pw.Document> generateNormalBillPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    final pdf = pw.Document();

    // Check if customer details should be shown
    final prefs = await SharedPreferences.getInstance();
    final showCustomer = prefs.getBool('bill_show_customer_details') ?? true;

    // Use standard A4 — content will naturally occupy half page for small bills
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Align(
          alignment: pw.Alignment.topCenter,
          child: _buildNormalBillContent(
            billData,
            shopDetails,
            showCustomer,
          ),
        ),
      ),
    );

    return pdf;
  }

  /// Build content for Normal/Tabular bill (Krushi Seva Kendra style — half A4 compact)
  pw.Widget _buildNormalBillContent(
    PrintBillData billData,
    Shop shopDetails,
    bool showCustomer,
  ) {
    final borderSide = pw.BorderSide(color: PdfColors.grey800, width: 0.8);
    final thinBorder = pw.BorderSide(color: PdfColors.grey600, width: 0.5);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 1.0),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════════
          // SHOP HEADER — Bold name, address, phone, GST
          // ═══════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: borderSide),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  shopDetails.shopName.isNotEmpty
                      ? shopDetails.shopName.toUpperCase()
                      : 'STORE',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (shopDetails.address.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    shopDetails.address.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                pw.SizedBox(height: 3),
                // Phone, Email, GST in a compact row
                pw.Wrap(
                  alignment: pw.WrapAlignment.center,
                  spacing: 12,
                  children: [
                    if (shopDetails.phone.isNotEmpty)
                      pw.Text(
                        'Mo. No: ${shopDetails.phone}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    if (shopDetails.email != null && shopDetails.email!.isNotEmpty)
                      pw.Text(
                        shopDetails.email!,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
                if (shopDetails.gstNumber != null &&
                    shopDetails.gstNumber!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GST No: ${shopDetails.gstNumber}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // CUSTOMER INFO + INVOICE INFO (side by side)
          // ═══════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: borderSide),
            ),
            child: pw.Row(
              children: [
                // Left: Customer Details
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: thinBorder),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (showCustomer &&
                            billData.customerName != null &&
                            billData.customerName!.isNotEmpty)
                          _buildCompactInfoRow(
                            'Customer Name',
                            billData.customerName!.toUpperCase(),
                            bold: true,
                          ),
                        if (billData.customerPhone != null &&
                            billData.customerPhone!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _buildCompactInfoRow('Contact', billData.customerPhone!),
                        ],
                        if ((!showCustomer ||
                                billData.customerName == null ||
                                billData.customerName!.isEmpty) &&
                            (billData.customerPhone == null ||
                                billData.customerPhone!.isEmpty))
                          _buildCompactInfoRow('Customer Name', 'CASH'),
                      ],
                    ),
                  ),
                ),
                // Right: Invoice Details
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildCompactInfoRow(
                          'Invoice Date',
                          _formatDateNormal(billData.dateTime),
                        ),
                        pw.SizedBox(height: 3),
                        _buildCompactInfoRow(
                          'Invoice No',
                          billData.billNumber,
                          bold: true,
                        ),
                        pw.SizedBox(height: 3),
                        _buildCompactInfoRow(
                          'Time',
                          _formatTime(billData.dateTime),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // ITEMS TABLE — Particulars, Company, Qty, Rate, Amount
          // ═══════════════════════════════════════════
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: thinBorder,
              bottom: borderSide,
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),   // Sr.
              1: const pw.FlexColumnWidth(3.5),   // Particulars
              2: const pw.FixedColumnWidth(40),    // Qty
              3: const pw.FixedColumnWidth(60),    // Rate
              4: const pw.FixedColumnWidth(70),    // Amount
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildCompactHeaderCell('Sr.'),
                  _buildCompactHeaderCell('Particulars', align: pw.TextAlign.left),
                  _buildCompactHeaderCell('Qty'),
                  _buildCompactHeaderCell('Rate'),
                  _buildCompactHeaderCell('Amount'),
                ],
              ),
              // Item rows
              ...billData.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return pw.TableRow(
                  children: [
                    _buildCompactCell('${index + 1}', align: pw.TextAlign.center),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.name,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          if (item.companyName != null && item.companyName!.isNotEmpty)
                            pw.Text(
                              item.companyName!,
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildCompactCell('${item.quantity}', align: pw.TextAlign.center),
                    _buildCompactCell(item.rate.toStringAsFixed(2), align: pw.TextAlign.right),
                    _buildCompactCell(item.amount.toStringAsFixed(2), align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),

          // ═══════════════════════════════════════════
          // BOTTOM SECTION — Terms (left) + Totals (right)
          // ═══════════════════════════════════════════
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Total items/qty + Terms
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: thinBorder),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Total Items: ${billData.items.length}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Text(
                            'Total Qty: ${billData.totalQuantity}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      // Returns info
                      if (billData.hasAnyReturns) ...[
                        pw.Text(
                          'Returned: ${billData.totalReturnedQuantity} qty  (-Rs.${billData.totalReturnedAmount.toStringAsFixed(2)})',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      pw.Text(
                        'Terms & Conditions:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. Goods once sold will not be taken back.',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                      pw.Text(
                        '2. Please check the items before leaving.',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
              // Right: Financial Summary
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  children: [
                    // Discount row
                    if (billData.hasDiscount)
                      _buildCompactAmountRow(
                        'DISCOUNT',
                        billData.discountAmount!,
                        border: thinBorder,
                        suffix: billData.discountPercent != null
                            ? ' (${billData.discountPercent!.toStringAsFixed(0)}%)'
                            : '',
                      ),
                    // Sub Total
                    _buildCompactAmountRow(
                      'SUB TOTAL',
                      billData.subtotal,
                      border: thinBorder,
                      bold: true,
                    ),
                    // Grand Total
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border(bottom: thinBorder),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'GRAND TOTAL',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            billData.grandTotal.toStringAsFixed(2),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Paid Amount
                    if (billData.hasPaymentInfo) ...[
                      _buildCompactAmountRow(
                        'PAID AMT',
                        billData.paidAmount ?? 0,
                        border: thinBorder,
                        color: PdfColors.green800,
                      ),
                      // Balance / Pending
                      if (billData.hasPendingAmount)
                        _buildCompactAmountRow(
                          'BALANCE AMT',
                          billData.pendingAmount!,
                          border: thinBorder,
                          color: PdfColors.red700,
                          bold: true,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ═══════════════════════════════════════════
          // TOTAL DUE SECTION (only if customer has running balance)
          // ═══════════════════════════════════════════
          if (billData.totalDueAmount != null && billData.totalDueAmount! > 0)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border(top: borderSide),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL DUE AMOUNT',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange900,
                    ),
                  ),
                  pw.Text(
                    'Rs. ${billData.totalDueAmount!.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange900,
                    ),
                  ),
                ],
              ),
            ),

          // ═══════════════════════════════════════════
          // FOOTER — Signature
          // ═══════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: thinBorder),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Customer Signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: 100,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Customer Signature',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                // Shop Signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'For ${shopDetails.shopName.isNotEmpty ? shopDetails.shopName.toUpperCase() : 'STORE'}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'Authorized Signatory',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // COMPACT HELPERS — for half-A4 normal bill
  // ═══════════════════════════════════════════

  /// Compact info row (label: value) for customer/invoice section
  pw.Widget _buildCompactInfoRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// Compact table header cell
  pw.Widget _buildCompactHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: align,
      ),
    );
  }

  /// Compact table data cell
  pw.Widget _buildCompactCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: align,
      ),
    );
  }

  /// Compact amount row for totals section
  pw.Widget _buildCompactAmountRow(
    String label,
    double amount, {
    pw.BorderSide? border,
    bool bold = false,
    String suffix = '',
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        border: border != null ? pw.Border(bottom: border) : null,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label$suffix :',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateNormal(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  pw.Widget _buildBillContent(
    PrintBillData billData,
    Shop shopDetails,
    bool showCustomer,
    bool generateViaContact,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Shop Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                shopDetails.shopName.isNotEmpty
                    ? shopDetails.shopName
                    : 'STORE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (shopDetails.address.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  shopDetails.address,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (shopDetails.phone.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Ph: ${shopDetails.phone}',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (shopDetails.gstNumber != null &&
                  shopDetails.gstNumber!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'GSTIN: ${shopDetails.gstNumber}',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Bill Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Bill: ${billData.billNumber}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              _formatDate(billData.dateTime),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 4),

        // Customer Info - show based on settings
        if (generateViaContact &&
            billData.customerPhone != null &&
            billData.customerPhone!.isNotEmpty) ...[
          pw.Text(
            'Phone: ${billData.customerPhone}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (showCustomer &&
              billData.customerName != null &&
              billData.customerName!.isNotEmpty)
            pw.Text(
              'Customer: ${billData.customerName}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.SizedBox(height: 4),
        ] else if (showCustomer &&
            billData.customerName != null &&
            billData.customerName!.isNotEmpty) ...[
          pw.Text(
            'Customer: ${billData.customerName}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (billData.customerPhone != null &&
              billData.customerPhone!.isNotEmpty)
            pw.Text(
              'Phone: ${billData.customerPhone}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.SizedBox(height: 4),
        ],

        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Items Header
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'Item',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 40,
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(
              width: 50,
              child: pw.Text(
                'Rate',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(
              width: 60,
              child: pw.Text(
                'Amount',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 4),

        // Items
        ...billData.items.expand(
          (item) => [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.name,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        if (item.companyName != null && item.companyName!.isNotEmpty)
                          pw.Text(
                            item.companyName!,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      '${item.quantity}',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(
                      item.rate.toStringAsFixed(2),
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text(
                      item.amount.toStringAsFixed(2),
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // Show returned quantity for this item
            if (item.hasReturns)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Returned: ${item.returnedQuantity} qty',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.orange800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '-Rs. ${item.returnedAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.orange800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Returns summary section
        if (billData.hasAnyReturns) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Returned Items:',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                '${billData.totalReturnedQuantity} qty',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Return Amount:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
              pw.Text(
                '-Rs. ${billData.totalReturnedAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 8),
        ],

        // Totals
        _buildTotalRow('Subtotal', billData.subtotal),
        if (billData.discountAmount != null &&
            billData.discountAmount! > 0) ...[
          pw.SizedBox(height: 4),
          _buildTotalRow(
            'Discount (${billData.discountPercent?.toStringAsFixed(0) ?? '0'}%)',
            -(billData.discountAmount ?? 0),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),

        // Grand Total
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'GRAND TOTAL',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Rs. ${billData.grandTotal.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),

        // Payment Details Section
        if (billData.hasPaymentInfo) ...[
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 0.3),
          pw.SizedBox(height: 8),

          // Paid Amount
          if (billData.paidAmount != null)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Paid Amount', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'Rs. ${billData.paidAmount!.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),

          // Pending Amount
          if (billData.hasPendingAmount) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pending Amount',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Rs. ${billData.pendingAmount!.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
              ],
            ),
          ],

          // Total Due Amount
          if (billData.totalDueAmount != null &&
              billData.totalDueAmount! > 0) ...[
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.3),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL DUE',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rs. ${billData.totalDueAmount!.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        pw.SizedBox(height: 16),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 8),

        // Footer
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Please visit again',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          'Rs. ${amount.abs().toStringAsFixed(2)}${amount < 0 ? ' -' : ''}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $period';
  }

  /// Save PDF to file and return the file path
  Future<File> savePdfToFile({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    // Check bill type setting
    final prefs = await SharedPreferences.getInstance();
    final billType = prefs.getString('bill_type') ?? 'pos';
    
    final pw.Document pdf;
    if (billType == 'normal') {
      pdf = await generateNormalBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    } else {
      pdf = await generateBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    }

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'bill_${billData.billNumber.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Share the bill as PDF via the system share sheet
  Future<void> shareBillAsPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    try {
      debugPrint('[PdfBillService] Starting shareBillAsPdf for bill: ${billData.billNumber}');
      
      // Check bill type setting
      final prefs = await SharedPreferences.getInstance();
      final billType = prefs.getString('bill_type') ?? 'pos';
      debugPrint('[PdfBillService] Bill type: $billType');
      
      final pw.Document pdf;
      if (billType == 'normal') {
        pdf = await generateNormalBillPdf(
          billData: billData,
          shopDetails: shopDetails,
        );
      } else {
        pdf = await generateBillPdf(
          billData: billData,
          shopDetails: shopDetails,
        );
      }
      debugPrint('[PdfBillService] PDF generated successfully');

      final bytes = await pdf.save();
      debugPrint('[PdfBillService] PDF bytes saved, size: ${bytes.length}');

      // Write to a temp file first — XFile.fromData is unreliable on some devices
      final dir = await getTemporaryDirectory();
      final fileName =
          'bill_${billData.billNumber.replaceAll('/', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      debugPrint('[PdfBillService] PDF written to temp file: ${file.path}');

      debugPrint('[PdfBillService] Calling Share.shareXFiles...');
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bill ${billData.billNumber} - ${shopDetails.shopName}',
        subject: 'Bill from ${shopDetails.shopName}',
      );
      debugPrint('[PdfBillService] Share result: ${result.status}');
    } catch (e, stackTrace) {
      debugPrint('[PdfBillService] ERROR in shareBillAsPdf: $e');
      debugPrint('[PdfBillService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Preview and print PDF using system print dialog
  Future<void> previewAndPrintPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    // Check bill type setting
    final prefs = await SharedPreferences.getInstance();
    final billType = prefs.getString('bill_type') ?? 'pos';
    
    final pw.Document pdf;
    if (billType == 'normal') {
      pdf = await generateNormalBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    } else {
      pdf = await generateBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Bill_${billData.billNumber}',
    );
  }

  /// Show PDF preview in a dialog
  Future<void> showPdfPreview({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    // Check bill type setting
    final prefs = await SharedPreferences.getInstance();
    final billType = prefs.getString('bill_type') ?? 'pos';
    
    final pw.Document pdf;
    if (billType == 'normal') {
      pdf = await generateNormalBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    } else {
      pdf = await generateBillPdf(
        billData: billData,
        shopDetails: shopDetails,
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'bill_${billData.billNumber.replaceAll('/', '_')}.pdf',
    );
  }
}
