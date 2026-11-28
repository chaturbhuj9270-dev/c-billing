// Localised names for barcode printer types and label presets. Feature:
// barcode-labels.
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/printing/barcode_label/barcode_label_models.dart';
import '../../../../core/services/language_service.dart';

AppLocalizations barcodeL10n() =>
    AppLocalizations(LanguageService.instance.currentLanguage);

String printerTypeName(AppLocalizations l, BarcodePrinterType t) {
  switch (t) {
    case BarcodePrinterType.normal:
      return l.normalPrinterTitle;
    case BarcodePrinterType.label:
      return l.barcodePrinterTitle;
    case BarcodePrinterType.pos:
      return l.posPrinter;
  }
}

String printerTypeSubtitle(AppLocalizations l, BarcodePrinterType t) {
  switch (t) {
    case BarcodePrinterType.normal:
      return l.normalPrinterSub;
    case BarcodePrinterType.label:
      return l.barcodePrinterSub;
    case BarcodePrinterType.pos:
      return l.posPrinterSub;
  }
}

IconData printerTypeIcon(BarcodePrinterType t) {
  switch (t) {
    case BarcodePrinterType.normal:
      return Icons.print_rounded;
    case BarcodePrinterType.label:
      return Icons.label_rounded;
    case BarcodePrinterType.pos:
      return Icons.receipt_long_rounded;
  }
}

String presetName(AppLocalizations l, String id) {
  switch (id) {
    case 'strip':
      return l.sizeTabletStrip;
    case 'small':
      return l.sizeSmallLabel;
    case 'standard':
      return l.sizeStandardLabel;
    case 'cloth':
      return l.sizeClothTag;
    case 'large':
      return l.sizeLargeLabel;
    default:
      return l.sizeCustomLabel;
  }
}

String presetUse(AppLocalizations l, String id) {
  switch (id) {
    case 'strip':
      return l.useTabletStrip;
    case 'small':
      return l.useSmallLabel;
    case 'standard':
      return l.useStandardLabel;
    case 'cloth':
      return l.useClothTag;
    case 'large':
      return l.useLargeLabel;
    default:
      return l.useCustomLabel;
  }
}

IconData presetIcon(String id) {
  switch (id) {
    case 'strip':
      return Icons.medication_rounded;
    case 'small':
      return Icons.sell_rounded;
    case 'standard':
      return Icons.inventory_2_rounded;
    case 'cloth':
      return Icons.checkroom_rounded;
    case 'large':
      return Icons.all_inbox_rounded;
    default:
      return Icons.straighten_rounded;
  }
}

/// "50 × 25 mm" with no trailing ".0".
String formatSizeMm(double w, double h) => '${_mm(w)} × ${_mm(h)} mm';

String _mm(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
