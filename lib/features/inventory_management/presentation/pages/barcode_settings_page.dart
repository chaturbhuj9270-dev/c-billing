// Barcode Settings: choose the printer type (normal / barcode / POS) and the
// label size, like the bill settings do for bills. Feature: barcode-labels.
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';

import '../../../../common_widgets/app_top_bar.dart';
import '../../../../core/printing/barcode_label/barcode_label_layout.dart';
import '../../../../core/printing/barcode_label/barcode_label_models.dart';
import '../../../../core/printing/barcode_label/barcode_label_settings_service.dart';
import '../../../../core/services/barcode_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/barcode_label_preview.dart';
import '../widgets/barcode_label_ui_helpers.dart';
import '../widgets/barcode_print_setup_panel.dart';

class BarcodeSettingsPage extends StatefulWidget {
  const BarcodeSettingsPage({super.key});

  @override
  State<BarcodeSettingsPage> createState() => _BarcodeSettingsPageState();
}

class _BarcodeSettingsPageState extends State<BarcodeSettingsPage> {
  final _svc = BarcodeLabelSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _svc.ensureLoaded();
    _svc.addListener(_onChanged);
    LanguageService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    _svc.removeListener(_onChanged);
    LanguageService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = barcodeL10n();
    final s = _svc.settings;
    final content = LabelContent.build(
      name: 'Sample product',
      code: '2000000000015',
      format: BarcodeFormat.ean13,
      settings: s,
      company: 'Brand',
      size: 'M',
      color: 'Blue',
      price: 99,
      mrp: 120,
      batchLabel: 'B-102',
      expiry: DateTime.now().add(const Duration(days: 365)),
    );
    final layout = computeLabelLayout(
      widthMm: s.widthMm,
      heightMm: s.heightMm,
      content: content,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            AppTopBar(
              title: l.barcodeSettings,
              subtitle: l.barcodeSettingsSubtitle,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _previewCard(
                        context,
                        l.labelPreviewTitle,
                        layout,
                        content,
                        s,
                      ),
                      const SizedBox(height: 20),
                      const BarcodePrintSetupPanel(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCard(
    BuildContext context,
    String title,
    LabelLayout layout,
    LabelContent content,
    BarcodeLabelSettings s,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                printerTypeIcon(s.printerType),
                size: 18,
                color: AppColors.action(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title · ${formatSizeMm(s.widthMm, s.heightMm)}',
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.chipFill(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: BarcodeLabelPreview(
                layout: layout,
                content: content,
                maxWidth: 300,
                maxHeight: 200,
                barcodeBuilder: (w, h) => bw.BarcodeWidget(
                  barcode: BarcodeService.instance.getBarcodeRenderer(
                    content.format,
                  ),
                  data: content.code,
                  drawText: false,
                  color: Colors.black,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
