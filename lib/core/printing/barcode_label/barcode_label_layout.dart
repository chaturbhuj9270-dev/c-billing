// Pure layout engine for barcode labels: given a label size and its content it
// decides font sizes, which lines fit and the barcode size. The PDF, Flutter
// preview, ESC/POS and TSPL renderers all consume the same [LabelLayout] so a
// label looks the same everywhere. Feature: barcode-labels.
import 'dart:math' as math;

import '../../services/barcode_service.dart' show BarcodeFormat;
import 'barcode_label_models.dart';

/// 1 typographic point in millimetres.
const double ptToMm = 25.4 / 72;

/// Minimum readable font size on a label.
const double minLabelPt = 4.5;

class LabelLine {
  final String text;
  final double pt;
  final bool bold;
  final int maxLines;
  const LabelLine(this.text, this.pt, {this.bold = false, this.maxLines = 1});

  double get heightMm => pt * ptToMm * 1.2 * maxLines;
}

class LabelLayout {
  final double widthMm;
  final double heightMm;
  final double padMm;
  final List<LabelLine> lines;

  final bool isQr;
  final double qrSizeMm;

  /// QR on the left with text on the right (wide labels); otherwise stacked.
  final bool qrLeft;

  final double barcodeWidthMm;
  final double barcodeHeightMm;
  final bool showCodeText;
  final double codeTextPt;

  /// True when the label is too narrow to print the barcode at a scannable
  /// size (pick a shorter format, e.g. EAN-8 / Code 128, or a bigger label).
  final bool barcodeTooNarrow;

  const LabelLayout({
    required this.widthMm,
    required this.heightMm,
    required this.padMm,
    required this.lines,
    required this.isQr,
    required this.qrSizeMm,
    required this.qrLeft,
    required this.barcodeWidthMm,
    required this.barcodeHeightMm,
    required this.showCodeText,
    required this.codeTextPt,
    required this.barcodeTooNarrow,
  });

  double get innerWidthMm => widthMm - 2 * padMm;
  double get innerHeightMm => heightMm - 2 * padMm;

  /// Height used by the text lines.
  double get textHeightMm => lines.fold(0.0, (s, l) => s + l.heightMm);
}

/// Approximate module count of a symbol including quiet zones.
double estimatedBarcodeModules(BarcodeFormat format, String data) {
  switch (format) {
    case BarcodeFormat.ean13:
    case BarcodeFormat.upcA:
      return 95 + 18;
    case BarcodeFormat.ean8:
      return 67 + 14;
    case BarcodeFormat.code128:
      return 11.0 * (data.length + 3) + 2 + 20;
    case BarcodeFormat.code39:
      return 16.0 * (data.length + 2) + 20;
    case BarcodeFormat.qrCode:
      return qrModulesFor(data.length) + 8.0;
  }
}

/// QR modules per side for byte-mode, error-correction M.
int qrModulesFor(int dataLength) {
  if (dataLength <= 14) return 21;
  if (dataLength <= 26) return 25;
  if (dataLength <= 42) return 29;
  if (dataLength <= 62) return 33;
  if (dataLength <= 84) return 37;
  if (dataLength <= 106) return 41;
  return 45;
}

/// Narrowest module that scans reliably on a typical reader.
const double minModuleMm = 0.25;

LabelLayout computeLabelLayout({
  required double widthMm,
  required double heightMm,
  required LabelContent content,
}) {
  final w = widthMm;
  final h = heightMm;
  final pad = (math.min(w, h) * 0.06).clamp(0.8, 3.0).toDouble();
  final innerW = w - 2 * pad;
  final innerH = h - 2 * pad;
  final isQr = content.format == BarcodeFormat.qrCode;
  const gap = 1.0;

  double textW;
  double textH;
  var qrLeft = false;
  var qrSize = 0.0;
  var barcodeW = 0.0;
  var barcodeH = 0.0;
  var showCode = false;
  var codeTextPt = 0.0;

  if (isQr) {
    final landscape = w / h >= 1.5;
    if (landscape) {
      qrLeft = true;
      qrSize = math.min(innerH, innerW * 0.45);
      textW = innerW - qrSize - 1.5;
      textH = innerH;
    } else {
      qrSize = math.min(innerW * 0.8, innerH * 0.5);
      textW = innerW;
      textH = innerH - qrSize - gap;
    }
  } else {
    barcodeW = innerW;
    barcodeH = (innerH * 0.40).clamp(5.0, 30.0).toDouble();
    showCode = innerH >= 12;
    codeTextPt = (innerH * 0.17).clamp(minLabelPt, 9.0).toDouble();
    final codeTextMm = showCode ? codeTextPt * ptToMm * 1.35 : 0.0;
    textW = innerW;
    textH = innerH - barcodeH - codeTextMm - gap;
  }
  if (textH < 0) textH = 0;

  final basePt = (innerH * 0.30).clamp(5.0, 14.0).toDouble();
  final maxNameLines = innerH >= 40 ? 3 : (innerH >= 20 ? 2 : 1);

  List<LabelLine>? tryFit(double scale, int drop, {bool allowClip = false}) {
    final namePt = math.max(minLabelPt, basePt * scale);
    final detailPt = math.max(minLabelPt, namePt * 0.82);
    final pricePt = math.max(minLabelPt, namePt * 1.15);

    final avgCharMm = namePt * ptToMm * 0.58;
    final charsPerLine = math.max(1, (textW / avgCharMm).floor());
    final neededNameLines = content.name.isEmpty
        ? 1
        : (content.name.length / charsPerLine).ceil();
    // Shrink the text before ever clipping the product name.
    if (neededNameLines > maxNameLines && !allowClip) return null;
    final nameLines = neededNameLines.clamp(1, maxNameLines);

    final lines = <LabelLine>[
      LabelLine(content.name, namePt, bold: true, maxLines: nameLines),
      if (drop < 1 && content.company != null)
        LabelLine(content.company!, detailPt),
      if (drop < 3 && content.attrs != null)
        LabelLine(content.attrs!, detailPt),
      if (drop < 2 && content.meta != null) LabelLine(content.meta!, detailPt),
      if (content.priceText != null)
        LabelLine(content.priceText!, pricePt, bold: true),
    ];
    final total = lines.fold(0.0, (s, l) => s + l.heightMm);
    return total <= textH + 1e-9 ? lines : null;
  }

  List<LabelLine>? picked;
  outer:
  for (var drop = 0; drop <= 3; drop++) {
    for (final scale in const [1.0, 0.9, 0.8, 0.7]) {
      picked = tryFit(scale, drop);
      if (picked != null) break outer;
    }
  }
  // Last resort: smallest readable text, name on one line (+ price if it fits).
  picked ??=
      tryFit(0.5, 3, allowClip: true) ??
      [LabelLine(content.name, minLabelPt, bold: true)];

  final tooNarrow =
      !isQr &&
      innerW <
          estimatedBarcodeModules(content.format, content.code) * minModuleMm;

  return LabelLayout(
    widthMm: w,
    heightMm: h,
    padMm: pad,
    lines: picked,
    isQr: isQr,
    qrSizeMm: qrSize,
    qrLeft: qrLeft,
    barcodeWidthMm: barcodeW,
    barcodeHeightMm: barcodeH,
    showCodeText: showCode,
    codeTextPt: codeTextPt,
    barcodeTooNarrow: tooNarrow,
  );
}

/// Grid of labels on a sheet (normal printer).
class SheetGrid {
  final int cols;
  final int rows;
  final double marginMm;
  final double gapMm;
  const SheetGrid(this.cols, this.rows, this.marginMm, this.gapMm);
  int get perPage => cols * rows;
}

SheetGrid computeSheetGrid({
  required double labelWidthMm,
  required double labelHeightMm,
  double pageWidthMm = 210,
  double pageHeightMm = 297,
  double marginMm = 8,
  double gapMm = 2,
}) {
  int fit(double page, double label) {
    final n = ((page - 2 * marginMm + gapMm) / (label + gapMm)).floor();
    return n < 1 ? 1 : n;
  }

  return SheetGrid(
    fit(pageWidthMm, labelWidthMm),
    fit(pageHeightMm, labelHeightMm),
    marginMm,
    gapMm,
  );
}
