// Printer type + label size + label content controls. Used on the Barcode
// Settings page; every change is saved straight away (like bill settings).
// Feature: barcode-labels.
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/printing/barcode_label/barcode_label_layout.dart';
import '../../../../core/printing/barcode_label/barcode_label_models.dart';
import '../../../../core/printing/barcode_label/barcode_label_settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'barcode_label_ui_helpers.dart';

class BarcodePrintSetupPanel extends StatefulWidget {
  const BarcodePrintSetupPanel({super.key});

  @override
  State<BarcodePrintSetupPanel> createState() => _BarcodePrintSetupPanelState();
}

class _BarcodePrintSetupPanelState extends State<BarcodePrintSetupPanel> {
  final _svc = BarcodeLabelSettingsService.instance;
  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;

  BarcodeLabelSettings get _s => _svc.settings;

  @override
  void initState() {
    super.initState();
    _wCtrl = TextEditingController(text: _fmt(_s.customWidthMm));
    _hCtrl = TextEditingController(text: _fmt(_s.customHeightMm));
    _svc.addListener(_onChanged);
  }

  @override
  void dispose() {
    _svc.removeListener(_onChanged);
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  void _set(BarcodeLabelSettings next) => _svc.update(next);

  void _onCustomSize() {
    final w = double.tryParse(_wCtrl.text.replaceAll(',', '.'));
    final h = double.tryParse(_hCtrl.text.replaceAll(',', '.'));
    if (w == null || h == null) return;
    if (w < BarcodeLabelSettings.minWidthMm ||
        w > BarcodeLabelSettings.maxWidthMm ||
        h < BarcodeLabelSettings.minHeightMm ||
        h > BarcodeLabelSettings.maxHeightMm) {
      return;
    }
    _set(_s.copyWith(customWidthMm: w, customHeightMm: h));
  }

  @override
  Widget build(BuildContext context) {
    final l = barcodeL10n();
    final s = _s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          context,
          l.printerTypeTitle,
          Column(
            children: [
              for (final t in BarcodePrinterType.values)
                _typeTile(context, l, t, s.printerType == t),
            ],
          ),
        ),
        _section(context, l.labelSizeTitle, _sizeGrid(context, l, s)),
        _section(context, l.printerConnection, _typeDetails(context, l, s)),
        _section(
          context,
          l.labelContentTitle,
          Column(
            children: [
              _switchTile(
                context,
                l.labelShowPrice,
                null,
                s.includePrice,
                (v) => _set(s.copyWith(includePrice: v)),
              ),
              _switchTile(
                context,
                l.labelShowCompany,
                null,
                s.includeCompany,
                (v) => _set(s.copyWith(includeCompany: v)),
              ),
              _switchTile(
                context,
                l.labelShowSizeColor,
                l.labelShowSizeColorSub,
                s.includeSizeColor,
                (v) => _set(s.copyWith(includeSizeColor: v)),
              ),
              _switchTile(
                context,
                l.labelShowBatchExpiry,
                l.labelShowBatchExpirySub,
                s.includeBatchExpiry,
                (v) => _set(s.copyWith(includeBatchExpiry: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- pieces

  Widget _section(BuildContext context, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _typeTile(
    BuildContext context,
    AppLocalizations l,
    BarcodePrinterType t,
    bool selected,
  ) {
    final accent = AppColors.action(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.10)
            : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _set(_s.copyWith(printerType: t)),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? accent : AppColors.border(context),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: selected ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(printerTypeIcon(t), color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printerTypeName(l, t),
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        printerTypeSubtitle(l, t),
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 12.5,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? accent : AppColors.mutedText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sizeGrid(
    BuildContext context,
    AppLocalizations l,
    BarcodeLabelSettings s,
  ) {
    final accent = AppColors.action(context);
    final entries = <String>[
      ...LabelPresets.all.map((p) => p.id),
      LabelPresets.customId,
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 520 ? 3 : 2;
        final w = (c.maxWidth - 10 * (perRow - 1)) / perRow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in entries)
                  SizedBox(
                    width: w,
                    child: _sizeChip(
                      context,
                      l,
                      id,
                      id == LabelPresets.customId
                          ? s.isCustom
                          : s.presetId == id,
                      accent,
                      s,
                    ),
                  ),
              ],
            ),
            if (s.isCustom) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sizeField(context, _wCtrl, l.widthMmLabel)),
                  const SizedBox(width: 12),
                  Expanded(child: _sizeField(context, _hCtrl, l.heightMmLabel)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _sizeChip(
    BuildContext context,
    AppLocalizations l,
    String id,
    bool selected,
    Color accent,
    BarcodeLabelSettings s,
  ) {
    final preset = LabelPresets.byId(id);
    final sizeText = preset != null
        ? formatSizeMm(preset.widthMm, preset.heightMm)
        : formatSizeMm(s.customWidthMm, s.customHeightMm);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.10)
          : AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _set(_s.copyWith(presetId: id)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : AppColors.border(context),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(presetIcon(id), size: 20, color: accent),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 18, color: accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                presetName(l, id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(context),
                ),
              ),
              Text(
                sizeText,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                presetUse(l, id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 11.5,
                  color: AppColors.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizeField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _onCustomSize(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputFill(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
      ),
    );
  }

  /// Connection / sheet details that depend on the printer type.
  Widget _typeDetails(
    BuildContext context,
    AppLocalizations l,
    BarcodeLabelSettings s,
  ) {
    final accent = AppColors.action(context);
    switch (s.printerType) {
      case BarcodePrinterType.normal:
        final grid = computeSheetGrid(
          labelWidthMm: s.widthMm,
          labelHeightMm: s.heightMm,
        );
        return Column(
          children: [
            _infoRow(
              context,
              Icons.grid_view_rounded,
              '${grid.perPage} ${l.labelsPerSheetSuffix} '
              '(${grid.cols} × ${grid.rows})',
            ),
            _switchTile(
              context,
              l.cutGuideBorder,
              l.cutGuideBorderSub,
              s.cutBorder,
              (v) => _set(s.copyWith(cutBorder: v)),
            ),
          ],
        );
      case BarcodePrinterType.label:
        return Material(
          color: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: RadioGroup<LabelConnection>(
            groupValue: s.connection,
            onChanged: (v) {
              if (v != null) _set(_s.copyWith(connection: v));
            },
            child: Column(
              children: [
                for (final c in LabelConnection.values)
                  RadioListTile<LabelConnection>(
                    value: c,
                    activeColor: accent,
                    dense: true,
                    title: Text(
                      c == LabelConnection.driver
                          ? l.connViaDriver
                          : l.connViaBluetooth,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 14,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      case BarcodePrinterType.pos:
        return _infoRow(context, Icons.info_outline_rounded, l.posPaperNote);
    }
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chipFill(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.action(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    BuildContext context,
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.action(context),
          dense: true,
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 12,
                    color: AppColors.secondaryText(context),
                  ),
                ),
        ),
      ),
    );
  }
}
