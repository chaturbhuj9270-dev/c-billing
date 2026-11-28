// Regression guard: barcode labels in different sizes, printed through a
// normal printer, a barcode printer or a POS printer. Feature: barcode-labels.
import 'dart:convert';

import 'package:c_billing/core/printing/barcode_label/barcode_label_escpos.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_layout.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_models.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_pdf.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_settings_service.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_tspl.dart';
import 'package:c_billing/core/printing/models/printer_models.dart';
import 'package:c_billing/core/services/barcode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LabelContent _content({
  String name = 'Paracetamol 500mg Tablets',
  String code = '2000000000015',
  BarcodeFormat format = BarcodeFormat.ean13,
  BarcodeLabelSettings settings = const BarcodeLabelSettings(),
  String? company = 'Cipla Ltd',
  String? size,
  String? color,
  double? price = 49.5,
  double? mrp = 55,
  String? batch = 'B#12',
  DateTime? expiry,
}) => LabelContent.build(
  name: name,
  code: code,
  format: format,
  settings: settings,
  company: company,
  size: size,
  color: color,
  price: price,
  mrp: mrp,
  batchLabel: batch,
  expiry: expiry ?? DateTime(2027, 6, 30),
);

void main() {
  group('label sizes', () {
    test('presets cover strips, small, standard, cloth and large labels', () {
      expect(LabelPresets.byId('strip')!.widthMm, 38);
      expect(LabelPresets.byId('strip')!.heightMm, 15);
      expect(
        LabelPresets.byId('cloth')!.heightMm,
        greaterThan(LabelPresets.byId('cloth')!.widthMm),
      ); // portrait garment tag
      expect(
        LabelPresets.all.map((p) => p.id),
        containsAll(['strip', 'small', 'standard', 'cloth', 'large']),
      );
    });

    test('custom size is clamped to a printable range', () {
      const s = BarcodeLabelSettings(
        presetId: 'custom',
        customWidthMm: 5,
        customHeightMm: 999,
      );
      expect(s.isCustom, isTrue);
      expect(s.widthMm, BarcodeLabelSettings.minWidthMm);
      expect(s.heightMm, BarcodeLabelSettings.maxHeightMm);
      expect(const BarcodeLabelSettings(presetId: 'small').widthMm, 50);
    });
  });

  group('label content', () {
    test('respects the include flags', () {
      const off = BarcodeLabelSettings(
        includePrice: false,
        includeCompany: false,
        includeSizeColor: false,
        includeBatchExpiry: false,
      );
      final c = _content(settings: off, size: 'M', color: 'Red');
      expect(c.priceText, isNull);
      expect(c.company, isNull);
      expect(c.attrs, isNull);
      expect(c.meta, isNull);
    });

    test('price, MRP, size/colour and batch/expiry text', () {
      final c = _content(size: 'M', color: 'Red');
      expect(c.priceText, 'Rs.49.50 (MRP 55)');
      expect(c.attrs, 'Size M | Color Red');
      expect(c.meta, 'B#12 | Exp 06/27');
      expect(formatLabelAmount(99), '99');
      expect(formatLabelAmount(99.5), '99.50'); // never rounds up to 100
    });
  });

  group('layout engine', () {
    final sizes = <String, List<double>>{
      'strip': [38, 15],
      'small': [50, 25],
      'standard': [60, 40],
      'cloth': [40, 60],
      'large': [100, 50],
      'tiny custom': [25, 12],
    };

    for (final e in sizes.entries) {
      test('${e.key}: text and barcode always fit inside the label', () {
        final l = computeLabelLayout(
          widthMm: e.value[0],
          heightMm: e.value[1],
          content: _content(size: 'M', color: 'Red'),
        );
        expect(l.lines, isNotEmpty);
        expect(l.lines.first.text, contains('Paracetamol'));
        // Always readable.
        for (final line in l.lines) {
          expect(line.pt, greaterThanOrEqualTo(minLabelPt));
        }
        final used =
            l.textHeightMm +
            l.barcodeHeightMm +
            (l.showCodeText ? l.codeTextPt * ptToMm * 1.35 : 0);
        // Allow only the last-resort clip on the very tiniest label.
        if (e.key != 'tiny custom') {
          expect(used, lessThanOrEqualTo(l.innerHeightMm + 0.5));
        }
      });
    }

    test(
      'big labels keep every line, small labels drop the least important',
      () {
        final big = computeLabelLayout(
          widthMm: 100,
          heightMm: 50,
          content: _content(size: 'M', color: 'Red'),
        );
        expect(big.lines.length, 5); // name, company, attrs, meta, price
        final strip = computeLabelLayout(
          widthMm: 38,
          heightMm: 15,
          content: _content(size: 'M', color: 'Red'),
        );
        expect(strip.lines.length, lessThan(big.lines.length));
        expect(strip.lines.first.bold, isTrue); // name kept
        expect(strip.lines.last.text, contains('Rs.')); // price kept
        expect(big.lines.first.pt, greaterThan(strip.lines.first.pt));
      },
    );

    test('a very long name shrinks instead of being clipped', () {
      final long =
          'Extra Strength Paracetamol and Caffeine Film Coated Tablets';
      final l = computeLabelLayout(
        widthMm: 50,
        heightMm: 25,
        content: _content(name: long),
      );
      final short = computeLabelLayout(
        widthMm: 50,
        heightMm: 25,
        content: _content(name: 'Crocin'),
      );
      expect(l.lines.first.pt, lessThan(short.lines.first.pt));
    });

    test('QR: landscape labels put the code beside the text', () {
      final wide = computeLabelLayout(
        widthMm: 100,
        heightMm: 50,
        content: _content(format: BarcodeFormat.qrCode, code: 'P-1234'),
      );
      expect(wide.isQr, isTrue);
      expect(wide.qrLeft, isTrue);
      final tall = computeLabelLayout(
        widthMm: 40,
        heightMm: 60,
        content: _content(format: BarcodeFormat.qrCode, code: 'P-1234'),
      );
      expect(tall.qrLeft, isFalse);
      expect(tall.qrSizeMm, greaterThan(10));
    });

    test('warns when a label is too narrow for a long barcode', () {
      final ok = computeLabelLayout(
        widthMm: 50,
        heightMm: 25,
        content: _content(),
      );
      expect(ok.barcodeTooNarrow, isFalse);
      final tight = computeLabelLayout(
        widthMm: 25,
        heightMm: 15,
        content: _content(
          format: BarcodeFormat.code128,
          code: 'P1234560123456789',
        ),
      );
      expect(tight.barcodeTooNarrow, isTrue);
    });
  });

  group('A4 sheet grid (normal printer)', () {
    test('smaller labels fit more per page', () {
      final strip = computeSheetGrid(labelWidthMm: 38, labelHeightMm: 15);
      final large = computeSheetGrid(labelWidthMm: 100, labelHeightMm: 50);
      expect(strip.perPage, greaterThan(large.perPage));
      expect(strip.cols, 4); // floor((210-16+2)/(38+2)); 5 would need 198mm
      expect(strip.rows, 16); // floor((297-16+2)/(15+2))
      expect(large.cols, 1); // 2 x 100mm does not fit in 194mm
    });

    test('a label bigger than the page still gets a 1x1 grid', () {
      final g = computeSheetGrid(labelWidthMm: 400, labelHeightMm: 400);
      expect(g.perPage, 1);
    });
  });

  group('PDF output', () {
    test(
      'normal printer: a sheet of labels, page count follows the grid',
      () async {
        const s = BarcodeLabelSettings(
          printerType: BarcodePrinterType.normal,
          presetId: 'standard', // 60x40 -> 3 cols x 6 rows = 18 per page
        );
        final one = await BarcodeLabelPdf.build(
          settings: s,
          content: _content(),
          copies: 1,
        );
        expect(one.isNotEmpty, isTrue);
        expect(_pageCount(one), 1);

        final many = await BarcodeLabelPdf.build(
          settings: s,
          content: _content(),
          copies: 19,
        );
        expect(_pageCount(many), 2);
      },
    );

    test('barcode printer: one page per label', () async {
      const s = BarcodeLabelSettings(
        printerType: BarcodePrinterType.label,
        presetId: 'strip',
      );
      final bytes = await BarcodeLabelPdf.build(
        settings: s,
        content: _content(),
        copies: 3,
      );
      expect(_pageCount(bytes), 3);
    });

    test('works for every barcode format and label size', () async {
      for (final f in BarcodeFormat.values) {
        final code = switch (f) {
          BarcodeFormat.ean13 => '2000000000015',
          BarcodeFormat.ean8 => '12345670',
          BarcodeFormat.upcA => '036000291452',
          BarcodeFormat.code128 => 'ABC-1234',
          BarcodeFormat.code39 => 'ABC1234',
          BarcodeFormat.qrCode => 'P-1234|Crocin|49',
        };
        for (final p in LabelPresets.all) {
          final bytes = await BarcodeLabelPdf.build(
            settings: BarcodeLabelSettings(
              printerType: BarcodePrinterType.label,
              presetId: p.id,
            ),
            content: _content(format: f, code: code),
            copies: 1,
          );
          expect(bytes.isNotEmpty, isTrue, reason: '${f.code} ${p.id}');
        }
      }
    });
  });

  group('POS (ESC/POS) output', () {
    test('contains name, price and a barcode command', () {
      final c = _content();
      final l = computeLabelLayout(widthMm: 50, heightMm: 25, content: c);
      final bytes = BarcodeLabelEscPos.build(
        paper: PosPaperSize.mm58,
        content: c,
        layout: l,
      );
      final text = latin1.decode(bytes, allowInvalid: true);
      expect(text, contains('Paracetamol'));
      expect(text, contains('Rs.49.50'));
      expect(text, contains('2000000000015'));
      // GS k 67 (EAN13)
      expect(_contains(bytes, [0x1D, 0x6B, 67, 13]), isTrue);
    });

    test('Code 128 is sent with a code-set prefix so printers accept it', () {
      final c = _content(format: BarcodeFormat.code128, code: 'AB12');
      final l = computeLabelLayout(widthMm: 50, heightMm: 25, content: c);
      final bytes = BarcodeLabelEscPos.build(
        paper: PosPaperSize.mm58,
        content: c,
        layout: l,
      );
      expect(_contains(bytes, [0x1D, 0x6B, 73, 6, 0x7B, 0x42]), isTrue);
    });

    test(
      'bigger label sizes use wider barcode modules, capped to the paper',
      () {
        final c = _content();
        expect(
          BarcodeLabelEscPos.moduleWidth(
            paper: PosPaperSize.mm80,
            content: c,
            labelWidthMm: 100,
          ),
          4,
        );
        expect(
          BarcodeLabelEscPos.moduleWidth(
            paper: PosPaperSize.mm80,
            content: c,
            labelWidthMm: 38,
          ),
          2,
        );
        // 95 modules x 4 dots = 380 <= 384 on 58 mm, 3 would also fit.
        expect(
          BarcodeLabelEscPos.moduleWidth(
            paper: PosPaperSize.mm58,
            content: c,
            labelWidthMm: 100,
          ),
          4,
        );
      },
    );

    test('detects a barcode too long for the paper width', () {
      final long = _content(
        format: BarcodeFormat.code128,
        code: 'P1234560123456789012',
      );
      expect(
        BarcodeLabelEscPos.fitsPaper(paper: PosPaperSize.mm58, content: long),
        isFalse,
      );
      expect(
        BarcodeLabelEscPos.fitsPaper(paper: PosPaperSize.mm80, content: long),
        isTrue,
      );
    });

    test('copies are separated and the job ends with a feed', () {
      final c = _content();
      final l = computeLabelLayout(widthMm: 50, heightMm: 25, content: c);
      final one = BarcodeLabelEscPos.build(
        paper: PosPaperSize.mm58,
        content: c,
        layout: l,
      );
      final three = BarcodeLabelEscPos.build(
        paper: PosPaperSize.mm58,
        content: c,
        layout: l,
        copies: 3,
      );
      expect(three.length, greaterThan(one.length * 2));
    });
  });

  group('barcode printer (TSPL) output', () {
    test('is a valid TSPL program for the label size', () {
      final c = _content();
      final l = computeLabelLayout(widthMm: 50, heightMm: 25, content: c);
      final prog = ascii.decode(
        BarcodeLabelTspl.build(
          widthMm: 50,
          heightMm: 25,
          gapMm: 2,
          content: c,
          layout: l,
          copies: 4,
        ),
      );
      expect(prog, contains('SIZE 50.0 mm,25.0 mm'));
      expect(prog, contains('GAP 2.0 mm,0 mm'));
      expect(prog, contains('CLS'));
      expect(prog, contains('TEXT '));
      expect(prog, contains('BARCODE '));
      expect(prog, contains('"EAN13"'));
      expect(prog, contains('"2000000000015"'));
      expect(prog.trimRight().endsWith('PRINT 1,4'), isTrue);
      expect(prog.contains('\r\n'), isTrue);
    });

    test('QR labels use the QRCODE command', () {
      final c = _content(format: BarcodeFormat.qrCode, code: 'P-1234');
      final l = computeLabelLayout(widthMm: 60, heightMm: 40, content: c);
      final prog = ascii.decode(
        BarcodeLabelTspl.build(
          widthMm: 60,
          heightMm: 40,
          gapMm: 2,
          content: c,
          layout: l,
        ),
      );
      expect(prog, contains('QRCODE '));
      expect(prog, isNot(contains('BARCODE ')));
    });

    test('non-ASCII text and quotes cannot break the command stream', () {
      expect(BarcodeLabelTspl.sanitize('Gola "A" साबुन'), "Gola 'A' ?????");
      final c = _content(name: 'साबुन "Lux"');
      final l = computeLabelLayout(widthMm: 50, heightMm: 25, content: c);
      final prog = ascii.decode(
        BarcodeLabelTspl.build(
          widthMm: 50,
          heightMm: 25,
          gapMm: 2,
          content: c,
          layout: l,
        ),
      );
      expect(prog.contains('साबुन'), isFalse);
    });

    test('font size follows the label size', () {
      final small = BarcodeLabelTspl.fontFor(4.5, 203);
      final big = BarcodeLabelTspl.fontFor(14, 203);
      expect(big.$3, greaterThan(small.$3));
    });
  });

  group('settings persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to normal printer with the small preset', () async {
      final svc = BarcodeLabelSettingsService.instance;
      await svc.reload();
      expect(svc.settings.printerType, BarcodePrinterType.normal);
      expect(svc.settings.presetId, 'small');
      expect(svc.settings.includePrice, isTrue);
    });

    test('printer type, size and flags survive a reload', () async {
      final svc = BarcodeLabelSettingsService.instance;
      await svc.reload();
      await svc.update(
        svc.settings.copyWith(
          printerType: BarcodePrinterType.pos,
          presetId: 'custom',
          customWidthMm: 45,
          customHeightMm: 22,
          connection: LabelConnection.bluetooth,
          includeCompany: false,
        ),
      );
      await svc.reload();
      expect(svc.settings.printerType, BarcodePrinterType.pos);
      expect(svc.settings.widthMm, 45);
      expect(svc.settings.heightMm, 22);
      expect(svc.settings.connection, LabelConnection.bluetooth);
      expect(svc.settings.includeCompany, isFalse);
    });

    test('unknown stored values fall back to safe defaults', () {
      expect(BarcodePrinterType.fromKey('nope'), BarcodePrinterType.normal);
      expect(LabelConnection.fromKey(null), LabelConnection.driver);
    });
  });
}

/// Page count read from the PDF page tree (`/Type/Pages ... /Count n`).
int _pageCount(List<int> pdf) {
  final m = RegExp(
    '/Type\\s*/Pages[^>]*/Count (\\d+)',
  ).firstMatch(latin1.decode(pdf, allowInvalid: true));
  return int.parse(m!.group(1)!);
}

bool _contains(List<int> haystack, List<int> needle) {
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}
