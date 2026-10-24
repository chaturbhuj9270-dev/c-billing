import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:c_billing/core/theme/app_theme.dart';
import '../../domain/models/unified_report_kind.dart';

class UnifiedReportExportResult {
  final Uint8List bytes;
  final String fileName;
  final UnifiedExportFormat format;

  const UnifiedReportExportResult({
    required this.bytes,
    required this.fileName,
    required this.format,
  });
}

/// Exports a [UnifiedReportTable] to PDF or Excel-compatible CSV.
class UnifiedReportExportService {
  UnifiedReportExportService._();
  static final UnifiedReportExportService instance =
      UnifiedReportExportService._();

  static final _stamp = DateFormat('yyyyMMdd_HHmm');

  Future<UnifiedReportExportResult> export({
    required UnifiedReportTable table,
    required UnifiedExportFormat format,
  }) async {
    final safeTitle = table.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final base = '${safeTitle}_${_stamp.format(DateTime.now())}';

    switch (format) {
      case UnifiedExportFormat.pdf:
        final bytes = await _toPdf(table);
        return UnifiedReportExportResult(
          bytes: bytes,
          fileName: '$base.pdf',
          format: format,
        );
      case UnifiedExportFormat.excel:
        final bytes = _toExcelCsv(table);
        return UnifiedReportExportResult(
          bytes: bytes,
          fileName: '$base.csv',
          format: format,
        );
    }
  }

  /// Helvetica (default pdf font) has no Unicode — strip ₹ / · / etc.
  static String _pdfSafe(String input) {
    return input
        .replaceAll('₹', 'Rs ')
        .replaceAll('·', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('…', '...')
        .replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E]'), '');
  }

  Future<Uint8List> _toPdf(UnifiedReportTable table) async {
    final pdf = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final headers = table.headers.map(_pdfSafe).toList();
    final rows = table.rows
        .map((r) => r.map(_pdfSafe).toList())
        .toList();
    final data = <List<String>>[headers, ...rows];
    final summary = table.summaryLine == null
        ? null
        : _pdfSafe(table.summaryLine!);
    final filter = _pdfSafe(table.filterDescription);
    final title = _pdfSafe(table.title);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(now, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(filter, style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 6),
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
                if (summary != null && summary.isNotEmpty)
                  pw.Text(
                    summary,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        build: (context) => [
          if (rows.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Center(
                child: pw.Text(
                  'No records for this selection.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(AppTheme.grey300.toARGB32()),
              ),
              cellHeight: 18,
              cellAlignments: {
                for (var i = 0; i < headers.length; i++)
                  i: pw.Alignment.centerLeft,
              },
              data: data,
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (bytes.isEmpty ||
        bytes.length < 4 ||
        String.fromCharCodes(bytes.take(4)) != '%PDF') {
      throw Exception('PDF generation produced an invalid file');
    }
    return bytes;
  }

  /// UTF-8 BOM CSV — opens cleanly in Excel / Google Sheets / Numbers.
  Uint8List _toExcelCsv(UnifiedReportTable table) {
    final buf = StringBuffer();
    buf.write('\uFEFF'); // BOM for Excel
    buf.writeln(_csvLine(table.headers));
    for (final row in table.rows) {
      buf.writeln(_csvLine(row));
    }
    if (table.summaryLine != null && table.summaryLine!.isNotEmpty) {
      buf.writeln();
      buf.writeln(_csvLine([table.summaryLine!]));
    }
    return Uint8List.fromList(utf8.encode(buf.toString()));
  }

  String _csvLine(List<String> cells) {
    return cells.map(_csvEscape).join(',');
  }

  String _csvEscape(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
