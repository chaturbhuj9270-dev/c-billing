import 'dart:convert';

import '../../services/barcode_service.dart' show BarcodeFormat;
import 'barcode_label_layout.dart';
import 'barcode_label_models.dart';

/// TSPL commands for Bluetooth / USB barcode (label roll) printers such as
/// TSC, Xprinter, Munbyn, etc. Built from the same [LabelLayout] as the PDF so
/// every label size prints consistently. Feature: barcode-labels.
///
/// Note: TSPL built-in fonts are ASCII only; other characters print as '?'.
class BarcodeLabelTspl {
  BarcodeLabelTspl._();

  /// Built-in bitmap fonts: id -> (char width, char height) in dots.
  static const _fonts = <(String, int, int)>[
    ('1', 8, 12),
    ('2', 12, 20),
    ('3', 16, 24),
    ('4', 24, 32),
    ('5', 32, 48),
  ];

  static String sanitize(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      if (r == 0x22) {
        buf.write("'");
      } else if (r >= 0x20 && r < 0x7F) {
        buf.writeCharCode(r);
      } else {
        buf.write('?');
      }
    }
    return buf.toString();
  }

  static String _barcodeType(BarcodeFormat f) {
    switch (f) {
      case BarcodeFormat.code128:
        return '128';
      case BarcodeFormat.code39:
        return '39';
      case BarcodeFormat.ean13:
        return 'EAN13';
      case BarcodeFormat.ean8:
        return 'EAN8';
      case BarcodeFormat.upcA:
        return 'UPCA';
      case BarcodeFormat.qrCode:
        return 'QR';
    }
  }

  static int _modules(BarcodeFormat f, String data) {
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

  /// Picks the largest built-in font whose height fits [pt] points.
  static (String, int, int) fontFor(double pt, int dpi) {
    final wantDots = pt * ptToMm * dpi / 25.4;
    var best = _fonts.first;
    for (final f in _fonts) {
      if (f.$3 <= wantDots * 1.15) best = f;
    }
    return best;
  }

  /// TSPL program for [copies] labels, as ASCII bytes with CRLF line ends.
  static List<int> build({
    required double widthMm,
    required double heightMm,
    required double gapMm,
    required LabelContent content,
    required LabelLayout layout,
    int copies = 1,
    int dpi = 203,
  }) {
    double dots(double mm) => mm * dpi / 25.4;
    final padD = dots(layout.padMm).round();
    final innerW = dots(widthMm).round() - 2 * padD;
    final cmds = <String>[
      'SIZE ${widthMm.toStringAsFixed(1)} mm,${heightMm.toStringAsFixed(1)} mm',
      'GAP ${gapMm.toStringAsFixed(1)} mm,0 mm',
      'DIRECTION 1,0',
      'REFERENCE 0,0',
      'CODEPAGE 1252',
      'CLS',
    ];

    var y = padD;
    var textLeft = padD;
    var textW = innerW;
    final isQr = content.format == BarcodeFormat.qrCode;

    if (isQr && layout.qrLeft) {
      final qrDots = dots(layout.qrSizeMm).round();
      final cell = _qrCell(qrDots, content.code);
      final side = (qrDots - cell * (qrModulesFor(content.code.length))) ~/ 2;
      cmds.add(
        'QRCODE $padD,${y + (side < 0 ? 0 : side)},M,$cell,A,0,"${sanitize(content.code)}"',
      );
      textLeft = padD + qrDots + dots(1.5).round();
      textW = innerW - qrDots - dots(1.5).round();
    }

    // Text lines (vertically centred in the free text area is approximated by
    // stacking from the top, which matches the PDF layout closely).
    for (var li = 0; li < layout.lines.length; li++) {
      final line = layout.lines[li];
      final font = fontFor(line.pt, dpi);
      final maxChars = textW ~/ font.$2;
      if (maxChars < 1) continue;
      final text = sanitize(line.text);
      final chunks = <String>[];
      if (line.maxLines <= 1 || text.length <= maxChars) {
        chunks.add(text.length > maxChars ? text.substring(0, maxChars) : text);
      } else {
        var rest = text;
        while (rest.isNotEmpty && chunks.length < line.maxLines) {
          if (rest.length <= maxChars) {
            chunks.add(rest);
            rest = '';
          } else {
            var cut = rest.lastIndexOf(' ', maxChars);
            if (cut <= 0) cut = maxChars;
            chunks.add(rest.substring(0, cut).trim());
            rest = rest.substring(cut).trim();
          }
        }
      }
      for (final chunk in chunks) {
        final x = textLeft + (textW - chunk.length * font.$2) ~/ 2;
        cmds.add(
          'TEXT ${x < textLeft ? textLeft : x},$y,"${font.$1}",0,1,1,"$chunk"',
        );
        y += (font.$3 * 1.15).round();
      }
    }

    if (isQr && !layout.qrLeft) {
      final qrDots = dots(layout.qrSizeMm).round();
      final cell = _qrCell(qrDots, content.code);
      final used = cell * qrModulesFor(content.code.length);
      final x = padD + (innerW - used) ~/ 2;
      final bottom = dots(heightMm).round() - padD - used;
      cmds.add(
        'QRCODE ${x < padD ? padD : x},${bottom > y ? bottom : y},M,$cell,A,0,"${sanitize(content.code)}"',
      );
    } else if (!isQr) {
      final modules = _modules(content.format, content.code);
      var narrow = innerW ~/ modules;
      if (narrow < 1) narrow = 1;
      if (narrow > 4) narrow = 4;
      final width = modules * narrow;
      final x = padD + (innerW - width) ~/ 2;
      final barH = dots(layout.barcodeHeightMm).round();
      final humanTextDots = layout.showCodeText ? 24 : 0;
      final bottom = dots(heightMm).round() - padD - barH - humanTextDots;
      final wide = content.format == BarcodeFormat.code39
          ? narrow * 3
          : narrow * 2;
      cmds.add(
        'BARCODE ${x < padD ? padD : x},${bottom > y ? bottom : y},"${_barcodeType(content.format)}",$barH,${layout.showCodeText ? 1 : 0},0,$narrow,$wide,"${sanitize(content.code)}"',
      );
    }

    cmds.add('PRINT 1,${copies < 1 ? 1 : copies}');
    return ascii.encode('${cmds.join('\r\n')}\r\n');
  }

  static int _qrCell(int sideDots, String data) {
    final cell = sideDots ~/ (qrModulesFor(data.length) + 2);
    if (cell < 2) return 2;
    if (cell > 10) return 10;
    return cell;
  }
}
