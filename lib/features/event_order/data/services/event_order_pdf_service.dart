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
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (context) =>
            _buildOrderContent(order, shopDetails, dateFormatter),
      ),
    );

    return pdf;
  }

  /// Build the main content of the PDF - Compact Professional UI
  pw.Widget _buildOrderContent(
    EventOrder order,
    Shop shopDetails,
    DateFormat dateFormatter,
  ) {
    final isEvent = order.orderType == OrderType.event;
    final primaryColor = PdfColor.fromHex('#1A1A1A');
    final accentColor = PdfColor.fromHex('#4A4A4A');
    final lightBg = PdfColor.fromHex('#F8F9FA');
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
        border: pw.Border.all(color: primaryColor, width: 1.2),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // ROW 1: COMPACT HEADER (Logo | Shop Info | Invoice Type | GSTIN)
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: pw.BoxDecoration(color: primaryColor),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo
                if (shopDetails.shopLogoBase64 != null &&
                    shopDetails.shopLogoBase64!.isNotEmpty)
                  _buildSafeImage(
                    base64String: shopDetails.shopLogoBase64!,
                    width: 36,
                    height: 36,
                    margin: const pw.EdgeInsets.only(right: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    padding: const pw.EdgeInsets.all(2),
                  ),
                // Shop Info
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        shopDetails.shopName.isNotEmpty
                            ? shopDetails.shopName.toUpperCase()
                            : 'BUSINESS',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (shopDetails.address.isNotEmpty)
                        pw.Text(
                          shopDetails.address,
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey300,
                          ),
                          maxLines: 1,
                        ),
                      pw.Row(
                        children: [
                          if (shopDetails.phone.isNotEmpty)
                            pw.Text(
                              shopDetails.phone,
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey300,
                              ),
                            ),
                          if (shopDetails.phone.isNotEmpty &&
                              shopDetails.email != null &&
                              shopDetails.email!.isNotEmpty)
                            pw.Text(
                              ' | ',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey500,
                              ),
                            ),
                          if (shopDetails.email != null &&
                              shopDetails.email!.isNotEmpty)
                            pw.Text(
                              shopDetails.email!,
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey300,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Invoice Type Badge
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    isEvent ? 'EVENT INVOICE' : 'ORDER INVOICE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // GSTIN
                if (shopDetails.gstNumber != null &&
                    shopDetails.gstNumber!.isNotEmpty)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(left: 8),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey500,
                        width: 0.5,
                      ),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'GSTIN',
                          style: const pw.TextStyle(
                            fontSize: 5,
                            color: PdfColors.grey400,
                          ),
                        ),
                        pw.Text(
                          shopDetails.gstNumber!,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // ROW 2: ORDER INFO BAR (Event/Order | Date | Status | Created)
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: lightBg,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    children: [
                      pw.Text(
                        '${isEvent ? "Event" : "Order"}: ',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          order.orderName,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 12,
                  color: PdfColors.grey400,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    dateFormatter.format(order.eventDate),
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 12,
                  color: PdfColors.grey400,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    order.status.displayName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 12,
                  color: PdfColors.grey400,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                ),
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

          // ═══════════════════════════════════════════════════════════════
          // ROW 3: CUSTOMER & OWNER INFO (2-Column Compact)
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            child: pw.Row(
              children: [
                // BILL TO
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: thinBorder),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Text(
                            'BILL TO',
                            style: pw.TextStyle(
                              fontSize: 6,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                order.customerName.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Row(
                                children: [
                                  if (order.customerContact.isNotEmpty)
                                    pw.Text(
                                      order.customerContact,
                                      style: const pw.TextStyle(fontSize: 8),
                                    ),
                                  if (order.customerContact.isNotEmpty &&
                                      order.customerAddress != null &&
                                      order.customerAddress!.isNotEmpty)
                                    pw.Text(
                                      ' | ',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey500,
                                      ),
                                    ),
                                  if (order.customerAddress != null &&
                                      order.customerAddress!.isNotEmpty)
                                    pw.Expanded(
                                      child: pw.Text(
                                        order.customerAddress!,
                                        style: const pw.TextStyle(fontSize: 7),
                                        maxLines: 1,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // PROPRIETOR / LOCATION
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (order.eventLocation != null &&
                            order.eventLocation!.isNotEmpty)
                          pw.Expanded(
                            child: pw.Text(
                              'Loc: ${order.eventLocation}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                              ),
                              maxLines: 1,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        if (shopDetails.ownerName != null &&
                            shopDetails.ownerName!.isNotEmpty)
                          pw.Container(
                            margin: const pw.EdgeInsets.only(left: 8),
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: pw.BoxDecoration(
                              color: lightBg,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.Text(
                              'Prop: ${shopDetails.ownerName}',
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
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
          // SECTION 4: EVENT DETAILS TABLE (Compact)
          // ═══════════════════════════════════════════════════════════════
          if (isEvent && order.subEvents.isNotEmpty)
            _buildEventDetailsTableCompact(
              order,
              dateFormatter,
              borderSide,
              thinBorder,
            ),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 5: PRODUCTS TABLE (Compact)
          // ═══════════════════════════════════════════════════════════════
          if (order.items.isNotEmpty)
            _buildProductsTableCompact(order.items, borderSide, thinBorder),

          // ═══════════════════════════════════════════════════════════════
          // SECTION 6: SUMMARY ROW (Amount Words | Description | Totals)
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // LEFT: Amount in Words + Notes + Terms
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: thinBorder),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Amount: ',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                _numberToWords(order.totalAmount),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (order.description != null &&
                            order.description!.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Desc: ${order.description}',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                            maxLines: 2,
                          ),
                        ],
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Notes: ${order.notes}',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                            maxLines: 2,
                          ),
                        ],
                        if (shopDetails.termsAndConditions != null &&
                            shopDetails.termsAndConditions!.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'T&C: ${shopDetails.termsAndConditions}',
                            style: const pw.TextStyle(
                              fontSize: 6,
                              color: PdfColors.grey600,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // RIGHT: Financial Summary (Compact)
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left column: breakdowns
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (isEvent && mainEventCharges > 0)
                                _buildCompactSummaryLine(
                                  'Main Event',
                                  mainEventCharges,
                                ),
                              if (isEvent && order.subEvents.isNotEmpty)
                                _buildCompactSummaryLine(
                                  'Sub-Events',
                                  subEventsTotal,
                                ),
                              if (order.items.isNotEmpty)
                                _buildCompactSummaryLine(
                                  'Products',
                                  productsTotal,
                                ),
                              _buildCompactSummaryLine(
                                'Advance',
                                order.advanceAmount,
                                color: PdfColors.green700,
                              ),
                            ],
                          ),
                        ),
                        // Right column: totals
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    'GRAND TOTAL',
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Text(
                                    'Rs. ${grandTotal.toStringAsFixed(0)}',
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: balanceDue > 0
                                    ? PdfColors.orange100
                                    : PdfColors.green100,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    'BALANCE DUE',
                                    style: pw.TextStyle(
                                      fontSize: 6,
                                      fontWeight: pw.FontWeight.bold,
                                      color: balanceDue > 0
                                          ? PdfColors.orange800
                                          : PdfColors.green800,
                                    ),
                                  ),
                                  pw.Text(
                                    'Rs. ${balanceDue.toStringAsFixed(0)}',
                                    style: pw.TextStyle(
                                      fontSize: 10,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // FOOTER: Bank Details | Customer Signature | Owner Signature
          // ═══════════════════════════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Bank Details + QR
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (shopDetails.qrCodeBase64 != null &&
                            shopDetails.qrCodeBase64!.isNotEmpty)
                          pw.Container(
                            margin: const pw.EdgeInsets.only(right: 6),
                            child: pw.Column(
                              children: [
                                pw.Container(
                                  width: 40,
                                  height: 40,
                                  padding: const pw.EdgeInsets.all(2),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: accentColor,
                                      width: 0.5,
                                    ),
                                    borderRadius: pw.BorderRadius.circular(2),
                                  ),
                                  child: _buildSafeImage(
                                    base64String: shopDetails.qrCodeBase64!,
                                    width: 36,
                                    height: 36,
                                  ),
                                ),
                                pw.Text(
                                  'Scan to Pay',
                                  style: const pw.TextStyle(
                                    fontSize: 5,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((shopDetails.bankName != null &&
                                shopDetails.bankName!.isNotEmpty) ||
                            (shopDetails.accountNumber != null &&
                                shopDetails.accountNumber!.isNotEmpty))
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Bank Details',
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                if (shopDetails.bankName != null &&
                                    shopDetails.bankName!.isNotEmpty)
                                  pw.Text(
                                    shopDetails.bankName!,
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                if (shopDetails.accountHolderName != null &&
                                    shopDetails.accountHolderName!.isNotEmpty)
                                  pw.Text(
                                    'Name: ${shopDetails.accountHolderName}',
                                    style: const pw.TextStyle(fontSize: 6),
                                  ),
                                if (shopDetails.accountNumber != null &&
                                    shopDetails.accountNumber!.isNotEmpty)
                                  pw.Text(
                                    'A/C: ${shopDetails.accountNumber}',
                                    style: const pw.TextStyle(fontSize: 6),
                                  ),
                                if (shopDetails.ifscCode != null &&
                                    shopDetails.ifscCode!.isNotEmpty)
                                  pw.Text(
                                    'IFSC: ${shopDetails.ifscCode}',
                                    style: const pw.TextStyle(fontSize: 6),
                                  ),
                              ],
                            ),
                          )
                        else if (shopDetails.qrCodeBase64 == null ||
                            shopDetails.qrCodeBase64!.isEmpty)
                          pw.Expanded(
                            child: pw.Center(
                              child: pw.Text(
                                'Bank Details Not Available',
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                // Customer Signature
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 20),
                        pw.Container(
                          width: 80,
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
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                // Owner Signature
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (shopDetails.signatureBase64 != null &&
                            shopDetails.signatureBase64!.isNotEmpty)
                          _buildSafeImage(
                            base64String: shopDetails.signatureBase64!,
                            width: 60,
                            height: 22,
                            margin: const pw.EdgeInsets.only(bottom: 4),
                          )
                        else
                          pw.SizedBox(height: 18),
                        pw.Container(
                          width: 80,
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
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
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

  /// Get status color
  PdfColor _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return PdfColors.green700;
      case OrderStatus.pending:
        return PdfColors.orange700;
      case OrderStatus.delivered:
        return PdfColors.blue700;
      case OrderStatus.cancelled:
        return PdfColors.red700;
      default:
        return PdfColors.grey700;
    }
  }

  /// Compact summary line helper
  pw.Widget _buildCompactSummaryLine(
    String label,
    double amount, {
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7, color: color ?? PdfColors.grey700),
          ),
          pw.Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Compact Event Details Table
  pw.Widget _buildEventDetailsTableCompact(
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
          // Compact Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'EVENT DETAILS - ${order.orderName}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    '${order.subEvents.length} Sub-Event(s)',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
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
              0: const pw.FlexColumnWidth(0.4),
              1: const pw.FlexColumnWidth(3.5),
              2: const pw.FlexColumnWidth(2.0),
              3: const pw.FlexColumnWidth(1.3),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCellCompact('Sr', isHeader: true),
                  _buildTableCellCompact(
                    'Event / Sub-Event',
                    isHeader: true,
                    align: pw.TextAlign.left,
                  ),
                  _buildTableCellCompact('Date', isHeader: true),
                  _buildTableCellCompact(
                    'Charges',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              // Main Event
              if (mainEventCharges > 0)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.amber50),
                  children: [
                    _buildTableCellCompact('1', isHeader: true),
                    _buildTableCellCompact(
                      '${order.orderName} (Main)',
                      isHeader: true,
                      align: pw.TextAlign.left,
                    ),
                    _buildTableCellCompact(
                      dateFormatter.format(order.eventDate),
                    ),
                    _buildTableCellCompact(
                      'Rs. ${mainEventCharges.toStringAsFixed(0)}',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              // Sub-Events
              ...order.subEvents.asMap().entries.map((entry) {
                final idx = entry.key;
                final subEvent = entry.value;
                final srNo = mainEventCharges > 0 ? idx + 2 : idx + 1;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: idx % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                  ),
                  children: [
                    _buildTableCellCompact('$srNo'),
                    _buildTableCellCompact(
                      subEvent.name,
                      align: pw.TextAlign.left,
                    ),
                    _buildTableCellCompact(dateFormatter.format(subEvent.date)),
                    _buildTableCellCompact(
                      'Rs. ${subEvent.charges.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
              // Total
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _buildTableCellCompact(''),
                  _buildTableCellCompact(
                    'EVENTS TOTAL',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCellCompact(''),
                  _buildTableCellCompact(
                    'Rs. ${allEventsTotal.toStringAsFixed(0)}',
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

  /// Build Compact Products Table
  pw.Widget _buildProductsTableCompact(
    List<OrderItem> items,
    pw.BorderSide borderSide,
    pw.BorderSide thinBorder,
  ) {
    final productsTotal = items.fold(0.0, (sum, item) => sum + item.total);

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Compact Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PRODUCTS',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    '${items.length} Item(s)',
                    style: pw.TextStyle(
                      fontSize: 7,
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
              0: const pw.FlexColumnWidth(0.4),
              1: const pw.FlexColumnWidth(3.0),
              2: const pw.FlexColumnWidth(0.7),
              3: const pw.FlexColumnWidth(1.0),
              4: const pw.FlexColumnWidth(0.6),
              5: const pw.FlexColumnWidth(1.3),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCellCompact('Sr', isHeader: true),
                  _buildTableCellCompact(
                    'Product',
                    isHeader: true,
                    align: pw.TextAlign.left,
                  ),
                  _buildTableCellCompact('Qty', isHeader: true),
                  _buildTableCellCompact(
                    'Rate',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCellCompact('Disc', isHeader: true),
                  _buildTableCellCompact(
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
                    _buildTableCellCompact('${idx + 1}'),
                    _buildTableCellCompact(
                      item.productName,
                      align: pw.TextAlign.left,
                    ),
                    _buildTableCellCompact('${item.quantity}'),
                    _buildTableCellCompact(
                      'Rs. ${item.rate.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCellCompact(
                      item.discountPercent > 0
                          ? '${item.discountPercent.toStringAsFixed(0)}%'
                          : '-',
                    ),
                    _buildTableCellCompact(
                      'Rs. ${item.total.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
              // Total
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green100),
                children: [
                  _buildTableCellCompact(''),
                  _buildTableCellCompact(
                    'PRODUCTS TOTAL',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCellCompact(''),
                  _buildTableCellCompact(''),
                  _buildTableCellCompact(''),
                  _buildTableCellCompact(
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

  /// Compact table cell
  pw.Widget _buildTableCellCompact(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
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
