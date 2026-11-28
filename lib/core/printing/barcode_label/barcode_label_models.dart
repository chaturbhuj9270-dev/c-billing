// Pure models for barcode label printing (no Flutter imports besides the
// BarcodeFormat enum). Feature: barcode-labels.
import '../../services/barcode_service.dart' show BarcodeFormat;

/// Which kind of printer the labels are printed on (set from Barcode Settings,
/// same idea as the bill's POS / Normal choice).
enum BarcodePrinterType {
  /// Office / inkjet / laser printer: labels laid out in a grid on A4 sheets.
  normal,

  /// Barcode (label roll) printer: one label per page, exact label size.
  label,

  /// Bluetooth POS thermal receipt printer (ESC/POS).
  pos;

  static BarcodePrinterType fromKey(String? key) =>
      BarcodePrinterType.values.firstWhere(
        (t) => t.name == key,
        orElse: () => BarcodePrinterType.normal,
      );
}

/// How a barcode (label roll) printer receives the job.
enum LabelConnection {
  /// Installed printer driver / system print dialog (USB, Wi-Fi, desktop, web).
  driver,

  /// Bluetooth label printers that understand TSPL.
  bluetooth;

  static LabelConnection fromKey(String? key) => LabelConnection.values
      .firstWhere((t) => t.name == key, orElse: () => LabelConnection.driver);
}

/// A ready-made label size for a typical use.
class LabelPreset {
  final String id;
  final double widthMm;
  final double heightMm;
  const LabelPreset(this.id, this.widthMm, this.heightMm);
}

class LabelPresets {
  LabelPresets._();

  /// Tablet strips, small packs.
  static const strip = LabelPreset('strip', 38, 15);

  /// Small products, jewellery, cosmetics.
  static const small = LabelPreset('small', 50, 25);

  /// General products.
  static const standard = LabelPreset('standard', 60, 40);

  /// Clothes / garment hang tags (portrait).
  static const cloth = LabelPreset('cloth', 40, 60);

  /// Cartons and big boxes.
  static const large = LabelPreset('large', 100, 50);

  static const customId = 'custom';

  static const all = <LabelPreset>[strip, small, standard, cloth, large];

  static LabelPreset? byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// User choices for barcode label printing. Persisted by
/// `BarcodeLabelSettingsService`.
class BarcodeLabelSettings {
  static const minWidthMm = 20.0;
  static const maxWidthMm = 150.0;
  static const minHeightMm = 10.0;
  static const maxHeightMm = 150.0;

  final BarcodePrinterType printerType;
  final String presetId; // a LabelPresets id or 'custom'
  final double customWidthMm;
  final double customHeightMm;
  final LabelConnection connection;

  /// Gap between labels on a label roll (TSPL), mm.
  final double gapMm;

  /// Draw a thin cut-guide border around each label on normal (A4) sheets.
  final bool cutBorder;

  final bool includePrice;
  final bool includeCompany;
  final bool includeSizeColor;
  final bool includeBatchExpiry;

  const BarcodeLabelSettings({
    this.printerType = BarcodePrinterType.normal,
    this.presetId = 'small',
    this.customWidthMm = 50,
    this.customHeightMm = 30,
    this.connection = LabelConnection.driver,
    this.gapMm = 2,
    this.cutBorder = true,
    this.includePrice = true,
    this.includeCompany = true,
    this.includeSizeColor = true,
    this.includeBatchExpiry = true,
  });

  bool get isCustom => LabelPresets.byId(presetId) == null;

  double get widthMm => isCustom
      ? customWidthMm.clamp(minWidthMm, maxWidthMm).toDouble()
      : LabelPresets.byId(presetId)!.widthMm;

  double get heightMm => isCustom
      ? customHeightMm.clamp(minHeightMm, maxHeightMm).toDouble()
      : LabelPresets.byId(presetId)!.heightMm;

  BarcodeLabelSettings copyWith({
    BarcodePrinterType? printerType,
    String? presetId,
    double? customWidthMm,
    double? customHeightMm,
    LabelConnection? connection,
    double? gapMm,
    bool? cutBorder,
    bool? includePrice,
    bool? includeCompany,
    bool? includeSizeColor,
    bool? includeBatchExpiry,
  }) => BarcodeLabelSettings(
    printerType: printerType ?? this.printerType,
    presetId: presetId ?? this.presetId,
    customWidthMm: customWidthMm ?? this.customWidthMm,
    customHeightMm: customHeightMm ?? this.customHeightMm,
    connection: connection ?? this.connection,
    gapMm: gapMm ?? this.gapMm,
    cutBorder: cutBorder ?? this.cutBorder,
    includePrice: includePrice ?? this.includePrice,
    includeCompany: includeCompany ?? this.includeCompany,
    includeSizeColor: includeSizeColor ?? this.includeSizeColor,
    includeBatchExpiry: includeBatchExpiry ?? this.includeBatchExpiry,
  );
}

/// Whole numbers print without decimals, others with two (never silently
/// rounds 99.50 up to 100).
String formatLabelAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// What is printed on one label.
class LabelContent {
  final String name;
  final String code;
  final BarcodeFormat format;
  final String? company;

  /// e.g. "Size M | Color Red"
  final String? attrs;

  /// e.g. "B#12 | Exp 06/27"
  final String? meta;

  /// e.g. "Rs.99 (MRP 120)"
  final String? priceText;

  const LabelContent({
    required this.name,
    required this.code,
    required this.format,
    this.company,
    this.attrs,
    this.meta,
    this.priceText,
  });

  factory LabelContent.build({
    required String name,
    required String code,
    required BarcodeFormat format,
    required BarcodeLabelSettings settings,
    String? company,
    String? size,
    String? color,
    double? price,
    double? mrp,
    String? batchLabel,
    DateTime? expiry,
  }) {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    String? priceText;
    if (settings.includePrice && price != null && price > 0) {
      priceText = 'Rs.${formatLabelAmount(price)}';
      if (mrp != null && mrp > price) {
        priceText = '$priceText (MRP ${formatLabelAmount(mrp)})';
      }
    }

    String? attrs;
    if (settings.includeSizeColor) {
      final parts = <String>[
        if (clean(size) != null) 'Size ${clean(size)}',
        if (clean(color) != null) 'Color ${clean(color)}',
      ];
      if (parts.isNotEmpty) attrs = parts.join(' | ');
    }

    String? meta;
    if (settings.includeBatchExpiry) {
      final parts = <String>[
        if (clean(batchLabel) != null) clean(batchLabel)!,
        if (expiry != null)
          'Exp ${expiry.month.toString().padLeft(2, '0')}/${(expiry.year % 100).toString().padLeft(2, '0')}',
      ];
      if (parts.isNotEmpty) meta = parts.join(' | ');
    }

    return LabelContent(
      name: name.trim(),
      code: code,
      format: format,
      company: settings.includeCompany ? clean(company) : null,
      attrs: attrs,
      meta: meta,
      priceText: priceText,
    );
  }
}
