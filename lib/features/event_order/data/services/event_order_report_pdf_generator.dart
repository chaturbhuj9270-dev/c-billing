import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/event_order.dart';
import '../../../shop/domain/entities/shop.dart';

/// PDF Report generator for Event Orders / Sales Orders.
/// Generates professional tabular reports with shop branding.
class EventOrderReportPdfGenerator {
  EventOrderReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  // Professional color palette
  static const _primaryColor = PdfColor.fromInt(0xFF1A1A1A);
  static const _lightBg = PdfColor.fromInt(0xFFF8F9FA);
  static const _borderColor = PdfColor.fromInt(0xFFE0E0E0);

  /// Generate PDF bytes from a list of event orders.
  static Future<Uint8List> generate({
    required List<EventOrder> orders,
    Shop? shopDetails,
    String? filterDescription,
    bool isEventReport = true,
  }) async {
    debugPrint('[EventOrderReport] START: ${orders.length} orders');

    try {
      final now = DateTime.now();
      final pdf = pw.Document();

      final reportTitle = isEventReport ? 'EVENT REPORT' : 'ORDER REPORT';

      // Calculate totals
      double totalAmount = 0;
      double totalAdvance = 0;
      double totalDue = 0;
      int confirmedCount = 0;
      int pendingCount = 0;
      int deliveredCount = 0;
      int cancelledCount = 0;

      for (final o in orders) {
        totalAmount += o.totalAmount;
        totalAdvance += o.advanceAmount;
        totalDue += o.remainingAmount;

        switch (o.status) {
          case OrderStatus.confirmed:
            confirmedCount++;
            break;
          case OrderStatus.pending:
            pendingCount++;
            break;
          case OrderStatus.delivered:
            deliveredCount++;
            break;
          case OrderStatus.cancelled:
            cancelledCount++;
            break;
          default:
            break;
        }
      }

      debugPrint('[EventOrderReport] Totals calculated');

      // Build table data
      final headers = <String>[
        'Sr',
        'Date',
        'Name',
        'Customer',
        'Contact',
        'Status',
        'Total',
        'Advance',
        'Due',
      ];

      final data = <List<String>>[headers];

      for (int i = 0; i < orders.length; i++) {
        final o = orders[i];
        data.add([
          '${i + 1}',
          _dateFmt.format(o.eventDate),
          _truncate(o.orderName, 18),
          _truncate(o.customerName, 15),
          o.customerContact.isNotEmpty ? o.customerContact : '-',
          o.status.displayName,
          'Rs. ${o.totalAmount.toStringAsFixed(0)}',
          'Rs. ${o.advanceAmount.toStringAsFixed(0)}',
          'Rs. ${o.remainingAmount.toStringAsFixed(0)}',
        ]);
      }

      debugPrint('[EventOrderReport] Table data built: ${data.length} rows');

      // Column widths - optimized for full width utilization
      final columnWidths = <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(0.4), // Sr
        1: const pw.FlexColumnWidth(1.0), // Date
        2: const pw.FlexColumnWidth(2.2), // Name
        3: const pw.FlexColumnWidth(1.6), // Customer
        4: const pw.FlexColumnWidth(1.2), // Contact
        5: const pw.FlexColumnWidth(0.9), // Status
        6: const pw.FlexColumnWidth(1.0), // Total
        7: const pw.FlexColumnWidth(1.0), // Advance
        8: const pw.FlexColumnWidth(1.0), // Due
      };

      // Add page with professional design
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(12),
          header: (context) => _buildCompactHeader(
            shopDetails: shopDetails,
            reportTitle: reportTitle,
            filterDescription: filterDescription,
            generatedAt: now,
            totalOrders: orders.length,
            confirmedCount: confirmedCount,
            pendingCount: pendingCount,
            deliveredCount: deliveredCount,
            cancelledCount: cancelledCount,
            totalAmount: totalAmount,
            totalAdvance: totalAdvance,
            totalDue: totalDue,
          ),
          footer: (context) => _buildCompactFooter(
            shopDetails: shopDetails,
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
            totalOrders: orders.length,
            totalAmount: totalAmount,
            totalAdvance: totalAdvance,
            totalDue: totalDue,
          ),
          build: (context) => [
            // Data Table - Full Width
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headerDecoration: pw.BoxDecoration(color: _primaryColor),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              cellHeight: 18,
              columnWidths: columnWidths,
              data: data,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
                8: pw.Alignment.centerRight,
              },
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
            ),
          ],
        ),
      );

      debugPrint('[EventOrderReport] Page added, saving...');

      final bytes = await pdf.save();

      debugPrint('[EventOrderReport] DONE: ${bytes.length} bytes');
      return bytes;
    } catch (e, stack) {
      debugPrint('[EventOrderReport] ERROR in generate: $e');
      debugPrint('[EventOrderReport] Stack: $stack');
      rethrow;
    }
  }

  /// Truncate string with ellipsis
  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Build compact header - single row design
  static pw.Widget _buildCompactHeader({
    Shop? shopDetails,
    required String reportTitle,
    String? filterDescription,
    required DateTime generatedAt,
    required int totalOrders,
    required int confirmedCount,
    required int pendingCount,
    required int deliveredCount,
    required int cancelledCount,
    required double totalAmount,
    required double totalAdvance,
    required double totalDue,
  }) {
    return pw.Column(
      children: [
        // Main Header Row - Shop | Title | Stats
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: _primaryColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // LEFT: Shop Logo & Name
              if (shopDetails?.shopLogoBase64 != null &&
                  shopDetails!.shopLogoBase64!.isNotEmpty)
                pw.Container(
                  width: 35,
                  height: 35,
                  margin: const pw.EdgeInsets.only(right: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  padding: const pw.EdgeInsets.all(2),
                  child: _buildSafeImage(shopDetails.shopLogoBase64!, 31, 31),
                ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      shopDetails?.shopName.toUpperCase() ?? 'BUSINESS',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    if (shopDetails?.phone != null &&
                        shopDetails!.phone.isNotEmpty)
                      pw.Text(
                        shopDetails.phone,
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey300,
                        ),
                      ),
                  ],
                ),
              ),
              // CENTER: Report Title & Date
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        reportTitle,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _dateTimeFmt.format(generatedAt),
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey300,
                      ),
                    ),
                  ],
                ),
              ),
              // RIGHT: Quick Stats
              pw.Expanded(
                flex: 3,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    _buildMiniStat('Total', '$totalOrders', PdfColors.white),
                    pw.SizedBox(width: 4),
                    _buildMiniStat(
                      'CNF',
                      '$confirmedCount',
                      PdfColors.green200,
                    ),
                    pw.SizedBox(width: 4),
                    _buildMiniStat('PND', '$pendingCount', PdfColors.orange200),
                    pw.SizedBox(width: 4),
                    _buildMiniStat('DLV', '$deliveredCount', PdfColors.blue200),
                    pw.SizedBox(width: 4),
                    _buildMiniStat('CNL', '$cancelledCount', PdfColors.red200),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Filter row (if applicable)
        if (filterDescription != null) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: _lightBg,
              border: pw.Border.all(color: _borderColor, width: 0.5),
            ),
            child: pw.Text(
              'Filter: $filterDescription',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ),
        ],
        pw.SizedBox(height: 6),
      ],
    );
  }

  /// Mini stat badge for header
  static pw.Widget _buildMiniStat(
    String label,
    String value,
    PdfColor bgColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor.shade(0.3),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7, color: _primaryColor),
          ),
          pw.SizedBox(width: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact footer - bank details | signatures | summary in one row
  static pw.Widget _buildCompactFooter({
    Shop? shopDetails,
    required int pageNumber,
    required int totalPages,
    required int totalOrders,
    required double totalAmount,
    required double totalAdvance,
    required double totalDue,
  }) {
    final hasBankDetails =
        shopDetails != null &&
        ((shopDetails.bankName != null && shopDetails.bankName!.isNotEmpty) ||
            (shopDetails.accountNumber != null &&
                shopDetails.accountNumber!.isNotEmpty));

    final hasQrCode =
        shopDetails?.qrCodeBase64 != null &&
        shopDetails!.qrCodeBase64!.isNotEmpty;

    final hasSignature =
        shopDetails?.signatureBase64 != null &&
        shopDetails!.signatureBase64!.isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // LEFT: Bank Details (compact)
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: _lightBg,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (hasQrCode)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(right: 6),
                      width: 40,
                      height: 40,
                      child: _buildSafeImage(shopDetails.qrCodeBase64!, 40, 40),
                    ),
                  if (hasBankDetails)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            'Bank Details',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (shopDetails.bankName != null)
                            pw.Text(
                              shopDetails.bankName!,
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          if (shopDetails.accountNumber != null)
                            pw.Text(
                              'A/C: ${shopDetails.accountNumber}',
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                          if (shopDetails.ifscCode != null)
                            pw.Text(
                              'IFSC: ${shopDetails.ifscCode}',
                              style: const pw.TextStyle(fontSize: 6),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          // CENTER: Customer Signature
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 90,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Customer Signature',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          // CENTER-RIGHT: Owner Signature
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (hasSignature)
                  _buildSafeImage(shopDetails.signatureBase64!, 60, 20)
                else
                  pw.SizedBox(height: 20),
                pw.Container(
                  width: 90,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Authorized Signatory',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          // RIGHT: Summary & Page
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: _primaryColor,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total: Rs.${totalAmount.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Advance: Rs.${totalAdvance.toStringAsFixed(0)}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.green200,
                        ),
                      ),
                      pw.Text(
                        'Due: Rs.${totalDue.toStringAsFixed(0)}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.red200,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Page $pageNumber of $totalPages',
                        style: const pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey400,
                        ),
                      ),
                      pw.Text(
                        'C-Billing',
                        style: const pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey400,
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
    );
  }

  /// Safe image builder to handle corrupted base64
  static pw.Widget _buildSafeImage(
    String base64String,
    double width,
    double height,
  ) {
    try {
      final bytes = base64Decode(base64String);
      return pw.Image(
        pw.MemoryImage(bytes),
        fit: pw.BoxFit.contain,
        width: width,
        height: height,
      );
    } catch (e) {
      debugPrint('[EventOrderReport] Failed to decode image: $e');
      return pw.Container(
        width: width,
        height: height,
        color: PdfColors.grey200,
      );
    }
  }

  /// Print the PDF.
  static Future<void> printReport(
    Uint8List pdfBytes, {
    bool isEvent = true,
  }) async {
    debugPrint('[EventOrderReport] Printing ${pdfBytes.length} bytes');
    final name = isEvent ? 'event_report' : 'order_report';
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: '${name}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Share the PDF via system share sheet.
  static Future<void> shareReport(
    Uint8List pdfBytes, {
    bool isEvent = true,
  }) async {
    debugPrint('[EventOrderReport] Sharing ${pdfBytes.length} bytes');
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = isEvent ? 'event_report' : 'order_report';
    final tempFile = File('${tempDir.path}/${name}_$timestamp.pdf');
    await tempFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: 'application/pdf')],
      text: '${isEvent ? "Event" : "Order"} Report — C-Billing',
      subject: '${isEvent ? "Event" : "Order"} Report',
    );
  }

  /// Save PDF to file and return the file.
  static Future<File> saveToFile(
    Uint8List pdfBytes, {
    bool isEvent = true,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = isEvent ? 'event_report' : 'order_report';
    final file = File('${tempDir.path}/${name}_$timestamp.pdf');
    await file.writeAsBytes(pdfBytes);
    debugPrint('[EventOrderReport] Saved to: ${file.path}');
    return file;
  }
}
