import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event_order.dart';
import '../../domain/entities/sub_event.dart';
import '../../domain/entities/order_item.dart';
import '../../../shop/domain/entities/shop.dart';

/// Service for generating PDF for Event Orders / Sales Orders
class EventOrderPdfService {
  static final EventOrderPdfService _instance = EventOrderPdfService._internal();
  factory EventOrderPdfService() => _instance;
  EventOrderPdfService._internal();

  static bool _isGenerating = false;

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
        build: (context) => _buildOrderContent(
          order,
          shopDetails,
          dateFormatter,
        ),
      ),
    );

    return pdf;
  }

  /// Build the main content of the PDF
  pw.Widget _buildOrderContent(
    EventOrder order,
    Shop shopDetails,
    DateFormat dateFormatter,
  ) {
    final isEvent = order.orderType == OrderType.event;
    final borderSide = pw.BorderSide(color: PdfColors.grey800, width: 0.8);
    final thinBorder = pw.BorderSide(color: PdfColors.grey600, width: 0.5);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey800, width: 1.0),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════
          // SHOP HEADER
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
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Wrap(
                    alignment: pw.WrapAlignment.end,
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
                ),
                if (shopDetails.gstNumber != null && shopDetails.gstNumber!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GST No: ${shopDetails.gstNumber}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
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
                        _buildCompactInfoRow('Customer Name', order.customerName.toUpperCase(), bold: true),
                        if (order.customerContact.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _buildCompactInfoRow('Contact', order.customerContact),
                        ],
                        if (order.customerAddress != null && order.customerAddress!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _buildCompactInfoRow('Address', order.customerAddress!),
                        ],
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
                          isEvent ? 'Event Date' : 'Delivery Date',
                          dateFormatter.format(order.eventDate),
                        ),
                        pw.SizedBox(height: 3),
                        _buildCompactInfoRow(
                          isEvent ? 'Event Name' : 'Order Name',
                          order.orderName,
                          bold: true,
                        ),
                        pw.SizedBox(height: 3),
                        _buildCompactInfoRow(
                          'Status',
                          order.status.displayName.toUpperCase(),
                        ),
                        if (order.eventLocation != null && order.eventLocation!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _buildCompactInfoRow('Location', order.eventLocation!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // ITEMS TABLES (Sub-events and/or Products)
          // ═══════════════════════════════════════════
          if (isEvent) ...[
            if (order.subEvents.isNotEmpty)
              _buildSubEventsTable(order.subEvents, dateFormatter, borderSide, thinBorder),
            if (order.items.isNotEmpty)
              _buildProductsTable(order.items, borderSide, thinBorder, 
                title: order.subEvents.isNotEmpty ? 'Event Products' : 'Products'),
          ] else if (order.items.isNotEmpty)
            _buildProductsTable(order.items, borderSide, thinBorder),

          // ═══════════════════════════════════════════
          // BOTTOM SECTION — Notes (left) + Totals (right)
          // ═══════════════════════════════════════════
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Notes + Terms
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
                      if (order.description != null && order.description!.isNotEmpty) ...[
                        pw.Text(
                          'Description:',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          order.description!,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        pw.Text(
                          'Notes:',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          order.notes!,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                      pw.Text(
                        'Terms & Conditions:',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. Advance payment is non-refundable.',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                      pw.Text(
                        '2. Balance to be paid before delivery/event.',
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
                    // Sub-events total (if any)
                    if (isEvent && order.subEvents.isNotEmpty)
                      _buildCompactAmountRow(
                        'SUB-EVENTS TOTAL',
                        order.subEvents.fold(0.0, (sum, e) => sum + e.charges),
                        border: thinBorder,
                      ),
                    // Products total (if any)
                    if (order.items.isNotEmpty)
                      _buildCompactAmountRow(
                        'PRODUCTS TOTAL',
                        order.items.fold(0.0, (sum, item) => sum + item.total),
                        border: thinBorder,
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
                            'Rs. ${order.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Advance Paid
                    _buildCompactAmountRow(
                      'ADVANCE PAID',
                      order.advanceAmount,
                      border: thinBorder,
                      color: PdfColors.green800,
                    ),
                    // Balance Amount
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: order.remainingAmount > 0 ? PdfColors.orange50 : PdfColors.green50,
                        border: pw.Border(bottom: thinBorder),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'BALANCE AMT',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: order.remainingAmount > 0 ? PdfColors.orange900 : PdfColors.green900,
                            ),
                          ),
                          pw.Text(
                            'Rs. ${order.remainingAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: order.remainingAmount > 0 ? PdfColors.orange900 : PdfColors.green900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ═══════════════════════════════════════════
          // FOOTER — Signature
          // ═══════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: borderSide),
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
                // Generated date
                pw.Text(
                  'Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
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

  /// Compact amount row for totals section
  pw.Widget _buildCompactAmountRow(
    String label,
    double amount, {
    required pw.BorderSide border,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: border),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            'Rs. ${amount.toStringAsFixed(2)}',
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

  /// Build sub-events table for Event type orders
  pw.Widget _buildSubEventsTable(
    List<SubEvent> subEvents,
    DateFormat dateFormatter,
    pw.BorderSide borderSide,
    pw.BorderSide thinBorder,
  ) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Text(
              'SUB-EVENTS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: thinBorder,
              bottom: borderSide,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Event Name', isHeader: true),
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Charges', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Data rows
              ...subEvents.asMap().entries.map((entry) {
                final idx = entry.key;
                final subEvent = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell('${idx + 1}'),
                    _buildTableCell(subEvent.name),
                    _buildTableCell(dateFormatter.format(subEvent.date)),
                    _buildTableCell('Rs. ${subEvent.charges.toStringAsFixed(0)}', 
                      align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Build products table for Sales Order type or Event products
  pw.Widget _buildProductsTable(
    List<OrderItem> items,
    pw.BorderSide borderSide,
    pw.BorderSide thinBorder, {
    String title = 'PRODUCTS',
  }) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border(bottom: thinBorder),
            ),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: thinBorder,
              bottom: borderSide,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(0.8),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(0.8),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Product', isHeader: true),
                  _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell('Rate', isHeader: true, align: pw.TextAlign.right),
                  _buildTableCell('Disc%', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Data rows
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell('${idx + 1}'),
                    _buildTableCell(item.productName),
                    _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
                    _buildTableCell('Rs. ${item.rate.toStringAsFixed(0)}', 
                      align: pw.TextAlign.right),
                    _buildTableCell(item.discountPercent > 0 
                      ? '${item.discountPercent.toStringAsFixed(0)}%' 
                      : '-', 
                      align: pw.TextAlign.center),
                    _buildTableCell('Rs. ${item.total.toStringAsFixed(0)}', 
                      align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
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
      debugPrint('[EventOrderPdfService] Already generating PDF, skipping...');
      return;
    }

    try {
      _isGenerating = true;
      debugPrint('[EventOrderPdfService] Starting shareOrderAsPdf for: ${order.orderName}');

      final pdf = await generateEventOrderPdf(
        order: order,
        shopDetails: shopDetails,
      );
      debugPrint('[EventOrderPdfService] PDF generated successfully');

      final bytes = await pdf.save();
      debugPrint('[EventOrderPdfService] PDF bytes saved, size: ${bytes.length}');

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final isEvent = order.orderType == OrderType.event;
      final prefix = isEvent ? 'event' : 'order';
      final fileName = '${prefix}_${order.orderName.replaceAll(RegExp(r'[^\w\s]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      debugPrint('[EventOrderPdfService] PDF written to temp file: ${file.path}');

      debugPrint('[EventOrderPdfService] Calling Share.shareXFiles...');
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: '${isEvent ? "Event" : "Order"}: ${order.orderName} - ${shopDetails.shopName}',
        subject: '${isEvent ? "Event Order" : "Sales Order"} from ${shopDetails.shopName}',
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
      debugPrint('[EventOrderPdfService] Already generating PDF, skipping...');
      return;
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
    debugPrint('[EventOrderPdfService] saveOrderPdf started for: ${order.orderName}');
    
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
      debugPrint('[EventOrderPdfService] PDF bytes saved: ${bytes.length} bytes');
      
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
      final safeOrderName = order.orderName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
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
      
      debugPrint('[EventOrderPdfService] File written successfully: $actualSize bytes');
      return file;
    } catch (e, stack) {
      debugPrint('[EventOrderPdfService] ERROR in saveOrderPdf: $e');
      debugPrint('[EventOrderPdfService] Stack trace: $stack');
      rethrow;
    }
  }
}
