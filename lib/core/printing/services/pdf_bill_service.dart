import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_bill_data.dart';
import '../../../features/shop/domain/entities/shop.dart';
import '../../services/bill_report_settings_service.dart';

/// Service for generating PDF bills and sharing them
class PdfBillService {
  static final PdfBillService _instance = PdfBillService._internal();
  factory PdfBillService() => _instance;
  PdfBillService._internal();

  static final bool _isGenerating = false;
  static final Set<String> _generatingBills = <String>{};

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
          child: _buildNormalBillContent(billData, shopDetails, showCustomer),
        ),
      ),
    );

    return pdf;
  }

  /// Build content for Normal/Tabular bill (Modern professional design - full A4 utilization)
  pw.Widget _buildNormalBillContent(
    PrintBillData billData,
    Shop shopDetails,
    bool showCustomer,
  ) {
    final primaryColor = PdfColor.fromHex('#1A1A1A'); // Black
    final accentColor = PdfColor.fromHex('#4A4A4A'); // Dark grey
    final lightBg = PdfColor.fromHex('#F5F5F5'); // Light grey
    final borderColor = PdfColors.grey400;
    final thinBorder = pw.BorderSide(color: borderColor, width: 0.5);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════════
          // HEADER — Logo, Shop Name, Contact Details
          // ═══════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryColor, accentColor],
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo on left
                if (shopDetails.shopLogoBase64 != null &&
                    shopDetails.shopLogoBase64!.isNotEmpty)
                  pw.Container(
                    width: 50,
                    height: 50,
                    margin: const pw.EdgeInsets.only(right: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Image(
                      pw.MemoryImage(base64Decode(shopDetails.shopLogoBase64!)),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                // Shop details in center
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopDetails.shopName.isNotEmpty
                            ? shopDetails.shopName.toUpperCase()
                            : 'STORE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (shopDetails.address.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          shopDetails.address,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          if (shopDetails.phone.isNotEmpty)
                            pw.Text(
                              'Ph: ${shopDetails.phone}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                          if (shopDetails.phone.isNotEmpty &&
                              shopDetails.email != null &&
                              shopDetails.email!.isNotEmpty)
                            pw.Text(
                              ' | ',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                          if (shopDetails.email != null &&
                              shopDetails.email!.isNotEmpty)
                            pw.Text(
                              shopDetails.email!,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // GST on right
                if (shopDetails.gstNumber != null &&
                    shopDetails.gstNumber!.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'GSTIN',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          shopDetails.gstNumber!,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // TAX INVOICE TITLE
          // ═══════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            color: lightBg,
            child: pw.Center(
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // CUSTOMER & INVOICE INFO (3-column layout)
          // ═══════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: primaryColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              children: [
                // Left: Customer Details
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: thinBorder),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          showCustomer &&
                                  billData.customerName != null &&
                                  billData.customerName!.isNotEmpty
                              ? billData.customerName!.toUpperCase()
                              : 'CASH',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (billData.customerPhone != null &&
                            billData.customerPhone!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Mobile: ${billData.customerPhone}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Center: Invoice Details
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: thinBorder),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoLine(
                          'Invoice No',
                          billData.billNumber,
                          bold: true,
                        ),
                        pw.SizedBox(height: 3),
                        _buildInfoLine(
                          'Date',
                          _formatDateNormal(billData.dateTime),
                        ),
                        pw.SizedBox(height: 3),
                        _buildInfoLine('Time', _formatTime(billData.dateTime)),
                      ],
                    ),
                  ),
                ),
                // Right: Owner/Prop details
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (shopDetails.ownerName != null &&
                            shopDetails.ownerName!.isNotEmpty) ...[
                          pw.Text(
                            'Prop: ${shopDetails.ownerName}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ],
                        if (shopDetails.phone.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Ph: ${shopDetails.phone}',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ],
                        if (shopDetails.email != null &&
                            shopDetails.email!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            shopDetails.email!,
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // ITEMS TABLE
          // ═══════════════════════════════════════════
          _buildDynamicItemsTable(
            billData,
            thinBorder,
            pw.BorderSide(color: primaryColor, width: 0.5),
          ),

          // ═══════════════════════════════════════════
          // SUMMARY SECTION — Amounts & Amount in Words
          // ═══════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: primaryColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Amount in Words + Terms
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: thinBorder),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Amount in Words:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _numberToWords(billData.grandTotal),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Total Items: ${billData.items.length}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Text(
                              'Total Qty: ${billData.totalQuantity == billData.totalQuantity.roundToDouble() ? billData.totalQuantity.toInt() : billData.totalQuantity.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (billData.hasAnyReturns) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Returned: ${billData.totalReturnedQuantity == billData.totalReturnedQuantity.roundToDouble() ? billData.totalReturnedQuantity.toInt() : billData.totalReturnedQuantity.toStringAsFixed(2)} qty (-Rs.${billData.totalReturnedAmount.toStringAsFixed(2)})',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange800,
                            ),
                          ),
                        ],
                        if (shopDetails.termsAndConditions != null &&
                            shopDetails.termsAndConditions!.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Terms & Conditions:',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            shopDetails.termsAndConditions!,
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Right: Financial Summary
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      children: [
                        if (billData.hasDiscount)
                          _buildSummaryRow(
                            'Discount',
                            billData.discountAmount!,
                            suffix: billData.discountPercent != null
                                ? ' (${billData.discountPercent!.toStringAsFixed(0)}%)'
                                : '',
                          ),
                        if (billData.hasGst) ...[
                          if (billData.cgstAmount > 0)
                            _buildSummaryRow(
                              'CGST (${billData.cgstPercent.toStringAsFixed(1)}%)',
                              billData.cgstAmount,
                              color: PdfColors.orange800,
                            ),
                          if (billData.sgstAmount > 0)
                            _buildSummaryRow(
                              'SGST (${billData.sgstPercent.toStringAsFixed(1)}%)',
                              billData.sgstAmount,
                              color: PdfColors.orange800,
                            ),
                          if (billData.otherTaxAmount > 0)
                            _buildSummaryRow(
                              '${billData.otherTaxName.isNotEmpty ? billData.otherTaxName : "TAX"} (${billData.otherTaxPercent.toStringAsFixed(1)}%)',
                              billData.otherTaxAmount,
                              color: PdfColors.orange800,
                            ),
                          _buildSummaryRow(
                            'Total Tax',
                            billData.totalTaxAmount,
                            bold: true,
                            color: PdfColors.orange900,
                          ),
                        ],
                        _buildSummaryRow('Sub Total', billData.subtotal),
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 4),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'GRAND TOTAL',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                'Rs. ${billData.grandTotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (billData.hasPaymentInfo) ...[
                          pw.SizedBox(height: 6),
                          _buildSummaryRow(
                            'Paid Amount',
                            billData.paidAmount ?? 0,
                            color: PdfColors.green800,
                          ),
                          if (billData.hasPendingAmount)
                            _buildSummaryRow(
                              'Balance Due',
                              billData.pendingAmount!,
                              bold: true,
                              color: PdfColors.red700,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // TOTAL DUE (if customer has running balance)
          // ═══════════════════════════════════════════
          if (billData.totalDueAmount != null && billData.totalDueAmount! > 0)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              color: PdfColors.orange50,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL DUE AMOUNT',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange900,
                    ),
                  ),
                  pw.Text(
                    'Rs. ${billData.totalDueAmount!.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange900,
                    ),
                  ),
                ],
              ),
            ),

          // ═══════════════════════════════════════════
          // FOOTER — Bank Details, QR Code, Signatures
          // ═══════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: Bank Details + QR Code
                pw.Expanded(
                  flex: 5,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // QR Code
                      if (shopDetails.qrCodeBase64 != null &&
                          shopDetails.qrCodeBase64!.isNotEmpty)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(right: 12),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: 65,
                                height: 65,
                                padding: const pw.EdgeInsets.all(3),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: accentColor,
                                    width: 1,
                                  ),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Image(
                                  pw.MemoryImage(
                                    base64Decode(shopDetails.qrCodeBase64!),
                                  ),
                                  fit: pw.BoxFit.contain,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Scan to Pay',
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Bank Details
                      if ((shopDetails.bankName != null &&
                              shopDetails.bankName!.isNotEmpty) ||
                          (shopDetails.accountNumber != null &&
                              shopDetails.accountNumber!.isNotEmpty))
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: lightBg,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(
                                color: borderColor,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Bank Details',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                if (shopDetails.bankName != null &&
                                    shopDetails.bankName!.isNotEmpty)
                                  pw.Text(
                                    shopDetails.bankName!,
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                if (shopDetails.accountHolderName != null &&
                                    shopDetails.accountHolderName!.isNotEmpty)
                                  pw.Text(
                                    'A/C Name: ${shopDetails.accountHolderName}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                if (shopDetails.accountNumber != null &&
                                    shopDetails.accountNumber!.isNotEmpty)
                                  pw.Text(
                                    'A/C No: ${shopDetails.accountNumber}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                if (shopDetails.ifscCode != null &&
                                    shopDetails.ifscCode!.isNotEmpty)
                                  pw.Text(
                                    'IFSC: ${shopDetails.ifscCode}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right: Signatures
                pw.Expanded(
                  flex: 4,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Customer Signature
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.SizedBox(height: 25),
                          pw.Container(
                            width: 90,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: PdfColors.grey500,
                                  width: 0.5,
                                ),
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
                      // Authorized Signature
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'For ${shopDetails.shopName.isNotEmpty ? shopDetails.shopName.toUpperCase() : 'STORE'}',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          if (shopDetails.signatureBase64 != null &&
                              shopDetails.signatureBase64!.isNotEmpty)
                            pw.Container(
                              width: 70,
                              height: 30,
                              child: pw.Image(
                                pw.MemoryImage(
                                  base64Decode(shopDetails.signatureBase64!),
                                ),
                                fit: pw.BoxFit.contain,
                              ),
                            )
                          else
                            pw.SizedBox(height: 20),
                          pw.Container(
                            width: 90,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: PdfColors.grey500,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 3),
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
          ),
        ],
      ),
    );
  }

  /// Helper for info line in customer/invoice section
  pw.Widget _buildInfoLine(String label, String value, {bool bold = false}) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Helper for summary rows
  pw.Widget _buildSummaryRow(
    String label,
    double amount, {
    bool bold = false,
    String suffix = '',
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label$suffix',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
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

  /// Convert number to words (Indian numbering system)
  String _numberToWords(double amount) {
    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    if (rupees == 0 && paise == 0) return 'Zero Rupees Only';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String twoDigits(int n) {
      if (n < 20) return ones[n];
      return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
    }

    String threeDigits(int n) {
      if (n < 100) return twoDigits(n);
      return '${ones[n ~/ 100]} Hundred ${twoDigits(n % 100)}'.trim();
    }

    String result = '';
    if (rupees >= 10000000) {
      result += '${twoDigits(rupees ~/ 10000000)} Crore ';
      result += threeDigits((rupees % 10000000) ~/ 100000);
      if ((rupees % 10000000) ~/ 100000 > 0) result += ' Lakh ';
    } else if (rupees >= 100000) {
      result += '${twoDigits(rupees ~/ 100000)} Lakh ';
    }
    if (rupees >= 1000) {
      final thousands = (rupees % 100000) ~/ 1000;
      if (thousands > 0) result += '${twoDigits(thousands)} Thousand ';
    }
    final remainder = rupees % 1000;
    if (remainder > 0) result += threeDigits(remainder);

    result = result.trim();
    if (result.isEmpty) result = 'Zero';

    String finalResult = '$result Rupees';
    if (paise > 0) {
      finalResult += ' and ${twoDigits(paise)} Paise';
    }
    return '$finalResult Only';
  }

  // ═══════════════════════════════════════════
  // COMPACT HELPERS — for half-A4 normal bill
  // ═══════════════════════════════════════════

  /// Compact info row (label: value) for customer/invoice section
  pw.Widget _buildCompactInfoRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
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
  pw.Widget _buildCompactHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        textAlign: align,
      ),
    );
  }

  /// Compact table data cell
  pw.Widget _buildCompactCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: align,
      ),
    );
  }

  /// Build dynamic items table based on visible columns from settings
  pw.Widget _buildDynamicItemsTable(
    PrintBillData billData,
    pw.BorderSide thinBorder,
    pw.BorderSide borderSide,
  ) {
    final settings = BillReportSettingsService.instance;

    // Define column configurations
    final allColumns = <String, _ColumnConfig>{
      'sr_no': _ColumnConfig(
        'Sr.',
        const pw.FixedColumnWidth(28),
        pw.TextAlign.center,
      ),
      'product_name': _ColumnConfig(
        'Particulars',
        const pw.FlexColumnWidth(3.5),
        pw.TextAlign.left,
      ),
      'hsn_code': _ColumnConfig(
        'HSN',
        const pw.FixedColumnWidth(55),
        pw.TextAlign.center,
      ),
      'company': _ColumnConfig(
        'Company',
        const pw.FixedColumnWidth(70),
        pw.TextAlign.left,
      ),
      'quantity': _ColumnConfig(
        'Qty',
        const pw.FixedColumnWidth(35),
        pw.TextAlign.center,
      ),
      'unit': _ColumnConfig(
        'Unit',
        const pw.FixedColumnWidth(35),
        pw.TextAlign.center,
      ),
      'rate': _ColumnConfig(
        'Rate',
        const pw.FixedColumnWidth(55),
        pw.TextAlign.right,
      ),
      'discount': _ColumnConfig(
        'Disc',
        const pw.FixedColumnWidth(45),
        pw.TextAlign.right,
      ),
      'tax': _ColumnConfig(
        'Tax',
        const pw.FixedColumnWidth(45),
        pw.TextAlign.right,
      ),
      'amount': _ColumnConfig(
        'Amount',
        const pw.FixedColumnWidth(65),
        pw.TextAlign.right,
      ),
    };

    // Get visible columns in order - ensure at least basic columns are shown
    final visibleColumnIds = <String>[];
    for (final colId in [
      'sr_no',
      'product_name',
      'hsn_code',
      'company',
      'quantity',
      'unit',
      'rate',
      'discount',
      'tax',
      'amount',
    ]) {
      if (settings.isColumnVisible(colId)) {
        visibleColumnIds.add(colId);
      }
    }

    // Fallback: if no columns are visible, show default columns
    if (visibleColumnIds.isEmpty) {
      visibleColumnIds.addAll([
        'sr_no',
        'product_name',
        'quantity',
        'rate',
        'amount',
      ]);
    }

    // Build column widths map
    final columnWidths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < visibleColumnIds.length; i++) {
      columnWidths[i] = allColumns[visibleColumnIds[i]]!.width;
    }

    // Build header row
    final headerCells = visibleColumnIds.map((colId) {
      final config = allColumns[colId]!;
      return _buildCompactHeaderCell(config.header, align: config.align);
    }).toList();

    // Build item rows
    final itemRows = <pw.TableRow>[];
    for (int index = 0; index < billData.items.length; index++) {
      final item = billData.items[index];

      final cells = visibleColumnIds.map((colId) {
        switch (colId) {
          case 'sr_no':
            return _buildCompactCell(
              '${index + 1}',
              align: pw.TextAlign.center,
            );
          case 'product_name':
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                item.name.isNotEmpty ? item.name : '-',
                style: const pw.TextStyle(fontSize: 9),
              ),
            );
          case 'hsn_code':
            return _buildCompactCell(
              (item.hsnCode != null && item.hsnCode!.isNotEmpty)
                  ? item.hsnCode!
                  : '-',
              align: pw.TextAlign.center,
            );
          case 'company':
            return _buildCompactCell(
              (item.companyName != null && item.companyName!.isNotEmpty)
                  ? item.companyName!
                  : '-',
              align: pw.TextAlign.left,
            );
          case 'quantity':
            return _buildCompactCell(
              item.displayQuantity,
              align: pw.TextAlign.center,
            );
          case 'unit':
            return _buildCompactCell(
              '-',
              align: pw.TextAlign.center,
            ); // Unit not available in PrintBillItem
          case 'rate':
            return _buildCompactCell(
              item.rate > 0 ? item.rate.toStringAsFixed(2) : '-',
              align: pw.TextAlign.right,
            );
          case 'discount':
            return _buildCompactCell(
              '-',
              align: pw.TextAlign.right,
            ); // Discount per item not available
          case 'tax':
            final taxAmt = item.cgstAmount + item.sgstAmount;
            return _buildCompactCell(
              taxAmt > 0 ? taxAmt.toStringAsFixed(2) : '-',
              align: pw.TextAlign.right,
            );
          case 'amount':
            return _buildCompactCell(
              item.amount > 0 ? item.amount.toStringAsFixed(2) : '-',
              align: pw.TextAlign.right,
            );
          default:
            return _buildCompactCell('-');
        }
      }).toList();

      itemRows.add(pw.TableRow(children: cells));

      // Add GST sub-row if tax column is visible and item has GST
      if (settings.isColumnVisible('tax') && item.hasItemGst) {
        final gstCells = visibleColumnIds.map((colId) {
          if (colId == 'product_name') {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 8,
                top: 0,
                bottom: 2,
                right: 4,
              ),
              child: pw.Row(
                children: [
                  if (item.cgstPercent > 0)
                    pw.Text(
                      'CGST(${item.cgstPercent.toStringAsFixed(1)}%): ${item.cgstAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.orange800,
                      ),
                    ),
                  if (item.cgstPercent > 0 && item.sgstPercent > 0)
                    pw.Text(
                      '  |  ',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  if (item.sgstPercent > 0)
                    pw.Text(
                      'SGST(${item.sgstPercent.toStringAsFixed(1)}%): ${item.sgstAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.orange800,
                      ),
                    ),
                ],
              ),
            );
          }
          return _buildCompactCell('');
        }).toList();
        itemRows.add(pw.TableRow(children: gstCells));
      }
    }

    return pw.Table(
      border: pw.TableBorder(horizontalInside: thinBorder, bottom: borderSide),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headerCells,
        ),
        ...itemRows,
      ],
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
    // Standard 80mm thermal paper width = ~48mm printable
    const receiptWidth = double.infinity;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // ═══════════════════════════════════════════════
        // SHOP HEADER - Two Column Layout
        // ═══════════════════════════════════════════════
        pw.Container(
          width: receiptWidth,
          child: pw.Column(
            children: [
              // Two Column Layout: Logo | Shop Name & Address
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Column 1: Logo (centered)
                  if (shopDetails.shopLogoBase64 != null &&
                      shopDetails.shopLogoBase64!.isNotEmpty)
                    pw.Container(
                      width: 50,
                      child: pw.Center(
                        child: pw.Container(
                          width: 45,
                          height: 45,
                          child: pw.Image(
                            pw.MemoryImage(base64Decode(shopDetails.shopLogoBase64!)),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  // Column 2: Shop Name & Address (start aligned)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shopDetails.shopName.isNotEmpty
                              ? shopDetails.shopName.toUpperCase()
                              : 'STORE',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: pw.TextAlign.left,
                        ),
                        if (shopDetails.address.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            shopDetails.address,
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.left,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Proprietor Name - right aligned
              if (shopDetails.ownerName != null &&
                  shopDetails.ownerName!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Prop: ${shopDetails.ownerName}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
              // Phone - right aligned
              if (shopDetails.phone.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Ph: ${shopDetails.phone}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
              // GST Number
              if (shopDetails.gstNumber != null &&
                  shopDetails.gstNumber!.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'GSTIN: ${shopDetails.gstNumber}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        
        // Dashed Separator
        pw.SizedBox(height: 4),
        _buildDashedDivider(),
        pw.SizedBox(height: 4),
        
        // ═══════════════════════════════════════════════
        // INVOICE INFO
        // ═══════════════════════════════════════════════
        pw.Container(
          width: receiptWidth,
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Bill No:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    billData.billNumber,
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    _formatDate(billData.dateTime),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              // Customer Info
              if ((showCustomer && billData.customerName != null && billData.customerName!.isNotEmpty) ||
                  (billData.customerPhone != null && billData.customerPhone!.isNotEmpty)) ...[
                pw.SizedBox(height: 2),
                if (showCustomer && billData.customerName != null && billData.customerName!.isNotEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Customer:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(billData.customerName!, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                if (billData.customerPhone != null && billData.customerPhone!.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Mobile:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(billData.customerPhone!, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),

        // Dashed Separator
        pw.SizedBox(height: 4),
        _buildDashedDivider(),
        
        // ═══════════════════════════════════════════════
        // ITEMS TABLE HEADER
        // ═══════════════════════════════════════════════
        pw.SizedBox(height: 4),
        pw.Container(
          width: receiptWidth,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  'ITEM',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(
                width: 30,
                child: pw.Text(
                  'QTY',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: 40,
                child: pw.Text(
                  'RATE',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: 50,
                child: pw.Text(
                  'AMT',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        
        // ═══════════════════════════════════════════════
        // ITEMS LIST
        // ═══════════════════════════════════════════════
        ...billData.items.expand(
          (item) => [
            pw.Container(
              width: receiptWidth,
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.name,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        if (item.companyName != null && item.companyName!.isNotEmpty)
                          pw.Text(
                            item.companyName!,
                            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                        if (item.hsnCode != null && item.hsnCode!.isNotEmpty)
                          pw.Text(
                            'HSN:${item.hsnCode}',
                            style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(
                    width: 30,
                    child: pw.Text(
                      item.displayQuantity,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      item.rate.toStringAsFixed(2),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(
                      item.amount.toStringAsFixed(2),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // Returned quantity
            if (item.hasReturns)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, bottom: 2),
                child: pw.Text(
                  'Ret: -${item.returnedQuantity} qty (-Rs.${item.returnedAmount.toStringAsFixed(2)})',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.orange800, fontWeight: pw.FontWeight.bold),
                ),
              ),
            // Per-item GST
            if (item.hasItemGst)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, bottom: 2),
                child: pw.Text(
                  'GST: CGST ${item.cgstPercent.toStringAsFixed(1)}%=${item.cgstAmount.toStringAsFixed(2)} | SGST ${item.sgstPercent.toStringAsFixed(1)}%=${item.sgstAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                ),
              ),
          ],
        ),
        
        // Items Separator
        pw.SizedBox(height: 2),
        _buildDashedDivider(),
        pw.SizedBox(height: 4),
        
        // ═══════════════════════════════════════════════
        // TOTALS SECTION
        // ═══════════════════════════════════════════════
        pw.Container(
          width: receiptWidth,
          child: pw.Column(
            children: [
              // Item Count & Qty
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Items: ${billData.items.length}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Qty: ${billData.totalQuantity == billData.totalQuantity.roundToDouble() ? billData.totalQuantity.toInt() : billData.totalQuantity.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Returns summary
              if (billData.hasAnyReturns) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Returned:', style: pw.TextStyle(fontSize: 8, color: PdfColors.orange800)),
                    pw.Text('-Rs.${billData.totalReturnedAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.orange800, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 2),
              ],
              
              // Subtotal
              _buildPOSTotalRow('Subtotal', billData.subtotal),
              
              // Discount
              if (billData.discountAmount != null && billData.discountAmount! > 0) ...[
                pw.SizedBox(height: 2),
                _buildPOSTotalRow(
                  'Discount${billData.discountPercent != null ? ' (${billData.discountPercent!.toStringAsFixed(0)}%)' : ''}',
                  -billData.discountAmount!,
                ),
              ],
              
              // GST Breakdown
              if (billData.hasGst) ...[
                pw.SizedBox(height: 4),
                pw.Container(
                  width: receiptWidth,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                  ),
                  child: pw.Column(
                    children: [
                      if (billData.cgstAmount > 0)
                        _buildPOSTotalRow('CGST (${billData.cgstPercent.toStringAsFixed(1)}%)', billData.cgstAmount),
                      if (billData.sgstAmount > 0) ...[
                        pw.SizedBox(height: 1),
                        _buildPOSTotalRow('SGST (${billData.sgstPercent.toStringAsFixed(1)}%)', billData.sgstAmount),
                      ],
                      if (billData.otherTaxAmount > 0) ...[
                        pw.SizedBox(height: 1),
                        _buildPOSTotalRow('${billData.otherTaxName.isNotEmpty ? billData.otherTaxName : "Tax"} (${billData.otherTaxPercent.toStringAsFixed(1)}%)', billData.otherTaxAmount),
                      ],
                      pw.SizedBox(height: 2),
                      _buildPOSTotalRow('Total Tax', billData.totalTaxAmount, bold: true),
                    ],
                  ),
                ),
                if (billData.isTaxInclusive) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '* Prices inclusive of GST',
                    style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                  ),
                ],
              ],
            ],
          ),
        ),
        
        // Grand Total Separator
        pw.SizedBox(height: 4),
        pw.Container(
          width: receiptWidth,
          height: 1.5,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 4),
        
        // ═══════════════════════════════════════════════
        // GRAND TOTAL - Prominent
        // ═══════════════════════════════════════════════
        pw.Container(
          width: receiptWidth,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'GRAND TOTAL',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Rs.${billData.grandTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        // Amount in Words
        pw.Container(
          width: receiptWidth,
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            _numberToWords(billData.grandTotal),
            style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Container(
          width: receiptWidth,
          height: 1.5,
          color: PdfColors.black,
        ),
        
        // ═══════════════════════════════════════════════
        // PAYMENT STATUS
        // ═══════════════════════════════════════════════
        if (billData.hasPaymentInfo) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            width: receiptWidth,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5),
            ),
            child: pw.Column(
              children: [
                if (billData.paidAmount != null)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('PAID', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.Text('Rs.${billData.paidAmount!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ],
                  ),
                if (billData.hasPendingAmount) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('BALANCE DUE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                      pw.Text('Rs.${billData.pendingAmount!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        
        // Total Due (Running Balance)
        if (billData.totalDueAmount != null && billData.totalDueAmount! > 0) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            width: receiptWidth,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL DUE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs.${billData.totalDueAmount!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
              ],
            ),
          ),
        ],
        
        // Separator before footer
        pw.SizedBox(height: 6),
        _buildDashedDivider(),
        pw.SizedBox(height: 6),
        
        // ═══════════════════════════════════════════════
        // FOOTER - Bank & QR Code
        // ═══════════════════════════════════════════════
        if ((shopDetails.qrCodeBase64 != null && shopDetails.qrCodeBase64!.isNotEmpty) ||
            (shopDetails.bankName != null && shopDetails.bankName!.isNotEmpty) ||
            (shopDetails.accountNumber != null && shopDetails.accountNumber!.isNotEmpty))
          pw.Container(
            width: receiptWidth,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // QR Code
                if (shopDetails.qrCodeBase64 != null && shopDetails.qrCodeBase64!.isNotEmpty)
                  pw.Container(
                    width: 55,
                    height: 55,
                    margin: const pw.EdgeInsets.only(right: 8),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: 50,
                          height: 50,
                          child: pw.Image(
                            pw.MemoryImage(base64Decode(shopDetails.qrCodeBase64!)),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                        pw.Text('Scan to Pay', style: const pw.TextStyle(fontSize: 6)),
                      ],
                    ),
                  ),
                // Bank Details
                if ((shopDetails.bankName != null && shopDetails.bankName!.isNotEmpty) ||
                    (shopDetails.accountNumber != null && shopDetails.accountNumber!.isNotEmpty))
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.only(left: 4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Bank Details', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          if (shopDetails.bankName != null && shopDetails.bankName!.isNotEmpty)
                            pw.Text(shopDetails.bankName!, style: const pw.TextStyle(fontSize: 6)),
                          if (shopDetails.accountHolderName != null && shopDetails.accountHolderName!.isNotEmpty)
                            pw.Text('A/C: ${shopDetails.accountHolderName}', style: const pw.TextStyle(fontSize: 6)),
                          if (shopDetails.accountNumber != null && shopDetails.accountNumber!.isNotEmpty)
                            pw.Text('No: ${shopDetails.accountNumber}', style: const pw.TextStyle(fontSize: 6)),
                          if (shopDetails.ifscCode != null && shopDetails.ifscCode!.isNotEmpty)
                            pw.Text('IFSC: ${shopDetails.ifscCode}', style: const pw.TextStyle(fontSize: 6)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        
        // Terms and Conditions
        if (shopDetails.termsAndConditions != null &&
            shopDetails.termsAndConditions!.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            width: receiptWidth,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Terms & Conditions:',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  shopDetails.termsAndConditions!,
                  style: const pw.TextStyle(fontSize: 6),
                ),
              ],
            ),
          ),
        ],
        
        // Thank You Message
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                '*** THANK YOU ***',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Please Visit Again!',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  /// Build dashed divider for POS receipt (full width)
  pw.Widget _buildDashedDivider() {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: List.generate(
          50,
          (index) => pw.Expanded(
            child: pw.Container(
              height: 0.5,
              margin: const pw.EdgeInsets.symmetric(horizontal: 0.5),
              color: PdfColors.grey700,
            ),
          ),
        ),
      ),
    );
  }

  /// Build total row for POS receipt
  pw.Widget _buildPOSTotalRow(String label, double amount, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          'Rs.${amount.abs().toStringAsFixed(2)}${amount < 0 ? ' -' : ''}',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
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
    final billId = billData.billNumber;

    // Prevent concurrent PDF generation for the same bill
    if (_generatingBills.contains(billId)) {
      debugPrint(
        '[PdfBillService] PDF generation already in progress for bill: $billId',
      );
      throw Exception('PDF generation already in progress for this bill');
    }

    _generatingBills.add(billId);

    try {
      debugPrint('[PdfBillService] savePdfToFile started for bill: $billId');

      // Check bill type setting
      debugPrint('[PdfBillService] Getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final billType = prefs.getString('bill_type') ?? 'pos';
      debugPrint('[PdfBillService] Bill type: $billType');

      debugPrint('[PdfBillService] Generating PDF document...');
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
      debugPrint('[PdfBillService] PDF document generated successfully');

      debugPrint('[PdfBillService] Saving PDF bytes...');
      final bytes = await pdf.save();
      debugPrint('[PdfBillService] PDF bytes saved: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        throw Exception('PDF generation failed: empty bytes');
      }

      debugPrint('[PdfBillService] Getting application documents directory...');
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('[PdfBillService] Directory: ${dir.path}');

      // Create a unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'bill_${billData.billNumber.replaceAll('/', '_')}_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');

      debugPrint('[PdfBillService] Writing file to: ${file.path}');
      await file.writeAsBytes(bytes, flush: true);

      // Verify file was written successfully
      if (!file.existsSync()) {
        throw Exception('Failed to write PDF file to storage');
      }

      final actualSize = file.lengthSync();
      if (actualSize == 0) {
        throw Exception('PDF file was written but is empty');
      }

      if (actualSize != bytes.length) {
        debugPrint(
          '[PdfBillService] WARNING: File size mismatch. Expected: ${bytes.length}, Actual: $actualSize',
        );
      }

      debugPrint(
        '[PdfBillService] File written successfully: $actualSize bytes',
      );

      return file;
    } catch (e, stack) {
      debugPrint('[PdfBillService] ERROR in savePdfToFile: $e');
      debugPrint('[PdfBillService] Stack trace: $stack');
      rethrow;
    } finally {
      _generatingBills.remove(billId);
    }
  }

  /// Share the bill as PDF via the system share sheet
  Future<void> shareBillAsPdf({
    required PrintBillData billData,
    required Shop shopDetails,
  }) async {
    try {
      debugPrint(
        '[PdfBillService] Starting shareBillAsPdf for bill: ${billData.billNumber}',
      );

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
      pdf = await generateBillPdf(billData: billData, shopDetails: shopDetails);
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
      pdf = await generateBillPdf(billData: billData, shopDetails: shopDetails);
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'bill_${billData.billNumber.replaceAll('/', '_')}.pdf',
    );
  }
}

/// Helper class for column configuration
class _ColumnConfig {
  final String header;
  final pw.TableColumnWidth width;
  final pw.TextAlign align;

  const _ColumnConfig(this.header, this.width, this.align);
}
