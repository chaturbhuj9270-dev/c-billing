import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../services/barcode_service.dart';
import 'barcode_label_layout.dart';
import 'barcode_label_models.dart';

/// Builds barcode label PDFs for the Normal printer (labels in a grid on A4
/// sheets) and the Barcode printer (one page per label, exact label size).
/// Feature: barcode-labels.
class BarcodeLabelPdf {
  BarcodeLabelPdf._();

  static const int maxCopies = 1000;
  static const double _mm = PdfPageFormat.mm;

  /// One label as a PDF widget, exactly [LabelLayout.widthMm] x heightMm.
  static pw.Widget buildLabel(
    LabelLayout l,
    LabelContent c, {
    bool border = false,
  }) {
    final barcode = BarcodeService.instance.getBarcodeRenderer(c.format);

    final texts = pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        for (final line in l.lines)
          pw.Text(
            line.text,
            maxLines: line.maxLines,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: line.pt,
              height: 1.2,
              fontWeight: line.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
      ],
    );

    final pw.Widget body;
    if (l.isQr) {
      final qr = pw.BarcodeWidget(
        barcode: barcode,
        data: c.code,
        width: l.qrSizeMm * _mm,
        height: l.qrSizeMm * _mm,
        drawText: false,
      );
      body = l.qrLeft
          ? pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                qr,
                pw.SizedBox(width: 1.5 * _mm),
                pw.Expanded(child: pw.Center(child: texts)),
              ],
            )
          : pw.Column(
              children: [
                pw.Expanded(child: pw.Center(child: texts)),
                pw.SizedBox(height: 1 * _mm),
                qr,
              ],
            );
    } else {
      final codeTextMm = l.showCodeText ? l.codeTextPt * ptToMm * 1.35 : 0.0;
      body = pw.Column(
        children: [
          pw.Expanded(child: pw.Center(child: texts)),
          pw.SizedBox(height: 1 * _mm),
          pw.BarcodeWidget(
            barcode: barcode,
            data: c.code,
            width: l.barcodeWidthMm * _mm,
            height: (l.barcodeHeightMm + codeTextMm) * _mm,
            drawText: l.showCodeText,
            textPadding: 1,
            textStyle: pw.TextStyle(fontSize: l.codeTextPt),
          ),
        ],
      );
    }

    return pw.SizedBox(
      width: l.widthMm * _mm,
      height: l.heightMm * _mm,
      child: pw.ClipRect(
        child: pw.Container(
          padding: pw.EdgeInsets.all(l.padMm * _mm),
          decoration: border
              ? pw.BoxDecoration(
                  border: pw.Border.all(width: 0.3, color: PdfColors.grey600),
                )
              : null,
          child: body,
        ),
      ),
    );
  }

  /// PDF for [copies] labels for the configured printer type.
  /// `label` -> one page per label at the exact label size;
  /// anything else -> labels in a grid on A4 sheets.
  static Future<Uint8List> build({
    required BarcodeLabelSettings settings,
    required LabelContent content,
    required int copies,
  }) async {
    final count = copies.clamp(1, maxCopies);
    final layout = computeLabelLayout(
      widthMm: settings.widthMm,
      heightMm: settings.heightMm,
      content: content,
    );
    final doc = pw.Document();

    if (settings.printerType == BarcodePrinterType.label) {
      final format = PdfPageFormat(
        settings.widthMm * _mm,
        settings.heightMm * _mm,
        marginAll: 0,
      );
      for (var i = 0; i < count; i++) {
        doc.addPage(
          pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (_) => buildLabel(layout, content),
          ),
        );
      }
      return doc.save();
    }

    final grid = computeSheetGrid(
      labelWidthMm: settings.widthMm,
      labelHeightMm: settings.heightMm,
    );
    for (var start = 0; start < count; start += grid.perPage) {
      final onPage = (count - start).clamp(1, grid.perPage);
      final rows = <pw.Widget>[];
      for (var r = 0; r * grid.cols < onPage; r++) {
        final cells = <pw.Widget>[];
        for (var c = 0; c < grid.cols && r * grid.cols + c < onPage; c++) {
          if (c > 0) cells.add(pw.SizedBox(width: grid.gapMm * _mm));
          cells.add(buildLabel(layout, content, border: settings.cutBorder));
        }
        if (r > 0) rows.add(pw.SizedBox(height: grid.gapMm * _mm));
        rows.add(pw.Row(children: cells));
      }
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(grid.marginMm * _mm),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      );
    }
    return doc.save();
  }
}
