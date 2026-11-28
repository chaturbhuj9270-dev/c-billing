import 'dart:convert';

import '../../services/barcode_service.dart' show BarcodeFormat;
import '../formatters/esc_pos_bill_formatter.dart' show EscPosCommands;
import '../models/printer_models.dart';
import '../receipt_text_layout.dart';
import 'barcode_label_layout.dart';
import 'barcode_label_models.dart';

/// ESC/POS bytes for labels on a POS thermal receipt printer (58 / 80 mm).
/// The label size preset controls text size, barcode height and width.
/// Feature: barcode-labels.
class BarcodeLabelEscPos {
  BarcodeLabelEscPos._();

  /// Dots per mm on 203 dpi thermal heads.
  static const double dotsPerMm = 8;

  /// Modules of the symbol itself (no quiet zone).
  static int symbolModules(BarcodeFormat f, String data) {
    switch (f) {
      case BarcodeFormat.ean13:
      case BarcodeFormat.upcA:
        return 95;
      case BarcodeFormat.ean8:
        return 67;
      case BarcodeFormat.code128:
        return 11 * (data.length + 3) + 2;
      case BarcodeFormat.code39:
        return 16 * (data.length + 2);
      case BarcodeFormat.qrCode:
        return qrModulesFor(data.length);
    }
  }

  /// Module width (dots) that fits the paper, preferring wider modules for
  /// bigger label sizes. Returns 0 when even the narrowest module overflows.
  static int moduleWidth({
    required PosPaperSize paper,
    required LabelContent content,
    required double labelWidthMm,
  }) {
    final modules = symbolModules(content.format, content.code);
    final maxFit = paper.dotsPerLine ~/ modules;
    if (maxFit < 2) return 0;
    final desired = labelWidthMm >= 75 ? 4 : (labelWidthMm >= 45 ? 3 : 2);
    return desired < maxFit ? desired : maxFit;
  }

  /// False when the barcode cannot be printed on this paper width (e.g. a long
  /// Code 128 on 58 mm paper).
  static bool fitsPaper({
    required PosPaperSize paper,
    required LabelContent content,
  }) =>
      content.format == BarcodeFormat.qrCode ||
      moduleWidth(paper: paper, content: content, labelWidthMm: 0) > 0;

  static List<int> _enc(String s) {
    try {
      return latin1.encode(s);
    } catch (_) {
      return utf8.encode(s);
    }
  }

  static List<int> _line(String text) => [
    ..._enc(text),
    ...EscPosCommands.lineFeed,
  ];

  static List<int> _barcode(LabelContent c) {
    switch (c.format) {
      case BarcodeFormat.code128:
        // GS k 73 needs a code-set prefix ("{B" = Code set B) to print.
        final data = '{B${c.code}';
        return [0x1D, 0x6B, 73, data.length, ...data.codeUnits];
      case BarcodeFormat.code39:
        return EscPosCommands.printCode39(c.code);
      case BarcodeFormat.ean13:
        return EscPosCommands.printEAN13(c.code);
      case BarcodeFormat.ean8:
        return EscPosCommands.printEAN8(c.code);
      case BarcodeFormat.upcA:
        return EscPosCommands.printUPCA(c.code);
      case BarcodeFormat.qrCode:
        return const [];
    }
  }

  static List<int> build({
    required PosPaperSize paper,
    required LabelContent content,
    required LabelLayout layout,
    int copies = 1,
  }) {
    final cols = paper.charsPerLine;
    final out = <int>[
      ...EscPosCommands.init,
      ...EscPosCommands.setLineSpacing(26),
    ];
    final count = copies < 1 ? 1 : copies;
    final isQr = content.format == BarcodeFormat.qrCode;

    for (var i = 0; i < count; i++) {
      out.addAll(EscPosCommands.alignCenter);

      for (var li = 0; li < layout.lines.length; li++) {
        final line = layout.lines[li];
        final isName = li == 0;
        final big = isName && line.pt >= 9;
        if (line.bold) out.addAll(EscPosCommands.boldOn);
        if (big) out.addAll(EscPosCommands.textDoubleHeight);
        var wrapped = wrapReceiptText(line.text, cols);
        // Names may use up to 3 lines on paper; details stay on one.
        final maxLines = isName ? (line.maxLines < 3 ? 3 : line.maxLines) : 1;
        if (wrapped.length > maxLines) wrapped = wrapped.sublist(0, maxLines);
        for (final w in wrapped) {
          out.addAll(_line(w));
        }
        if (big) out.addAll(EscPosCommands.textNormal);
        if (line.bold) out.addAll(EscPosCommands.boldOff);
      }

      if (isQr) {
        final qrDots = layout.qrSizeMm * dotsPerMm;
        final target = qrDots < 96 ? 96.0 : qrDots;
        final cap = paper.dotsPerLine * 0.8;
        final area = target > cap ? cap : target;
        final modules = qrModulesFor(content.code.length) + 8;
        var size = (area / modules).floor();
        if (size < 3) size = 3;
        if (size > 8) size = 8;
        out.addAll(EscPosCommands.printQRCode(content.code, moduleSize: size));
      } else {
        final height = (layout.barcodeHeightMm * dotsPerMm).round().clamp(
          40,
          162,
        );
        var module = moduleWidth(
          paper: paper,
          content: content,
          labelWidthMm: layout.widthMm,
        );
        if (module == 0) module = 2;
        out.addAll(EscPosCommands.setBarcodeHeight(height));
        out.addAll(EscPosCommands.setBarcodeWidth(module));
        out.addAll(EscPosCommands.setHRIPosition(layout.showCodeText ? 2 : 0));
        out.addAll(EscPosCommands.setHRIFont(1));
        out.addAll(_barcode(content));
        out.addAll(EscPosCommands.lineFeed);
      }

      out.addAll(EscPosCommands.feedLines(2));
      if (i < count - 1) {
        out.addAll(_line('- ' * (cols ~/ 2)));
        out.addAll(EscPosCommands.feedLines(1));
      }
    }

    out.addAll(EscPosCommands.alignLeft);
    out.addAll(EscPosCommands.feedLines(3));
    return out;
  }
}
