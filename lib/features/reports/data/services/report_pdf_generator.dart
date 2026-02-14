import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/report_result_model.dart';

/// Professional PDF generator for inventory reports.
/// Generates landscape PDF with:
///   - Company header
///   - Filter summary
///   - Data table with colour-coded rows
///   - Summary totals
///   - Page numbers
class ReportPdfGenerator {
  ReportPdfGenerator._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static const _green = PdfColor.fromInt(0xFF1B4D3E);
  static const _red = PdfColor.fromInt(0xFFD32F2F);
  static const _amber = PdfColor.fromInt(0xFFF57F17);

  /// Generate PDF document from report result.
  static Future<Uint8List> generate(ReportResultModel report) async {
    final pdf = pw.Document(
      title: 'Inventory Report',
      author: 'C-Billing',
      creator: 'C-Billing App',
    );

    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = const pw.TextStyle(fontSize: 8);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(report, context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // ── Filter Summary ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              report.filterSummary,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 12),

          // ── Data Table ──
          if (report.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: _green),
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              oddCellStyle: cellStyle,
              headerHeight: 28,
              cellHeight: 24,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),  // Product
                1: const pw.FlexColumnWidth(1.5),  // Company
                2: const pw.FlexColumnWidth(1.5),  // Supplier
                3: const pw.FlexColumnWidth(0.8),  // Pur Qty
                4: const pw.FlexColumnWidth(0.8),  // Sold Qty
                5: const pw.FlexColumnWidth(0.8),  // Ret Qty
                6: const pw.FlexColumnWidth(0.8),  // Stock
                7: const pw.FlexColumnWidth(1),    // Pur Price
                8: const pw.FlexColumnWidth(1),    // Sell Price
                9: const pw.FlexColumnWidth(1.2),  // Pur Amt
                10: const pw.FlexColumnWidth(1.2), // Sales Amt
                11: const pw.FlexColumnWidth(1.2), // Profit/Loss
                12: const pw.FlexColumnWidth(1.2), // Expiry
              },
              headers: [
                'Product',
                'Company',
                'Supplier',
                'Pur Qty',
                'Sold',
                'Return',
                'Stock',
                'Pur Price',
                'Sell Price',
                'Pur Amt',
                'Sales Amt',
                'P/L',
                'Expiry',
              ],
              data: report.rows.map((r) {
                return [
                  r.productName,
                  r.companyName,
                  r.supplierName,
                  '${r.purchaseQty}',
                  '${r.soldQty}',
                  '${r.returnedQty}',
                  '${r.currentStock}',
                  _fmtAmt(r.purchasePrice),
                  _fmtAmt(r.sellingPrice),
                  _fmtAmt(r.totalPurchaseAmount),
                  _fmtAmt(r.totalSalesAmount),
                  _fmtAmt(r.profitOrLoss),
                  r.expiryDate != null
                      ? _dateFormat.format(r.expiryDate!)
                      : '-',
                ];
              }).toList(),
              cellDecoration: (index, data, rowNum) {
                if (rowNum < 0 || rowNum >= report.rows.length) {
                  return const pw.BoxDecoration();
                }
                final row = report.rows[rowNum];
                if (row.isExpired) {
                  return const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFEBEE));
                }
                if (row.isExpiringThisWeek) {
                  return const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFF8E1));
                }
                if (rowNum % 2 == 0) {
                  return const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFAFAFA));
                }
                return const pw.BoxDecoration();
              },
            )
          else
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'No data available for the selected filters.',
                  style: pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey600),
                ),
              ),
            ),
          pw.SizedBox(height: 16),

          // ── Summary Section ──
          _buildSummarySection(report),

          // ── Legend ──
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _buildLegendDot(const PdfColor.fromInt(0xFFFFEBEE), 'Expired'),
            pw.SizedBox(width: 16),
            _buildLegendDot(
                const PdfColor.fromInt(0xFFFFF8E1), 'Expiring This Week'),
          ]),
        ],
      ),
    );

    return pdf.save();
  }

  /// Share / print / save the PDF.
  static Future<void> shareOrPrint(
      BuildContext context, Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'inventory_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  // ── HEADER ──
  static pw.Widget _buildHeader(
      ReportResultModel report, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Inventory Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _green,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated: ${_dateTimeFormat.format(report.generatedAt)}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'C-Billing',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _green,
                ),
              ),
              pw.Text(
                'Total Products: ${report.totalProducts}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FOOTER with page numbers ──
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  // ── SUMMARY ──
  static pw.Widget _buildSummarySection(ReportResultModel report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _green, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _green,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildSummaryCell(
                'Total Purchase', _fmtAmt(report.totalPurchaseAmount)),
            _buildSummaryCell(
                'Total Sales', _fmtAmt(report.totalSalesAmount)),
            _buildSummaryCell('Total Profit', _fmtAmt(report.totalProfit),
                color: PdfColors.green800),
            _buildSummaryCell('Total Loss', _fmtAmt(report.totalLoss),
                color: _red),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            _buildSummaryCell(
                'Expired Stock Value', _fmtAmt(report.expiredStockValue),
                color: _red),
            _buildSummaryCell(
                'Returned Stock Value', _fmtAmt(report.returnedStockValue)),
            _buildSummaryCell('Expired Items', '${report.expiredCount}',
                color: _red),
            _buildSummaryCell(
                'Low Stock Items', '${report.lowStockCount}',
                color: _amber),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCell(String label, String value,
      {PdfColor color = PdfColors.black}) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
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

  static pw.Widget _buildLegendDot(PdfColor color, String label) {
    return pw.Row(children: [
      pw.Container(width: 10, height: 10, color: color),
      pw.SizedBox(width: 4),
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ]);
  }

  static String _fmtAmt(double val) {
    if (val == 0) return '₹0';
    if (val < 0) return '-₹${val.abs().toStringAsFixed(0)}';
    return '₹${val.toStringAsFixed(0)}';
  }
}
