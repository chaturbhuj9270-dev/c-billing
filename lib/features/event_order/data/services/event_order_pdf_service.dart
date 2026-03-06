import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event_order.dart';
import '../../domain/entities/order_item.dart';
import '../../../shop/domain/entities/shop.dart';

/// Service for generating PDF for Event Orders / Sales Orders
class EventOrderPdfService {
  static final EventOrderPdfService _instance =
      EventOrderPdfService._internal();
  factory EventOrderPdfService() => _instance;
  EventOrderPdfService._internal();

  bool _isGenerating = false;

  /// Reset the generating flag - useful for error recovery
  void resetGeneratingState() {
    _isGenerating = false;
  }

  /// Check if PDF generation is in progress
  bool get isGenerating => _isGenerating;

  /// Generate PDF document for an Event Order
  Future<pw.Document> generateEventOrderPdf({
    required EventOrder order,
    required Shop shopDetails,
  }) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) =>
            _buildOrderContent(order, shopDetails, dateFormatter),
      ),
    );

    return pdf;
  }

  /// Build the main content of the PDF - Bill-like UI
  pw.Widget _buildOrderContent(
    EventOrder order,
    Shop shopDetails,
    DateFormat dateFormatter,
  ) {
    final isEvent = order.orderType == OrderType.event;
    final primaryColor = PdfColor.fromHex('#1A1A1A');
    final accentColor = PdfColor.fromHex('#4A4A4A');
    final lightBg = PdfColor.fromHex('#F5F5F5');
    final borderSide = pw.BorderSide(color: primaryColor, width: 0.8);
    final thinBorder = pw.BorderSide(color: PdfColors.grey400, width: 0.5);

    // Calculate totals
    final subEventsTotal = order.subEvents.fold(
      0.0,
      (sum, e) => sum + e.charges,
    );
    final mainEventCharges = order.eventCharges;
    final allEventsTotal = mainEventCharges + subEventsTotal;
    final productsTotal = order.items.fold(
      0.0,
      (sum, item) => sum + item.total,
    );
    final grandTotal = allEventsTotal + productsTotal;
    final balanceDue = grandTotal - order.advanceAmount;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // SECTION 1: SHOP HEADER (Gradient Background)
          // ═══════════════════════════════════════════════════════════════
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
                  _buildSafeImage(
                    base64String: shopDetails.shopLogoBase64!,
                    width: 50,
                    height: 50,
                    margin: const pw.EdgeInsets.only(right: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    padding: const pw.EdgeInsets.all(4),
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
                          style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                          if (shopDetails.phone.isNotEmpty &&
                              shopDetails.email != null &&
                              shopDetails.email!.isNotEmpty)
                            pw.Text(
                              ' | ',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                          if (shopDetails.email != null &&
                              shopDetails.email!.isNotEmpty)
                            pw.Text(
                              shopDetails.email!,
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // GST badge on right
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

          // ═══════════════════════════════════════════════════════════════
          // SECTION 2: INVOICE TITLE BAR
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            color: lightBg,
            child: pw.Center(
              child: pw.Text(
                isEvent ? 'EVENT INVOICE' : 'ORDER INVOICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 3: CUSTOMER & INVOICE INFO (3-Column Layout)
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            child: pw.Row(
              children: [
                // Left: Customer Details (BILL TO)
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
                          order.customerName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (order.customerContact.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Mobile: ${order.customerContact}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                        if (order.customerAddress != null &&
                            order.customerAddress!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Address: ${order.customerAddress}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Center: Invoice/Event Details
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
                          isEvent ? 'Event' : 'Order',
                          order.orderName,
                          bold: true,
                        ),
                        pw.SizedBox(height: 3),
                        _buildInfoLine(
                          isEvent ? 'Event Date' : 'Delivery Date',
                          dateFormatter.format(order.eventDate),
                        ),
                        pw.SizedBox(height: 3),
                        _buildInfoLine(
                          'Status',
                          order.status.displayName.toUpperCase(),
                        ),
                        if (order.eventLocation != null &&
                            order.eventLocation!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _buildInfoLine('Location', order.eventLocation!),
                        ],
                      ],
                    ),
                  ),
                ),
                // Right: Owner/Proprietor Details
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
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Created: ${DateFormat('dd/MM/yy').format(order.createdAt)}',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 4: EVENT DETAILS TABLE (Main Event + Sub-Events)
          // ═══════════════════════════════════════════════════════════════
          if (isEvent && order.subEvents.isNotEmpty)
            _buildEventDetailsTable(
              order,
              dateFormatter,
              borderSide,
              thinBorder,
            ),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 5: PRODUCTS TABLE
          // ═══════════════════════════════════════════════════════════════
          if (order.items.isNotEmpty)
            _buildProductsTable(order.items, borderSide, thinBorder),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 6: SUMMARY (Notes + Totals)
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Notes, Description, Terms
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
                          _numberToWords(order.totalAmount),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (order.description != null &&
                            order.description!.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Description:',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            order.description!,
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Notes:',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            order.notes!,
                            style: const pw.TextStyle(fontSize: 7),
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
                        if (isEvent && mainEventCharges > 0)
                          _buildSummaryRow(
                            'Main Event Charges',
                            mainEventCharges,
                          ),
                        if (isEvent && order.subEvents.isNotEmpty)
                          _buildSummaryRow('Sub-Events Total', subEventsTotal),
                        if (isEvent &&
                            (mainEventCharges > 0 ||
                                order.subEvents.isNotEmpty))
                          _buildSummaryRow(
                            'Events Total',
                            allEventsTotal,
                            color: PdfColors.blue800,
                          ),
                        if (order.items.isNotEmpty)
                          _buildSummaryRow('Products Total', productsTotal),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          margin: const pw.EdgeInsets.only(top: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'GRAND TOTAL',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'Rs. ${grandTotal.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow(
                          'Advance Paid',
                          order.advanceAmount,
                          color: PdfColors.green800,
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          margin: const pw.EdgeInsets.only(top: 4),
                          decoration: pw.BoxDecoration(
                            color: balanceDue > 0
                                ? PdfColors.orange50
                                : PdfColors.green50,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'BALANCE DUE',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: balanceDue > 0
                                      ? PdfColors.orange900
                                      : PdfColors.green900,
                                ),
                              ),
                              pw.Text(
                                'Rs. ${balanceDue.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: balanceDue > 0
                                      ? PdfColors.orange900
                                      : PdfColors.green900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 7: SIGNATURE
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: thinBorder)),
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
                // Generated date
                pw.Text(
                  'Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                // Shop Signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'For ${shopDetails.shopName.isNotEmpty ? shopDetails.shopName.toUpperCase() : "STORE"}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (shopDetails.signatureBase64 != null &&
                        shopDetails.signatureBase64!.isNotEmpty) ...[
                      _buildSafeImage(
                        base64String: shopDetails.signatureBase64!,
                        width: 60,
                        height: 25,
                      ),
                    ] else ...[
                      pw.SizedBox(height: 12),
                    ],
                    pw.Text(
                      'Authorized Signatory',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 8: BANK DETAILS & QR CODE
          // ═══════════════════════════════════════════════════════════════
          if ((shopDetails.qrCodeBase64 != null &&
                  shopDetails.qrCodeBase64!.isNotEmpty) ||
              (shopDetails.bankName != null &&
                  shopDetails.bankName!.isNotEmpty) ||
              (shopDetails.accountNumber != null &&
                  shopDetails.accountNumber!.isNotEmpty))
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // QR Code on left
                  if (shopDetails.qrCodeBase64 != null &&
                      shopDetails.qrCodeBase64!.isNotEmpty)
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        children: [
                          _buildSafeImage(
                            base64String: shopDetails.qrCodeBase64!,
                            width: 70,
                            height: 70,
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Scan to Pay',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ),
                    ),
                  // Bank Details on right
                  if ((shopDetails.bankName != null &&
                          shopDetails.bankName!.isNotEmpty) ||
                      (shopDetails.accountNumber != null &&
                          shopDetails.accountNumber!.isNotEmpty))
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey400,
                            width: 0.5,
                          ),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Bank Details',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            if (shopDetails.bankName != null &&
                                shopDetails.bankName!.isNotEmpty)
                              pw.Text(
                                shopDetails.bankName!,
                                style: const pw.TextStyle(fontSize: 8),
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
        ],
      ),
    );
  }

  /// Build Event Details Table (Main Event + Sub-Events combined)
  pw.Widget _buildEventDetailsTable(
    EventOrder order,
    DateFormat dateFormatter,
    pw.BorderSide borderSide,
    pw.BorderSide thinBorder,
  ) {
    final subEventsTotal = order.subEvents.fold(
      0.0,
      (sum, e) => sum + e.charges,
    );
    final mainEventCharges = order.eventCharges;
    final allEventsTotal = mainEventCharges + subEventsTotal;

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Table Header Section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EVENT DETAILS',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Main Event: ${order.orderName}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '${order.subEvents.length} Sub-Event(s)',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sub-Events Table
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: thinBorder,
              verticalInside: thinBorder,
              left: thinBorder,
              right: thinBorder,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5), // Sr
              1: const pw.FlexColumnWidth(2.8), // Sub-Event Name
              2: const pw.FlexColumnWidth(1.3), // Date
              3: const pw.FlexColumnWidth(1.2), // Charges
              4: const pw.FlexColumnWidth(2.0), // Notes
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Sr', isHeader: true),
                  _buildTableCell(
                    'Event / Sub-Event Name',
                    isHeader: true,
                    align: pw.TextAlign.left,
                  ),
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell(
                    'Charges',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(
                    'Notes',
                    isHeader: true,
                    align: pw.TextAlign.left,
                  ),
                ],
              ),
              // Main Event Row (highlighted)
              if (mainEventCharges > 0)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.amber50),
                  children: [
                    _buildTableCell('★', isHeader: true),
                    _buildTableCell(
                      '${order.orderName} (Main Event)',
                      isHeader: true,
                      align: pw.TextAlign.left,
                    ),
                    _buildTableCell(dateFormatter.format(order.eventDate)),
                    _buildTableCell(
                      'Rs. ${mainEventCharges.toStringAsFixed(0)}',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell('-', align: pw.TextAlign.left),
                  ],
                ),
              // Sub-Event Data Rows
              ...order.subEvents.asMap().entries.map((entry) {
                final idx = entry.key;
                final subEvent = entry.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: idx % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                  ),
                  children: [
                    _buildTableCell('${idx + 1}'),
                    _buildTableCell(subEvent.name, align: pw.TextAlign.left),
                    _buildTableCell(dateFormatter.format(subEvent.date)),
                    _buildTableCell(
                      'Rs. ${subEvent.charges.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      subEvent.notes ?? '-',
                      align: pw.TextAlign.left,
                    ),
                  ],
                );
              }),
              // Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableCell(''),
                  _buildTableCell(
                    'EVENTS TOTAL',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(''),
                  _buildTableCell(
                    'Rs. ${allEventsTotal.toStringAsFixed(0)}',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(''),
                ],
              ),
            ],
          ),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
          ),
        ],
      ),
    );
  }

  /// Build image safely with base64 decoding error handling
  pw.Widget _buildSafeImage({
    required String base64String,
    double? width,
    double? height,
    pw.EdgeInsets? margin,
    pw.EdgeInsets? padding,
    pw.BoxDecoration? decoration,
    pw.BoxFit fit = pw.BoxFit.contain,
  }) {
    try {
      final bytes = base64Decode(base64String);
      if (bytes.isEmpty) {
        debugPrint('[EventOrderPdfService] Empty image bytes');
        return pw.SizedBox(width: width, height: height);
      }
      return pw.Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: pw.Image(pw.MemoryImage(bytes), fit: fit),
      );
    } catch (e) {
      debugPrint('[EventOrderPdfService] Error decoding image: $e');
      return pw.SizedBox(width: width, height: height);
    }
  }

  /// Info line helper (Label: Value)
  pw.Widget _buildInfoLine(String label, String value, {bool bold = false}) {
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

  /// Summary row helper
  pw.Widget _buildSummaryRow(String label, double amount, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
          pw.Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Number to words converter
  String _numberToWords(double number) {
    final units = [
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

    if (number == 0) return 'Zero Rupees Only';

    int rupees = number.floor();
    int paise = ((number - rupees) * 100).round();

    String result = '';

    if (rupees >= 10000000) {
      result += '${units[rupees ~/ 10000000]} Crore ';
      rupees %= 10000000;
    }
    if (rupees >= 100000) {
      result += '${units[rupees ~/ 100000]} Lakh ';
      rupees %= 100000;
    }
    if (rupees >= 1000) {
      int thousands = rupees ~/ 1000;
      if (thousands < 20) {
        result += '${units[thousands]} Thousand ';
      } else {
        result +=
            '${tens[thousands ~/ 10]}${thousands % 10 > 0 ? " ${units[thousands % 10]}" : ""} Thousand ';
      }
      rupees %= 1000;
    }
    if (rupees >= 100) {
      result += '${units[rupees ~/ 100]} Hundred ';
      rupees %= 100;
    }
    if (rupees >= 20) {
      result += tens[rupees ~/ 10];
      if (rupees % 10 > 0) result += ' ${units[rupees % 10]}';
      result += ' ';
    } else if (rupees > 0) {
      result += '${units[rupees]} ';
    }

    result += 'Rupees';
    if (paise > 0) {
      result += ' and ';
      if (paise >= 20) {
        result += tens[paise ~/ 10];
        if (paise % 10 > 0) result += ' ${units[paise % 10]}';
      } else {
        result += units[paise];
      }
      result += ' Paise';
    }
    result += ' Only';

    return result.trim();
  }

  /// Build products table for Sales Order type or Event products
  pw.Widget _buildProductsTable(
    List<OrderItem> items,
    pw.BorderSide borderSide,
    pw.BorderSide thinBorder, {
    String title = 'PRODUCTS',
  }) {
    final productsTotal = items.fold(0.0, (sum, item) => sum + item.total);

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '${items.length} Item(s)',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: thinBorder,
              verticalInside: thinBorder,
              left: thinBorder,
              right: thinBorder,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(2.8),
              2: const pw.FlexColumnWidth(0.8),
              3: const pw.FlexColumnWidth(1.0),
              4: const pw.FlexColumnWidth(0.7),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Sr', isHeader: true),
                  _buildTableCell(
                    'Product Name',
                    isHeader: true,
                    align: pw.TextAlign.left,
                  ),
                  _buildTableCell('Qty', isHeader: true),
                  _buildTableCell(
                    'Rate',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell('Disc', isHeader: true),
                  _buildTableCell(
                    'Amount',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              // Data rows
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: idx % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                  ),
                  children: [
                    _buildTableCell('${idx + 1}'),
                    _buildTableCell(item.productName, align: pw.TextAlign.left),
                    _buildTableCell('${item.quantity}'),
                    _buildTableCell(
                      'Rs. ${item.rate.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      item.discountPercent > 0
                          ? '${item.discountPercent.toStringAsFixed(0)}%'
                          : '-',
                    ),
                    _buildTableCell(
                      'Rs. ${item.total.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
              // Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green100),
                children: [
                  _buildTableCell(''),
                  _buildTableCell(
                    'PRODUCTS TOTAL',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(
                    'Rs. ${productsTotal.toStringAsFixed(0)}',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
          ),
        ],
      ),
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  /// Share the order as PDF via the system share sheet
  Future<void> shareOrderAsPdf({
    required EventOrder order,
    required Shop shopDetails,
  }) async {
    if (_isGenerating) {
      debugPrint(
        '[EventOrderPdfService] Already generating PDF, resetting flag and retrying...',
      );
      // Reset flag and allow retry instead of silently returning
      _isGenerating = false;
    }

    try {
      _isGenerating = true;
      debugPrint(
        '[EventOrderPdfService] Starting shareOrderAsPdf for: ${order.orderName}',
      );

      final pdf = await generateEventOrderPdf(
        order: order,
        shopDetails: shopDetails,
      );
      debugPrint('[EventOrderPdfService] PDF generated successfully');

      final bytes = await pdf.save();
      debugPrint(
        '[EventOrderPdfService] PDF bytes saved, size: ${bytes.length}',
      );

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final isEvent = order.orderType == OrderType.event;
      final prefix = isEvent ? 'event' : 'order';
      final fileName =
          '${prefix}_${order.orderName.replaceAll(RegExp(r'[^\w\s]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      debugPrint(
        '[EventOrderPdfService] PDF written to temp file: ${file.path}',
      );

      debugPrint('[EventOrderPdfService] Calling Share.shareXFiles...');
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${isEvent ? "Event" : "Order"}: ${order.orderName} - ${shopDetails.shopName}',
        subject:
            '${isEvent ? "Event Order" : "Sales Order"} from ${shopDetails.shopName}',
      );
      debugPrint('[EventOrderPdfService] Share result: ${result.status}');
    } catch (e, stackTrace) {
      debugPrint('[EventOrderPdfService] ERROR in shareOrderAsPdf: $e');
      debugPrint('[EventOrderPdfService] Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isGenerating = false;
    }
  }

  /// Preview and print PDF using system print dialog
  Future<void> printOrder({
    required EventOrder order,
    required Shop shopDetails,
  }) async {
    if (_isGenerating) {
      debugPrint(
        '[EventOrderPdfService] Already generating PDF, resetting flag and retrying...',
      );
      // Reset flag and allow retry instead of silently returning
      _isGenerating = false;
    }

    try {
      _isGenerating = true;
      final pdf = await generateEventOrderPdf(
        order: order,
        shopDetails: shopDetails,
      );

      final isEvent = order.orderType == OrderType.event;
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: '${isEvent ? "Event" : "Order"}_${order.orderName}',
      );
    } finally {
      _isGenerating = false;
    }
  }

  /// Save PDF to file
  Future<File> saveOrderPdf({
    required EventOrder order,
    required Shop shopDetails,
  }) async {
    debugPrint(
      '[EventOrderPdfService] saveOrderPdf started for: ${order.orderName}',
    );

    try {
      // Yield to allow UI to update
      await Future.delayed(Duration.zero);

      debugPrint('[EventOrderPdfService] Generating PDF document...');
      final pdf = await generateEventOrderPdf(
        order: order,
        shopDetails: shopDetails,
      );
      debugPrint('[EventOrderPdfService] PDF document generated successfully');

      // Yield again before heavy save operation
      await Future.delayed(Duration.zero);

      debugPrint('[EventOrderPdfService] Saving PDF bytes...');
      final bytes = await pdf.save();
      debugPrint(
        '[EventOrderPdfService] PDF bytes saved: ${bytes.length} bytes',
      );

      if (bytes.isEmpty) {
        throw Exception('PDF generation failed: empty bytes');
      }

      // Yield before file operations
      await Future.delayed(Duration.zero);

      debugPrint('[EventOrderPdfService] Getting temporary directory...');
      final dir = await getTemporaryDirectory();
      debugPrint('[EventOrderPdfService] Directory: ${dir.path}');

      final isEvent = order.orderType == OrderType.event;
      final prefix = isEvent ? 'event_invoice' : 'order_invoice';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeOrderName = order.orderName
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final fileName = '${prefix}_${safeOrderName}_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');

      debugPrint('[EventOrderPdfService] Writing file to: ${file.path}');
      await file.writeAsBytes(bytes, flush: true);

      // Verify file was written successfully
      if (!file.existsSync()) {
        throw Exception('Failed to write PDF file to storage');
      }

      final actualSize = file.lengthSync();
      if (actualSize == 0) {
        throw Exception('PDF file was written but is empty');
      }

      debugPrint(
        '[EventOrderPdfService] File written successfully: $actualSize bytes',
      );
      return file;
    } catch (e, stack) {
      debugPrint('[EventOrderPdfService] ERROR in saveOrderPdf: $e');
      debugPrint('[EventOrderPdfService] Stack trace: $stack');
      rethrow;
    }
  }
}
