import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/features/inventory_management/domain/entities/product.dart';

/// Report type enumeration
enum ReportType { outOfStock, lowStock, allProducts }

/// Report format enumeration
enum ReportFormat { pdf, csv }

/// Service for generating inventory reports
class InventoryReportService {
  static final InventoryReportService _instance =
      InventoryReportService._internal();
  factory InventoryReportService() => _instance;
  InventoryReportService._internal();

  /// Filter products based on report type
  List<Product> filterProducts(List<Product> products, ReportType reportType) {
    switch (reportType) {
      case ReportType.outOfStock:
        return products.where((p) => p.currentStock == 0).toList();
      case ReportType.lowStock:
        return products
            .where((p) => p.currentStock > 0 && p.currentStock <= 10)
            .toList();
      case ReportType.allProducts:
        return products;
    }
  }

  /// Get report type label
  String getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.outOfStock:
        return 'Out of Stock Products';
      case ReportType.lowStock:
        return 'Low Stock Products';
      case ReportType.allProducts:
        return 'All Products';
    }
  }

  /// Get stock status label
  String getStockStatus(int stock) {
    if (stock == 0) {
      return 'Out of Stock';
    } else if (stock <= 10) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  /// Generate PDF report
  Future<File> generatePdfReport({
    required List<Product> products,
    required ReportType reportType,
    String? shopName,
    String? customTitle,
    String? customSubtitle,
  }) async {
    final pdf = pw.Document();
    final reportTitle = customTitle ?? getReportTypeLabel(reportType);
    final reportSubtitle = customSubtitle;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final finalShopName = shopName ?? 'C-Billing Network';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          reportTitle,
          dateStr,
          finalShopName,
          reportSubtitle,
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildPdfSummary(products, reportType),
          pw.SizedBox(height: 20),
          _buildPdfTable(products),
        ],
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${reportType.name}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfHeader(
    String reportTitle,
    String dateStr,
    String? shopName,
    String? subtitle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (shopName != null && shopName.isNotEmpty)
                  pw.Text(
                    shopName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColors.grey800,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      subtitle,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated on:',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, color: PdfColors.green800),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildPdfSummary(List<Product> products, ReportType reportType) {
    final totalProducts = products.length;
    final totalStock = products.fold<int>(0, (sum, p) => sum + p.currentStock);
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + p.getStockValue(),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Products', totalProducts.toString()),
          _buildSummaryItem('Total Units', totalStock.toString()),
          _buildSummaryItem(
            'Total Value',
            'Rs.${NumberFormat('#,##0.00').format(totalValue)}',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Product> products) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      headers: [
        '#',
        'Product Name',
        'Category',
        'Company',
        'Stock',
        'Status',
        'Order Qty',
      ],
      data: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return [
          '${i + 1}',
          p.name,
          p.category,
          p.companyName,
          '${p.currentStock}',
          getStockStatus(p.currentStock),
          '-',
        ];
      }).toList(),
    );
  }

  /// Generate CSV report
  Future<File> generateCsvReport({
    required List<Product> products,
    required ReportType reportType,
    String? customTitle,
  }) async {
    final reportTitle = customTitle ?? getReportTypeLabel(reportType);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final buffer = StringBuffer();

    // Header info
    buffer.writeln('Report: $reportTitle');
    buffer.writeln('Generated: $dateStr');
    buffer.writeln('Total Products: ${products.length}');
    buffer.writeln('');

    // CSV headers
    buffer.writeln('S.No,Product Name,Category,Company,Stock,Status,Order Qty');

    // Data rows
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      buffer.writeln(
        '${i + 1},'
        '"${p.name.replaceAll('"', '""')}",'
        '"${p.category.replaceAll('"', '""')}",'
        '"${p.companyName.replaceAll('"', '""')}",'
        '${p.currentStock},'
        '"${getStockStatus(p.currentStock)}",'
        '-',
      );
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${reportType.name}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Share the generated report
  Future<void> shareReport(File file) async {
    await Share.shareXFiles([XFile(file.path)], subject: 'Inventory Report');
  }

  /// Generate PDF report with order quantities
  Future<File> generatePdfReportWithOrderQty({
    required List<Product> products,
    required List<int> orderQuantities,
    required ReportType reportType,
    String? shopName,
    String? customTitle,
    String? customSubtitle,
  }) async {
    final pdf = pw.Document();
    final reportTitle = customTitle ?? getReportTypeLabel(reportType);
    final reportSubtitle = customSubtitle;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final finalShopName = shopName ?? 'C-Billing Network';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          reportTitle,
          dateStr,
          finalShopName,
          reportSubtitle,
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildPdfSummary(products, reportType),
          pw.SizedBox(height: 20),
          _buildPdfTableWithOrderQty(products, orderQuantities),
        ],
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${reportType.name}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfTableWithOrderQty(
    List<Product> products,
    List<int> orderQuantities,
  ) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      headers: [
        '#',
        'Product Name',
        'Category',
        'Company',
        'Stock',
        'Status',
        'Order Qty',
      ],
      data: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final orderQty = i < orderQuantities.length ? orderQuantities[i] : 0;
        return [
          '${i + 1}',
          p.name,
          p.category,
          p.companyName,
          '${p.currentStock}',
          getStockStatus(p.currentStock),
          '$orderQty',
        ];
      }).toList(),
    );
  }

  /// Generate CSV report with order quantities
  Future<File> generateCsvReportWithOrderQty({
    required List<Product> products,
    required List<int> orderQuantities,
    required ReportType reportType,
    String? customTitle,
  }) async {
    final reportTitle = customTitle ?? getReportTypeLabel(reportType);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final buffer = StringBuffer();

    // Header info
    buffer.writeln('Report: $reportTitle');
    buffer.writeln('Generated: $dateStr');
    buffer.writeln('Total Products: ${products.length}');
    buffer.writeln('');

    // CSV headers
    buffer.writeln('S.No,Product Name,Category,Company,Stock,Status,Order Qty');

    // Data rows
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      final orderQty = i < orderQuantities.length ? orderQuantities[i] : 0;
      buffer.writeln(
        '${i + 1},'
        '"${p.name.replaceAll('"', '""')}",'
        '"${p.category.replaceAll('"', '""')}",'
        '"${p.companyName.replaceAll('"', '""')}",'
        '${p.currentStock},'
        '"${getStockStatus(p.currentStock)}",'
        '$orderQty',
      );
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${reportType.name}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file;
  }
}
