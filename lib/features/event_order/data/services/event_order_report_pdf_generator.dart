import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/event_order.dart';

/// PDF Report generator for Event Orders / Sales Orders.
/// Generates tabular reports from lists of orders with date filtering.
class EventOrderReportPdfGenerator {
  EventOrderReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate PDF bytes from a list of event orders.
  static Future<Uint8List> generate({
    required List<EventOrder> orders,
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

  /// Generate detailed PDF report with Main Events and Sub-Events in tabular format.
  /// Shows event name as main header with sub-events (relational events) in table rows.
  static Future<Uint8List> generateDetailedEventReport({
    required List<EventOrder> orders,
    String? filterDescription,
  }) async {
    debugPrint('[EventOrderReport] DETAILED START: ${orders.length} orders');

    try {
      final now = DateTime.now();
      final pdf = pw.Document();

      // Calculate overall totals
      double grandTotalAmount = 0;
      double grandTotalAdvance = 0;
      double grandTotalDue = 0;
      int totalSubEvents = 0;

      for (final o in orders) {
        grandTotalAmount += o.totalAmount;
        grandTotalAdvance += o.advanceAmount;
        grandTotalDue += o.remainingAmount;
        totalSubEvents += o.subEvents.length;
      }

      // Build content widgets for each event with sub-events
      final contentWidgets = <pw.Widget>[];

      for (int orderIdx = 0; orderIdx < orders.length; orderIdx++) {
        final order = orders[orderIdx];

        // Add spacing between events (except first)
        if (orderIdx > 0) {
          contentWidgets.add(pw.SizedBox(height: 16));
        }

        // ══════════════════════════════════════════════════════════════
        // MAIN EVENT HEADER
        // ══════════════════════════════════════════════════════════════
        contentWidgets.add(
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${orderIdx + 1}. ${order.orderName}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${order.customerName} | ${order.customerContact}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: ${_dateFmt.format(order.eventDate)}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Status: ${order.status.displayName}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.yellow100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        // ══════════════════════════════════════════════════════════════
        // SUB-EVENTS TABLE (Relational Events)
        // ══════════════════════════════════════════════════════════════
        if (order.subEvents.isNotEmpty) {
          contentWidgets.add(pw.SizedBox(height: 4));

          // Build sub-events table data
          final subEventHeaders = <String>[
            'Sr',
            'Sub-Event Name',
            'Date',
            'Charges',
            'Notes',
          ];
          final subEventData = <List<String>>[subEventHeaders];

          double subEventsTotal = 0;
          for (int i = 0; i < order.subEvents.length; i++) {
            final subEvent = order.subEvents[i];
            subEventsTotal += subEvent.charges;
            subEventData.add([
              '${i + 1}',
              subEvent.name,
              _dateFmt.format(subEvent.date),
              'Rs. ${subEvent.charges.toStringAsFixed(0)}',
              subEvent.notes ?? '-',
            ]);
          }

          // Sub-events table
          contentWidgets.add(
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  // Table label
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.vertical(
                        top: pw.Radius.circular(3),
                      ),
                    ),
                    child: pw.Text(
                      'Sub-Events (Relational Events)',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  // Table
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellHeight: 20,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(0.5), // Sr
                      1: const pw.FlexColumnWidth(2.5), // Sub-Event Name
                      2: const pw.FlexColumnWidth(1.5), // Date
                      3: const pw.FlexColumnWidth(1.2), // Charges
                      4: const pw.FlexColumnWidth(2.5), // Notes
                    },
                    data: subEventData,
                    cellAlignments: {
                      0: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerRight,
                    },
                  ),
                  // Sub-events total row
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.vertical(
                        bottom: pw.Radius.circular(3),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Sub-Events Total: Rs. ${subEventsTotal.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // No sub-events
          contentWidgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'No sub-events for this event',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          );
        }

        // ══════════════════════════════════════════════════════════════
        // EVENT FINANCIAL SUMMARY
        // ══════════════════════════════════════════════════════════════
        contentWidgets.add(pw.SizedBox(height: 4));
        contentWidgets.add(
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (order.eventCharges > 0)
                  pw.Text(
                    'Event Charges: Rs. ${order.eventCharges.toStringAsFixed(0)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.Text(
                  'Total: Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Advance: Rs. ${order.advanceAmount.toStringAsFixed(0)}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'Due: Rs. ${order.remainingAmount.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: order.remainingAmount > 0
                        ? PdfColors.red700
                        : PdfColors.green700,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Add page with all content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Event Report - Detailed',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _dateTimeFmt.format(now),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
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
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Events: ${orders.length}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sub-Events: $totalSubEvents',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Total: Rs. ${grandTotalAmount.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Advance: Rs. ${grandTotalAdvance.toStringAsFixed(0)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Due: Rs. ${grandTotalDue.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
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
          build: (context) => contentWidgets,
        ),
      );

      debugPrint('[EventOrderReport] Detailed page added, saving...');

      final bytes = await pdf.save();

      debugPrint('[EventOrderReport] DETAILED DONE: ${bytes.length} bytes');
      return bytes;
    } catch (e, stack) {
      debugPrint('[EventOrderReport] ERROR in generateDetailedEventReport: $e');
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
