import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/purchase_report_settings_service.dart';
import '../../../../core/services/product_settings_service.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';

/// Fast PDF generator for Purchase Reports.
/// Generates reports with columns based on user's Report Settings.
class PurchaseReportPdfGenerator {
  PurchaseReportPdfGenerator._();

  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate PDF bytes directly from purchase entities.
  /// Uses PurchaseReportSettingsService to determine visible columns.
  static Future<Uint8List> generate({
    required List<PurchaseBatchEntity> purchases,
    String? filterDescription,
  }) async {
    debugPrint('[PurchaseReport] START: ${purchases.length} items');
    
    try {
      final now = DateTime.now();
      final pdf = pw.Document();
      
      debugPrint('[PurchaseReport] Document created');

      // Initialize report settings and get visible columns
      await PurchaseReportSettingsService.instance.init();
      final visibleColumns = PurchaseReportSettingsService.instance.visibleColumns;
      
      debugPrint('[PurchaseReport] Visible columns: ${visibleColumns.map((c) => c.id).toList()}');

      // Load product custom fields for all products
      final customFieldsMap = await _loadProductCustomFields(purchases);
      
      // Get custom columns definition
      final customColumnsDef = ProductSettingsService.instance.activeCustomColumns;

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

      // Build dynamic header based on visible columns
      final headers = <String>[];
      for (final col in visibleColumns) {
        headers.add(_getColumnHeader(col.id, col.name));
      }

      // Build table data
      final data = <List<String>>[headers];
      
      for (int i = 0; i < purchases.length; i++) {
        final p = purchases[i];
        final productCustomFields = customFieldsMap[p.productId] ?? {};
        final row = <String>[];
        
        for (final col in visibleColumns) {
          row.add(_getCellValue(
            col.id, 
            p, 
            i + 1, 
            productCustomFields, 
            customColumnsDef,
          ));
        }
        
        data.add(row);
      }
      
      debugPrint('[PurchaseReport] Table data built: ${data.length} rows, ${headers.length} columns');

      // Calculate column widths based on visible columns
      final columnWidths = _calculateColumnWidths(visibleColumns);

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
                  pw.Text('Purchase Report',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_dateTimeFmt.format(now),
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 4),
              if (filterDescription != null)
                pw.Text('Filter: $filterDescription',
                    style: const pw.TextStyle(fontSize: 9)),
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
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Row(
                    children: [
                      pw.Text('Total: ${purchases.length} items',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text('Qty: $totalQty',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text('Stock: $totalRemaining',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text('Amount: Rs ${totalPurchaseAmt.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300),
              cellHeight: 20,
              columnWidths: columnWidths,
              data: data,
            ),
          ],
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

  /// Load custom fields for all products in purchases
  static Future<Map<String, Map<String, dynamic>>> _loadProductCustomFields(
    List<PurchaseBatchEntity> purchases,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    final productIds = purchases.map((p) => p.productId).toSet();
    
    for (final productId in productIds) {
      try {
        final product = await ProductOfflineController.instance
            .getProductByServerId(productId);
        if (product != null && 
            product.customFieldsJson != null && 
            product.customFieldsJson!.isNotEmpty) {
          result[productId] = jsonDecode(product.customFieldsJson!) 
              as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('[PurchaseReport] Error loading custom fields for $productId: $e');
      }
    }
    
    return result;
  }

  /// Get column header text
  static String _getColumnHeader(String columnId, String defaultName) {
    switch (columnId) {
      case 'sr_no': return 'Sr';
      case 'product_name': return 'Product';
      case 'hsn_code': return 'HSN';
      case 'company': return 'Company';
      case 'supplier': return 'Supplier';
      case 'purchase_date': return 'Date';
      case 'quantity': return 'Qty';
      case 'stock': return 'Stock';
      case 'purchase_price': return 'Price';
      case 'selling_price': return 'Sale Price';
      case 'total': return 'Total';
      case 'unit': return 'Unit';
      case 'production_date': return 'Prod. Date';
      case 'expiry_date': return 'Expiry';
      case 'warranty': return 'Warranty';
      case 'notes': return 'Notes';
      default:
        // Custom columns - use the name
        if (columnId.startsWith('custom_')) {
          return defaultName;
        }
        return defaultName;
    }
  }

  /// Get cell value for a column
  static String _getCellValue(
    String columnId,
    PurchaseBatchEntity p,
    int index,
    Map<String, dynamic> customFields,
    List<CustomColumn> customColumnsDef,
  ) {
    switch (columnId) {
      case 'sr_no':
        return '$index';
      case 'product_name':
        return p.productName.length > 20 
            ? '${p.productName.substring(0, 20)}...' 
            : p.productName;
      case 'hsn_code':
        return '-'; // HSN lookup can be added later
      case 'company':
        return p.companyName.length > 15 
            ? '${p.companyName.substring(0, 15)}...' 
            : p.companyName;
      case 'supplier':
        final supplier = p.supplierName ?? '-';
        return supplier.length > 12 
            ? '${supplier.substring(0, 12)}...' 
            : supplier;
      case 'purchase_date':
        return _dateFmt.format(p.purchaseDate);
      case 'quantity':
        return '${p.quantityPurchased}';
      case 'stock':
        return '${p.quantityRemaining}';
      case 'purchase_price':
        return p.purchasePrice.toStringAsFixed(2);
      case 'selling_price':
        return p.sellingPrice.toStringAsFixed(2);
      case 'total':
        return (p.purchasePrice * p.quantityPurchased).toStringAsFixed(2);
      case 'unit':
        return p.unit;
      case 'production_date':
        return p.productionDate != null 
            ? _dateFmt.format(p.productionDate!) 
            : '-';
      case 'expiry_date':
        return p.expiryDate != null 
            ? _dateFmt.format(p.expiryDate!) 
            : '-';
      case 'warranty':
        return p.warrantyMonths != null && p.warrantyMonths! > 0
            ? '${p.warrantyMonths}m'
            : '-';
      case 'notes':
        final notes = p.notes ?? '-';
        return notes.length > 20 ? '${notes.substring(0, 20)}...' : notes;
      default:
        // Handle custom columns
        if (columnId.startsWith('custom_')) {
          final customId = columnId.replaceFirst('custom_', '');
          final value = customFields[customId];
          if (value == null) return '-';
          
          // Find the column definition to format properly
          final colDef = customColumnsDef.firstWhere(
            (c) => c.id == customId,
            orElse: () => CustomColumn(
              id: customId, 
              name: '', 
              type: CustomColumnType.text,
            ),
          );
          
          return _formatCustomValue(value, colDef.type);
        }
        return '-';
    }
  }

  /// Format custom field value based on type
  static String _formatCustomValue(dynamic value, CustomColumnType type) {
    if (value == null) return '-';
    
    switch (type) {
      case CustomColumnType.date:
        try {
          final date = DateTime.parse(value.toString());
          return _dateFmt.format(date);
        } catch (_) {
          return value.toString();
        }
      case CustomColumnType.boolean:
        return value == true || value == 'true' ? 'Yes' : 'No';
      case CustomColumnType.decimal:
        final num = double.tryParse(value.toString());
        return num?.toStringAsFixed(2) ?? value.toString();
      default:
        final str = value.toString();
        return str.length > 15 ? '${str.substring(0, 15)}...' : str;
    }
  }

  /// Calculate column widths based on visible columns
  static Map<int, pw.TableColumnWidth> _calculateColumnWidths(
    List<ReportColumn> visibleColumns,
  ) {
    final widths = <int, pw.TableColumnWidth>{};
    
    for (int i = 0; i < visibleColumns.length; i++) {
      final col = visibleColumns[i];
      widths[i] = pw.FlexColumnWidth(_getColumnFlex(col.id));
    }
    
    return widths;
  }

  /// Get flex value for column width
  static double _getColumnFlex(String columnId) {
    switch (columnId) {
      case 'sr_no': return 0.5;
      case 'product_name': return 2.5;
      case 'hsn_code': return 1.0;
      case 'company': return 1.5;
      case 'supplier': return 1.5;
      case 'purchase_date': return 1.2;
      case 'quantity': return 0.7;
      case 'stock': return 0.7;
      case 'purchase_price': return 1.0;
      case 'selling_price': return 1.0;
      case 'total': return 1.2;
      case 'unit': return 0.7;
      case 'production_date': return 1.2;
      case 'expiry_date': return 1.2;
      case 'warranty': return 0.8;
      case 'notes': return 2.0;
      default: return 1.2; // Custom columns
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
