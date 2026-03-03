import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/bill_report_settings_service.dart';
import '../../domain/entities/bill.dart';

/// Fast PDF generator for Bill Reports.
/// Generates reports with columns based on user's Bill Report Settings.
class BillReportPdfGenerator {
  BillReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate PDF bytes directly from bill entities.
  /// Uses BillReportSettingsService to determine visible columns.
  static Future<Uint8List> generate({
    required List<Bill> bills,
    String? filterDescription,
  }) async {
    debugPrint('[BillReport] START: ${bills.length} bills');

    try {
      final now = DateTime.now();
      final pdf = pw.Document();

      debugPrint('[BillReport] Document created');

      // Initialize report settings - use defaults if init fails
      try {
        await BillReportSettingsService.instance.init().timeout(
          const Duration(seconds: 5),
        );
        debugPrint('[BillReport] Settings initialized');
      } catch (e) {
        debugPrint('[BillReport] Settings init failed, using defaults: $e');
        // visibleColumns getter already returns defaults if not initialized
      }
      final visibleColumns = BillReportSettingsService.instance.visibleColumns;
      debugPrint('[BillReport] Got ${visibleColumns.length} visible columns');

      debugPrint(
        '[BillReport] Visible columns: ${visibleColumns.map((c) => c.id).toList()}',
      );

      // Calculate totals
      int totalItems = 0;
      int totalQuantity = 0;
      double totalAmount = 0;
      double totalDiscount = 0;
      double totalTax = 0;
      double totalFinal = 0;

      for (final bill in bills) {
        totalItems += bill.items.length;
        totalQuantity += bill.totalQuantity;
        totalAmount += bill.totalAmount;
        totalDiscount += bill.discountAmount;
        totalTax += bill.totalTaxAmount;
        totalFinal += bill.finalAmount;
      }

      debugPrint('[BillReport] Totals calculated');

      // Build dynamic header based on visible columns
      // For bill report, we show bill-level info first, then expand items
      final headers = <String>['Sr', 'Bill No', 'Date', 'Customer'];

      // Add item-level columns
      for (final col in visibleColumns) {
        if (col.id != 'sr_no') {
          // Skip sr_no for items
          headers.add(_getColumnHeader(col.id, col.name));
        }
      }
      headers.add('Bill Total');

      // Build table data - one row per bill item
      final data = <List<String>>[headers];
      int srNo = 0;

      for (final bill in bills) {
        // Handle bills with no items - add a single row with bill info only
        if (bill.items.isEmpty) {
          srNo++;
          final row = <String>[];
          row.add('$srNo');
          row.add(_truncate(bill.billNumber, 15));
          row.add(_dateFmt.format(bill.billDate));
          row.add(_truncate(bill.customerName ?? '-', 12));

          // Add empty values for item columns
          for (final col in visibleColumns) {
            if (col.id != 'sr_no') {
              row.add('-');
            }
          }
          row.add('Rs.${bill.finalAmount.toStringAsFixed(2)}');
          data.add(row);
          continue;
        }

        for (int itemIdx = 0; itemIdx < bill.items.length; itemIdx++) {
          srNo++;
          final item = bill.items[itemIdx];
          final row = <String>[];

          // Bill-level info (only show on first item of each bill)
          if (itemIdx == 0) {
            row.add('$srNo');
            row.add(_truncate(bill.billNumber, 15));
            row.add(_dateFmt.format(bill.billDate));
            row.add(_truncate(bill.customerName ?? '-', 12));
          } else {
            row.add('$srNo');
            row.add(''); // Empty bill number for subsequent items
            row.add(''); // Empty date
            row.add(''); // Empty customer
          }

          // Item-level columns based on visibility
          for (final col in visibleColumns) {
            if (col.id != 'sr_no') {
              row.add(_getCellValue(col.id, bill, item));
            }
          }

          // Bill total (only show on first item)
          if (itemIdx == 0) {
            row.add('Rs.${bill.finalAmount.toStringAsFixed(2)}');
          } else {
            row.add('');
          }

          data.add(row);
        }
      }

      debugPrint(
        '[BillReport] Table data built: ${data.length} rows, ${headers.length} columns',
      );

      // Calculate column widths
      final columnWidths = _calculateColumnWidths(
        headers.length,
        visibleColumns,
      );

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
                    'Bill Report',
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
                  pw.Row(
                    children: [
                      pw.Text(
                        'Bills: ${bills.length}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'Items: $totalItems',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'Qty: $totalQuantity',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'Amount: Rs ${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (totalDiscount > 0) ...[
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Disc: -Rs ${totalDiscount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                      if (totalTax > 0) ...[
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Tax: Rs ${totalTax.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'Total: Rs ${totalFinal.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
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
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 20,
              columnWidths: columnWidths,
              data: data,
            ),
          ],
        ),
      );

      debugPrint('[BillReport] Page added, saving...');

      final bytes = await pdf.save();

      debugPrint('[BillReport] DONE: ${bytes.length} bytes');
      return bytes;
    } catch (e, stack) {
      debugPrint('[BillReport] ERROR in generate: $e');
      debugPrint('[BillReport] Stack: $stack');
      rethrow;
    }
  }

  /// Truncate string to max length
  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get column header text
  static String _getColumnHeader(String columnId, String defaultName) {
    switch (columnId) {
      case 'sr_no':
        return 'Sr';
      case 'product_name':
        return 'Product';
      case 'hsn_code':
        return 'HSN';
      case 'company':
        return 'Company';
      case 'quantity':
        return 'Qty';
      case 'unit':
        return 'Unit';
      case 'rate':
        return 'Rate';
      case 'discount':
        return 'Disc%';
      case 'tax':
        return 'Tax';
      case 'amount':
        return 'Amount';
      default:
        return defaultName;
    }
  }

  /// Get cell value for a column
  static String _getCellValue(String columnId, Bill bill, dynamic item) {
    switch (columnId) {
      case 'product_name':
        return _truncate(item.productName ?? '-', 20);
      case 'hsn_code':
        return item.hsnCode ?? '-';
      case 'company':
        return _truncate(item.companyName ?? '-', 12);
      case 'quantity':
        return '${item.quantity}';
      case 'unit':
        return '-'; // Unit not stored in bill items
      case 'rate':
        return '${item.sellingPrice.toStringAsFixed(2)}';
      case 'discount':
        // Item-level discount not directly available, show bill discount
        return bill.discountPercent > 0
            ? '${bill.discountPercent.toStringAsFixed(1)}%'
            : '-';
      case 'tax':
        final itemTax = item.cgstPercent + item.sgstPercent;
        return itemTax > 0 ? '${itemTax.toStringAsFixed(1)}%' : '-';
      case 'amount':
        return '${item.subtotal.toStringAsFixed(2)}';
      default:
        return '-';
    }
  }

  /// Calculate column widths based on visible columns
  static Map<int, pw.TableColumnWidth> _calculateColumnWidths(
    int totalColumns,
    List<BillReportColumn> visibleColumns,
  ) {
    final widths = <int, pw.TableColumnWidth>{};

    // Fixed columns (first 4): Sr, Bill No, Date, Customer
    widths[0] = const pw.FlexColumnWidth(0.5); // Sr
    widths[1] = const pw.FlexColumnWidth(1.5); // Bill No
    widths[2] = const pw.FlexColumnWidth(1.2); // Date
    widths[3] = const pw.FlexColumnWidth(1.3); // Customer

    // Dynamic columns based on visible settings
    int colIdx = 4;
    for (final col in visibleColumns) {
      if (col.id != 'sr_no') {
        widths[colIdx] = pw.FlexColumnWidth(_getColumnFlex(col.id));
        colIdx++;
      }
    }

    // Last column: Bill Total
    widths[colIdx] = const pw.FlexColumnWidth(1.2);

    return widths;
  }

  /// Get flex value for column width
  static double _getColumnFlex(String columnId) {
    switch (columnId) {
      case 'product_name':
        return 2.0;
      case 'hsn_code':
        return 1.0;
      case 'company':
        return 1.3;
      case 'quantity':
        return 0.6;
      case 'unit':
        return 0.6;
      case 'rate':
        return 1.0;
      case 'discount':
        return 0.7;
      case 'tax':
        return 0.7;
      case 'amount':
        return 1.0;
      default:
        return 1.0;
    }
  }

  /// Print the PDF.
  static Future<void> printReport(Uint8List pdfBytes) async {
    debugPrint('[BillReport] Printing ${pdfBytes.length} bytes');
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name:
          'bill_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Share the PDF via system share sheet.
  static Future<void> shareReport(Uint8List pdfBytes) async {
    debugPrint('[BillReport] Sharing ${pdfBytes.length} bytes');
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final tempFile = File('${tempDir.path}/bill_report_$timestamp.pdf');
    await tempFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: 'application/pdf')],
      text: 'Bill Report — C-Billing',
      subject: 'Bill Report',
    );
  }

  /// Save PDF locally and return saved path.
  static Future<String?> saveLocally(Uint8List pdfBytes) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${docsDir.path}/Reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${reportsDir.path}/bill_report_$timestamp.pdf';
      await File(filePath).writeAsBytes(pdfBytes);
      debugPrint('[BillReport] Saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[BillReport] Save error: $e');
      return null;
    }
  }
}
