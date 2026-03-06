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
  static const _accentColor = PdfColor.fromInt(0xFF4A4A4A);
  static const _lightBg = PdfColor.fromInt(0xFFF8F9FA);
  static const _borderColor = PdfColor.fromInt(0xFFE0E0E0);
  static const _successColor = PdfColor.fromInt(0xFF28A745);
  static const _warningColor = PdfColor.fromInt(0xFFFF9800);
  static const _dangerColor = PdfColor.fromInt(0xFFDC3545);

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

      // Column widths
      final columnWidths = <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(0.5), // Sr
        1: const pw.FlexColumnWidth(1.2), // Date
        2: const pw.FlexColumnWidth(2.0), // Name
        3: const pw.FlexColumnWidth(1.5), // Customer
        4: const pw.FlexColumnWidth(1.2), // Contact
        5: const pw.FlexColumnWidth(1.0), // Status
        6: const pw.FlexColumnWidth(1.0), // Total
        7: const pw.FlexColumnWidth(1.0), // Advance
        8: const pw.FlexColumnWidth(1.0), // Due
      };

      // Add page with professional design
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          header: (context) => _buildHeader(
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
            isEventReport: isEventReport,
          ),
          footer: (context) => _buildFooter(
            shopDetails: shopDetails,
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount,
          ),
          build: (context) => [
            // Data Table
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderColor, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  headerDecoration: pw.BoxDecoration(color: _primaryColor),
                  oddRowDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                  ),
                  cellHeight: 20,
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
                    vertical: 3,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            // Bottom Summary Bar
            _buildBottomSummary(
              totalOrders: orders.length,
              totalAmount: totalAmount,
              totalAdvance: totalAdvance,
              totalDue: totalDue,
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

  /// Build professional header with shop branding
  static pw.Widget _buildHeader({
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
    required bool isEventReport,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Shop Header with gradient
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_primaryColor, _accentColor],
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
            ),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            children: [
              // Shop Logo
              if (shopDetails?.shopLogoBase64 != null &&
                  shopDetails!.shopLogoBase64!.isNotEmpty)
                pw.Container(
                  width: 45,
                  height: 45,
                  margin: const pw.EdgeInsets.only(right: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  padding: const pw.EdgeInsets.all(3),
                  child: _buildSafeImage(shopDetails.shopLogoBase64!, 39, 39),
                ),
              // Shop Details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shopDetails?.shopName.toUpperCase() ?? 'BUSINESS NAME',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (shopDetails?.address != null &&
                        shopDetails!.address.isNotEmpty)
                      pw.Text(
                        shopDetails.address,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey300,
                        ),
                      ),
                    if (shopDetails?.phone != null &&
                        shopDetails!.phone.isNotEmpty)
                      pw.Text(
                        'Tel: ${shopDetails.phone}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey300,
                        ),
                      ),
                  ],
                ),
              ),
              // Report Title & Date
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      reportTitle,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _dateTimeFmt.format(generatedAt),
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Filter description if provided
        if (filterDescription != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: _lightBg,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _borderColor, width: 0.5),
            ),
            child: pw.Text(
              'Filter: $filterDescription',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        if (filterDescription != null) pw.SizedBox(height: 6),
        // Status Summary Cards
        pw.Row(
          children: [
            _buildStatCard('TOTAL', '$totalOrders', _primaryColor),
            pw.SizedBox(width: 6),
            _buildStatCard('CONFIRMED', '$confirmedCount', _successColor),
            pw.SizedBox(width: 6),
            _buildStatCard('PENDING', '$pendingCount', _warningColor),
            pw.SizedBox(width: 6),
            _buildStatCard('DELIVERED', '$deliveredCount', PdfColors.blue700),
            pw.SizedBox(width: 6),
            _buildStatCard('CANCELLED', '$cancelledCount', _dangerColor),
            pw.Spacer(),
            _buildAmountCard('Total', totalAmount, _primaryColor),
            pw.SizedBox(width: 6),
            _buildAmountCard('Advance', totalAdvance, _successColor),
            pw.SizedBox(width: 6),
            _buildAmountCard('Due', totalDue, _dangerColor),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Build stat card for status counts
  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(label, style: pw.TextStyle(fontSize: 6, color: color)),
        ],
      ),
    );
  }

  /// Build amount card for financial summary
  static pw.Widget _buildAmountCard(
    String label,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 6, color: color),
          ),
        ],
      ),
    );
  }

  /// Build bottom summary bar
  static pw.Widget _buildBottomSummary({
    required int totalOrders,
    required double totalAmount,
    required double totalAdvance,
    required double totalDue,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_lightBg, PdfColors.grey200],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'SUMMARY: ',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              pw.Text(
                '$totalOrders Records',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'Total: Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: _successColor.shade(0.1),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'Advance: Rs. ${totalAdvance.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _successColor,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: _dangerColor.shade(0.1),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'Due: Rs. ${totalDue.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _dangerColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build professional footer with bank details and signatures (same as bill)
  static pw.Widget _buildFooter({
    Shop? shopDetails,
    required int pageNumber,
    required int totalPages,
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
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        children: [
          // Bank Details | Customer Signature | Owner Signature — Same Row
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // LEFT: Bank Details with QR Code
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _lightBg,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: _borderColor, width: 0.5),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // QR Code
                        if (hasQrCode)
                          pw.Container(
                            margin: const pw.EdgeInsets.only(right: 8),
                            child: pw.Column(
                              children: [
                                pw.Container(
                                  width: 45,
                                  height: 45,
                                  padding: const pw.EdgeInsets.all(2),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: _accentColor,
                                      width: 0.5,
                                    ),
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                  child: _buildSafeImage(
                                    shopDetails.qrCodeBase64!,
                                    41,
                                    41,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Scan to Pay',
                                  style: pw.TextStyle(
                                    fontSize: 6,
                                    color: _accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Bank Details Text
                        if (hasBankDetails)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Bank Details',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _accentColor,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
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
                                    'A/C Name: ${shopDetails.accountHolderName}',
                                    style: const pw.TextStyle(fontSize: 7),
                                  ),
                                if (shopDetails.accountNumber != null &&
                                    shopDetails.accountNumber!.isNotEmpty)
                                  pw.Text(
                                    'A/C No: ${shopDetails.accountNumber}',
                                    style: const pw.TextStyle(fontSize: 7),
                                  ),
                                if (shopDetails.ifscCode != null &&
                                    shopDetails.ifscCode!.isNotEmpty)
                                  pw.Text(
                                    'IFSC: ${shopDetails.ifscCode}',
                                    style: const pw.TextStyle(fontSize: 7),
                                  ),
                              ],
                            ),
                          )
                        else if (!hasQrCode)
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
                pw.SizedBox(width: 10),
                // CENTER: Customer Signature
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _lightBg,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: _borderColor, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 25),
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
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // RIGHT: Owner/Authorized Signature
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _lightBg,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: _borderColor, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'For ${shopDetails?.shopName.toUpperCase() ?? "STORE"}',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        if (hasSignature)
                          pw.Container(
                            width: 70,
                            height: 25,
                            child: _buildSafeImage(
                              shopDetails.signatureBase64!,
                              70,
                              25,
                            ),
                          )
                        else
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
          // Page number and branding
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Page $pageNumber of $totalPages',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Generated by C-Billing',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey500,
                ),
              ),
            ],
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
