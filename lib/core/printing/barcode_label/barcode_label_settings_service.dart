import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'barcode_label_models.dart';

/// Persists [BarcodeLabelSettings] (printer type, label size, content flags),
/// like the bill settings do for the bill printer. Local only - no Firestore.
class BarcodeLabelSettingsService extends ChangeNotifier {
  BarcodeLabelSettingsService._();
  static final BarcodeLabelSettingsService instance =
      BarcodeLabelSettingsService._();

  static const keyPrinterType = 'barcode_printer_type';
  static const keyPreset = 'barcode_label_preset';
  static const keyCustomWidth = 'barcode_label_custom_width_mm';
  static const keyCustomHeight = 'barcode_label_custom_height_mm';
  static const keyConnection = 'barcode_label_connection';
  static const keyGap = 'barcode_label_gap_mm';
  static const keyCutBorder = 'barcode_label_cut_border';
  static const keyIncludePrice = 'barcode_label_include_price';
  static const keyIncludeCompany = 'barcode_label_include_company';
  static const keyIncludeSizeColor = 'barcode_label_include_size_color';
  static const keyIncludeBatchExpiry = 'barcode_label_include_batch_expiry';

  BarcodeLabelSettings _settings = const BarcodeLabelSettings();
  bool _loaded = false;

  BarcodeLabelSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await reload();
  }

  Future<void> reload() async {
    final p = await SharedPreferences.getInstance();
    const d = BarcodeLabelSettings();
    _settings = BarcodeLabelSettings(
      printerType: BarcodePrinterType.fromKey(p.getString(keyPrinterType)),
      presetId: p.getString(keyPreset) ?? d.presetId,
      customWidthMm: p.getDouble(keyCustomWidth) ?? d.customWidthMm,
      customHeightMm: p.getDouble(keyCustomHeight) ?? d.customHeightMm,
      connection: LabelConnection.fromKey(p.getString(keyConnection)),
      gapMm: p.getDouble(keyGap) ?? d.gapMm,
      cutBorder: p.getBool(keyCutBorder) ?? d.cutBorder,
      includePrice: p.getBool(keyIncludePrice) ?? d.includePrice,
      includeCompany: p.getBool(keyIncludeCompany) ?? d.includeCompany,
      includeSizeColor: p.getBool(keyIncludeSizeColor) ?? d.includeSizeColor,
      includeBatchExpiry:
          p.getBool(keyIncludeBatchExpiry) ?? d.includeBatchExpiry,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(BarcodeLabelSettings next) async {
    _settings = next;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(keyPrinterType, next.printerType.name);
    await p.setString(keyPreset, next.presetId);
    await p.setDouble(keyCustomWidth, next.customWidthMm);
    await p.setDouble(keyCustomHeight, next.customHeightMm);
    await p.setString(keyConnection, next.connection.name);
    await p.setDouble(keyGap, next.gapMm);
    await p.setBool(keyCutBorder, next.cutBorder);
    await p.setBool(keyIncludePrice, next.includePrice);
    await p.setBool(keyIncludeCompany, next.includeCompany);
    await p.setBool(keyIncludeSizeColor, next.includeSizeColor);
    await p.setBool(keyIncludeBatchExpiry, next.includeBatchExpiry);
  }
}
