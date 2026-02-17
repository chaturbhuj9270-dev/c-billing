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
class PurchaseReportPdfGenerator {
  PurchaseReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate PDF bytes directly from purchase entities.
  static Future<Uint8List> generate({
    required List<PurchaseBatchEntity> purchases,
    String? filterDescription,
  }) async {
    debugPrint('[PurchaseReport] START: ${purchases.length} items');
    
    try {
      final now = DateTime.now();
      final pdf = pw.Document();
      
      debugPrint('[PurchaseReport] Document created');

      // Skip HSN lookup for now - just use empty map to avoid blocking
      final hsnMap = <String, String>{};
      debugPrint('[PurchaseReport] Skipping HSN lookup for performance');

      // Calculate totals
      int totalQty = 0, totalRemaining = 0;
      double totalPurchaseAmt = 0, totalSellingVal = 0;
      for (final p in purchases) {
        totalQty += p.quantityPurchased;
        totalRemaining += p.quantityRemaining;
        totalPurchaseAmt += p.purchasePrice * p.quantityPurchased;
        totalSellingVal += p.sellingPrice * p.quantityPurchased;
      }
      
      debugPrint('[PurchaseReport] Totals calculated');

      // Build table data with HSN code
      final data = <List<String>>[
        ['Sr', 'Product', 'HSN', 'Company', 'Supplier', 'Date', 'Qty', 'Stock', 'Price', 'Total'],
      ];
      
      for (int i = 0; i < purchases.length; i++) {
        final p = purchases[i];
        final hsn = hsnMap[p.productId] ?? '-';
        data.add([
          '${i + 1}',
          p.productName.length > 18 ? '${p.productName.substring(0, 18)}...' : p.productName,
          hsn,
          p.companyName.length > 12 ? '${p.companyName.substring(0, 12)}...' : p.companyName,
          (p.supplierName ?? '-').length > 10 ? '${p.supplierName!.substring(0, 10)}...' : (p.supplierName ?? '-'),
          _dateFmt.format(p.purchaseDate),
          '${p.quantityPurchased}',
          '${p.quantityRemaining}',
          p.purchasePrice.toStringAsFixed(2),
          (p.purchasePrice * p.quantityPurchased).toStringAsFixed(2),
        ]);
      }
      
      debugPrint('[PurchaseReport] Table data built: ${data.length} rows');

      // Add single page with table
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Purchase Report',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_dateTimeFmt.format(now),
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 8),
                
                // Filter info
                if (filterDescription != null)
                  pw.Text('Filter: $filterDescription',
                      style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 10),
                
                // Table using TableHelper
                pw.Expanded(
                  child: pw.Table.fromTextArray(
                    headerStyle: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.grey300),
                    cellHeight: 18,
                    data: data,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 6),
                
                // Summary row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Total Purchases: ${purchases.length}',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total Qty: $totalQty',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Remaining: $totalRemaining',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total Amount: Rs ${totalPurchaseAmt.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      debugPrint('[PurchaseReport] Page added, saving...');
      
      final bytes = await pdf.save();
      
      debugPrint('[PurchaseReport] DONE: ${bytes.length} bytes');
      return bytes;
      
    } catch (e, stack) {
      debugPrint('[PurchaseReport] ERROR in generate: $e');
      debugPrint('[PurchaseReport] Stack: $stack');
      rethrow;
    }
  }

  /// Print the PDF.
  static Future<void> printReport(Uint8List pdfBytes) async {
    debugPrint('[PurchaseReport] Printing ${pdfBytes.length} bytes');
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'purchase_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Share the PDF via system share sheet.
  static Future<void> shareReport(Uint8List pdfBytes) async {
    debugPrint('[PurchaseReport] Sharing ${pdfBytes.length} bytes');
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
      debugPrint('[PurchaseReport] Saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[PurchaseReport] Save error: $e');
      return null;
    }
  }
}
