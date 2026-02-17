import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../offline/entities/purchase_batch_entity.dart';

/// Fast PDF generator for Purchase Reports.
/// Uses pre-computed data and direct pw.Table for speed.
class PurchaseReportPdfGenerator {
  PurchaseReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static const _green = PdfColor.fromInt(0xFF1B4D3E);

  /// Generate PDF bytes directly from purchase entities.
  static Future<Uint8List> generate({
    required List<PurchaseBatchEntity> purchases,
    String? filterDescription,
  }) async {
    debugPrint('[PurchaseReport] Building PDF for ${purchases.length} items...');
    final sw = Stopwatch()..start();

    final now = DateTime.now();
    final pdf = pw.Document(title: 'Purchase Report', creator: 'C-Billing');

    final hdrStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    const cellStyle = pw.TextStyle(fontSize: 8);

    // ── Pre-compute all table data + row colours in one pass ──
    int totalQty = 0, totalRemaining = 0;
    double totalPurchaseAmt = 0, totalSellingVal = 0;

    final tableRows = <pw.TableRow>[];
    for (int i = 0; i < purchases.length; i++) {
      final p = purchases[i];
      final lineAmt = p.purchasePrice * p.quantityPurchased;
      totalQty += p.quantityPurchased;
      totalRemaining += p.quantityRemaining;
      totalPurchaseAmt += lineAmt;
      totalSellingVal += p.sellingPrice * p.quantityPurchased;

      // Row colour
      PdfColor? bg;
      if (p.expiryDate != null && p.expiryDate!.isBefore(now)) {
        bg = const PdfColor.fromInt(0xFFFFEBEE);
      } else if (p.expiryDate != null &&
          p.expiryDate!.isBefore(now.add(const Duration(days: 7)))) {
        bg = const PdfColor.fromInt(0xFFFFF8E1);
      } else if (i.isEven) {
        bg = const PdfColor.fromInt(0xFFFAFAFA);
      }

      final cells = [
        '${i + 1}',
        p.productName,
        p.companyName,
        p.supplierName ?? '-',
        _dateFmt.format(p.purchaseDate),
        '${p.quantityPurchased}',
        '${p.quantityRemaining}',
        p.unit,
        _fmtAmt(p.purchasePrice),
        _fmtAmt(p.sellingPrice),
        _fmtAmt(lineAmt),
        p.expiryDate != null ? _dateFmt.format(p.expiryDate!) : '-',
      ];

      tableRows.add(pw.TableRow(
        decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
        children: cells
            .map((c) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: pw.Text(c, style: cellStyle),
                ))
            .toList(),
      ));
    }

    // Column widths
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.5),
      1: const pw.FlexColumnWidth(2.0),
      2: const pw.FlexColumnWidth(1.5),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FlexColumnWidth(1.0),
      5: const pw.FlexColumnWidth(0.7),
      6: const pw.FlexColumnWidth(0.7),
      7: const pw.FlexColumnWidth(0.6),
      8: const pw.FlexColumnWidth(1.0),
      9: const pw.FlexColumnWidth(1.0),
      10: const pw.FlexColumnWidth(1.2),
      11: const pw.FlexColumnWidth(1.0),
    };

    const headers = [
      'Sr.', 'Product', 'Company', 'Supplier', 'Date', 'Qty',
      'Stock', 'Unit', 'Pur. Price', 'Sell Price', 'Total Amt', 'Expiry',
    ];

    // Header row
    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: _green),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4, vertical: 6),
                child: pw.Text(h, style: hdrStyle),
              ))
          .toList(),
    );

    // ── Assemble page ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: _green, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Purchase Report',
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _green)),
              pw.Text(_dateTimeFmt.format(now),
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          // Filter label
          if (filterDescription != null && filterDescription.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('Filter: $filterDescription',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
            ),

          // Data table
          if (tableRows.isNotEmpty)
            pw.Table(
              border: null,
              columnWidths: colWidths,
              children: [headerRow, ...tableRows],
            )
          else
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No purchase data available for the selected filters.',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                ),
              ),
            ),

          pw.SizedBox(height: 16),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _green, width: 1),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _green)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  _summaryCell('Total Purchases', '${purchases.length}'),
                  _summaryCell('Total Quantity', '$totalQty'),
                  _summaryCell('Remaining Stock', '$totalRemaining'),
                  _summaryCell('Total Purchase Amt',
                      _fmtAmt(totalPurchaseAmt),
                      color: PdfColors.blue800),
                  _summaryCell('Total Selling Value',
                      _fmtAmt(totalSellingVal),
                      color: PdfColors.green800),
                ]),
              ],
            ),
          ),

          pw.SizedBox(height: 10),
          pw.Row(children: [
            _legendDot(const PdfColor.fromInt(0xFFFFEBEE), 'Expired'),
            pw.SizedBox(width: 16),
            _legendDot(
                const PdfColor.fromInt(0xFFFFF8E1), 'Expiring Within 7 Days'),
          ]),
        ],
      ),
    );

    final bytes = await pdf.save();
    sw.stop();
    debugPrint('[PurchaseReport] PDF built in ${sw.elapsedMilliseconds}ms (${bytes.length} bytes)');
    return bytes;
  }

  // ─── Actions ───────────────────────────────────────────────────

  /// Print the PDF.
  static Future<void> printReport(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name:
          'purchase_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Share the PDF via system share sheet.
  static Future<void> shareReport(Uint8List pdfBytes) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final tempFile = File('${tempDir.path}/purchase_report_$timestamp.pdf');
    await tempFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: 'application/pdf')],
      text: 'Purchase Report — C-Billing',
      subject: 'Purchase Report',
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
      final filePath = '${reportsDir.path}/purchase_report_$timestamp.pdf';
      await File(filePath).writeAsBytes(pdfBytes);
      return filePath;
    } catch (e) {
      debugPrint('[PurchaseReport] Save error: $e');
      return null;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  static pw.Widget _summaryCell(String label, String value,
      {PdfColor color = PdfColors.black}) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _legendDot(PdfColor color, String label) {
    return pw.Row(children: [
      pw.Container(width: 10, height: 10, color: color),
      pw.SizedBox(width: 4),
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ]);
  }

  static String _fmtAmt(double val) {
    if (val == 0) return '₹0';
    if (val < 0) return '-₹${val.abs().toStringAsFixed(2)}';
    return '₹${val.toStringAsFixed(2)}';
  }
}
