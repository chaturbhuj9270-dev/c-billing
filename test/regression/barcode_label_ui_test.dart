// Widget smoke tests for the barcode label UI (feature: barcode-labels):
// every preset renders without layout errors and the settings panel persists
// choices.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:c_billing/core/printing/barcode_label/barcode_label_layout.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_models.dart';
import 'package:c_billing/core/printing/barcode_label/barcode_label_settings_service.dart';
import 'package:c_billing/core/services/barcode_service.dart';
import 'package:c_billing/features/inventory_management/presentation/widgets/barcode_label_preview.dart';
import 'package:c_billing/features/inventory_management/presentation/widgets/barcode_print_setup_panel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('preview renders for every preset and format without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final formats = {
      BarcodeFormat.ean13: '2000000000015',
      BarcodeFormat.code128: 'ITEM-12345',
      BarcodeFormat.qrCode: 'ITEM-12345',
    };
    final sizes = <List<double>>[
      for (final p in LabelPresets.all) [p.widthMm, p.heightMm],
      [20, 10],
      [150, 150],
    ];
    for (final f in formats.entries) {
      for (final size in sizes) {
        const settings = BarcodeLabelSettings();
        final content = LabelContent.build(
          name: 'A very long product name that needs wrapping on the label',
          code: f.value,
          format: f.key,
          settings: settings,
          company: 'Some Company Pvt Ltd',
          size: 'XL',
          color: 'Navy Blue',
          price: 1299,
          mrp: 1599,
          batchLabel: 'BATCH-2025-001',
          expiry: DateTime(2027, 3, 1),
        );
        final layout = computeLabelLayout(
          widthMm: size[0],
          heightMm: size[1],
          content: content,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BarcodeLabelPreview(
                  layout: layout,
                  content: content,
                  barcodeBuilder: (w, h) => const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${f.key} ${size[0]}x${size[1]}',
        );
      }
    }
  });

  testWidgets('setup panel changes and persists printer type and size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final svc = BarcodeLabelSettingsService.instance;
    await svc.reload();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: BarcodePrintSetupPanel()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(svc.settings.printerType, BarcodePrinterType.normal);

    await tester.tap(find.text('POS Printer').first);
    await tester.pump();
    expect(svc.settings.printerType, BarcodePrinterType.pos);

    await tester.tap(find.text('Cloth tag'));
    await tester.pump();
    expect(svc.settings.presetId, 'cloth');
    expect(svc.settings.widthMm, 40);
    expect(svc.settings.heightMm, 60);

    await tester.tap(find.text('Custom'));
    await tester.pump();
    expect(svc.settings.isCustom, isTrue);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.first, '70');
    await tester.enterText(fields.last, '45');
    await tester.pump();
    expect(svc.settings.widthMm, 70);
    expect(svc.settings.heightMm, 45);

    // Persisted: a fresh load returns the same choices.
    await svc.reload();
    expect(svc.settings.printerType, BarcodePrinterType.pos);
    expect(svc.settings.isCustom, isTrue);
    expect(svc.settings.widthMm, 70);

    // restore defaults for other tests
    await svc.update(const BarcodeLabelSettings());
  });
}
