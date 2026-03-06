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
/// Generates tabular reports from lists of orders with date filtering.
class EventOrderReportPdfGenerator {
  EventOrderReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

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

      final reportTitle = isEventReport ? 'Event Report' : 'Order Report';

      // Calculate totals
      double totalAmount = 0;
      double totalAdvance = 0;
      double totalDue = 0;
      int confirmedCount = 0;
      int pendingCount = 0;
      int deliveredCount = 0;

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

      // Add page with table
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _dateTimeFmt.format(now),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 4),
              if (filterDescription != null)
                pw.Text(
                  'Filter: $filterDescription',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              // Summary row
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total: ${orders.length}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Confirmed: $confirmedCount',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Pending: $pendingCount',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Delivered: $deliveredCount',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Total Amt: Rs. ${totalAmount.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Advance: Rs. ${totalAdvance.toStringAsFixed(0)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Due: Rs. ${totalDue.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Generated by C-Billing',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 22,
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
