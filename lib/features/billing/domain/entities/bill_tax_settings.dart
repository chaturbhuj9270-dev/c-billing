import 'package:shared_preferences/shared_preferences.dart';

// GST tax mode for billing
enum GstMode {
  // No GST applied
  noGst,

  // GST applied and added on top of subtotal
  excludeGst,

  // GST is included in the item prices (extracted for display)
  includeGst,
}

// Model for persisting GST/tax configuration in Bill Settings
class BillTaxSettings {
  // SharedPreferences keys
  static const String _keyEnableCgst = 'tax_enable_cgst';
  static const String _keyEnableSgst = 'tax_enable_sgst';
  static const String _keyEnableIgst = 'tax_enable_igst';
  static const String _keyEnableOtherTax = 'tax_enable_other_tax';
  static const String _keyEnableExtraCharges = 'bill_enable_extra_charges';
  static const String _keyCgstPercent = 'tax_cgst_percent';
  static const String _keySgstPercent = 'tax_sgst_percent';
  static const String _keyIgstPercent = 'tax_igst_percent';
  static const String _keyOtherTaxName = 'tax_other_tax_name';
  static const String _keyOtherTaxPercent = 'tax_other_tax_percent';
  static const String _keyDefaultIncludeTax = 'tax_default_include';

  final bool enableCgst;
  final bool enableSgst;
  final bool enableIgst;
  final bool enableOtherTax;
  /// Master switch: Extra charges section on Generate Invoice (Bill Settings only).
  final bool enableExtraCharges;
  final double cgstPercent;
  final double sgstPercent;
  final double igstPercent;
  final String otherTaxName;
  final double otherTaxPercent;
  final bool defaultIncludeTax;

  const BillTaxSettings({
    this.enableCgst = false,
    this.enableSgst = false,
    this.enableIgst = false,
    this.enableOtherTax = false,
    this.enableExtraCharges = false,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.igstPercent = 0.0,
    this.otherTaxName = '',
    this.otherTaxPercent = 0.0,
    this.defaultIncludeTax = true,
  });

  // Default (all disabled)
  static const BillTaxSettings defaultSettings = BillTaxSettings();

  // Effective CGST percent (0 if disabled or IGST mode)
  double get effectiveCgstPercent =>
      (!enableIgst && enableCgst && cgstPercent > 0) ? cgstPercent : 0.0;

  // Effective SGST percent (0 if disabled or IGST mode)
  double get effectiveSgstPercent =>
      (!enableIgst && enableSgst && sgstPercent > 0) ? sgstPercent : 0.0;

  // Effective IGST percent (interstate)
  double get effectiveIgstPercent =>
      (enableIgst && igstPercent > 0) ? igstPercent : 0.0;

  // Effective Other Tax percent (0 if disabled)
  double get effectiveOtherTaxPercent =>
      (enableOtherTax && otherTaxPercent > 0) ? otherTaxPercent : 0.0;

  // Total effective tax percentage (sum of all enabled taxes)
  double get totalTaxPercent =>
      effectiveCgstPercent +
      effectiveSgstPercent +
      effectiveIgstPercent +
      effectiveOtherTaxPercent;

  // Whether any tax is effectively enabled (enabled + percent > 0)
  bool get hasAnyTaxEnabled => totalTaxPercent > 0;

  /// GST feature toggled on in Bill Settings, even if % is still 0.
  bool get gstFeatureEnabled =>
      enableCgst || enableSgst || enableIgst || enableOtherTax;

  // The default GST mode based on settings
  GstMode get defaultGstMode {
    if (!gstFeatureEnabled || !hasAnyTaxEnabled) return GstMode.noGst;
    return defaultIncludeTax ? GstMode.includeGst : GstMode.excludeGst;
  }

  // Load from SharedPreferences
  static Future<BillTaxSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return BillTaxSettings(
      enableCgst: prefs.getBool(_keyEnableCgst) ?? false,
      enableSgst: prefs.getBool(_keyEnableSgst) ?? false,
      enableIgst: prefs.getBool(_keyEnableIgst) ?? false,
      enableOtherTax: prefs.getBool(_keyEnableOtherTax) ?? false,
      enableExtraCharges: prefs.getBool(_keyEnableExtraCharges) ?? false,
      cgstPercent: prefs.getDouble(_keyCgstPercent) ?? 0.0,
      sgstPercent: prefs.getDouble(_keySgstPercent) ?? 0.0,
      igstPercent: prefs.getDouble(_keyIgstPercent) ?? 0.0,
      otherTaxName: prefs.getString(_keyOtherTaxName) ?? '',
      otherTaxPercent: prefs.getDouble(_keyOtherTaxPercent) ?? 0.0,
      defaultIncludeTax: prefs.getBool(_keyDefaultIncludeTax) ?? true,
    );
  }

  // Save to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableCgst, enableCgst);
    await prefs.setBool(_keyEnableSgst, enableSgst);
    await prefs.setBool(_keyEnableIgst, enableIgst);
    await prefs.setBool(_keyEnableOtherTax, enableOtherTax);
    await prefs.setBool(_keyEnableExtraCharges, enableExtraCharges);
    await prefs.setDouble(_keyCgstPercent, cgstPercent);
    await prefs.setDouble(_keySgstPercent, sgstPercent);
    await prefs.setDouble(_keyIgstPercent, igstPercent);
    await prefs.setString(_keyOtherTaxName, otherTaxName);
    await prefs.setDouble(_keyOtherTaxPercent, otherTaxPercent);
    await prefs.setBool(_keyDefaultIncludeTax, defaultIncludeTax);
  }

  // Calculate tax breakdown for a given subtotal and GST mode
  TaxBreakdown calculateTax({
    required double subtotal,
    required GstMode gstMode,
  }) {
    if (gstMode == GstMode.noGst || !hasAnyTaxEnabled) {
      return TaxBreakdown.zero(subtotal: subtotal);
    }

    if (gstMode == GstMode.excludeGst) {
      final cgst = subtotal * (effectiveCgstPercent / 100);
      final sgst = subtotal * (effectiveSgstPercent / 100);
      final igst = subtotal * (effectiveIgstPercent / 100);
      final other = subtotal * (effectiveOtherTaxPercent / 100);
      final totalTax = cgst + sgst + igst + other;
      return TaxBreakdown(
        taxableValue: subtotal,
        cgstPercent: effectiveCgstPercent,
        sgstPercent: effectiveSgstPercent,
        igstPercent: effectiveIgstPercent,
        otherTaxPercent: effectiveOtherTaxPercent,
        otherTaxName: otherTaxName,
        cgstAmount: cgst,
        sgstAmount: sgst,
        igstAmount: igst,
        otherTaxAmount: other,
        totalTaxAmount: totalTax,
        subtotal: subtotal,
        isInclusive: false,
      );
    }

    // Include GST → extract from subtotal
    final taxableValue = subtotal / (1 + totalTaxPercent / 100);
    final cgst = taxableValue * (effectiveCgstPercent / 100);
    final sgst = taxableValue * (effectiveSgstPercent / 100);
    final igst = taxableValue * (effectiveIgstPercent / 100);
    final other = taxableValue * (effectiveOtherTaxPercent / 100);
    final totalTax = cgst + sgst + igst + other;
    return TaxBreakdown(
      taxableValue: taxableValue,
      cgstPercent: effectiveCgstPercent,
      sgstPercent: effectiveSgstPercent,
      igstPercent: effectiveIgstPercent,
      otherTaxPercent: effectiveOtherTaxPercent,
      otherTaxName: otherTaxName,
      cgstAmount: cgst,
      sgstAmount: sgst,
      igstAmount: igst,
      otherTaxAmount: other,
      totalTaxAmount: totalTax,
      subtotal: subtotal,
      isInclusive: true,
    );
  }

  /// Build tax from per-product CGST/SGST. When [forceIgst] is true (interstate),
  /// combined CGST+SGST rates are charged as IGST instead.
  static TaxBreakdown fromItemTaxes({
    required List<({double subtotal, double cgstPercent, double sgstPercent})>
        items,
    required double discountAmount,
    required GstMode gstMode,
    bool forceIgst = false,
  }) {
    final subtotal = items.fold<double>(0, (s, i) => s + i.subtotal);
    if (subtotal <= 0 || gstMode == GstMode.noGst) {
      return TaxBreakdown.zero(subtotal: subtotal);
    }

    final discountRatio =
        (discountAmount > 0 && subtotal > 0) ? (discountAmount / subtotal) : 0.0;
    double taxableValue = 0;
    double cgstAmount = 0;
    double sgstAmount = 0;
    double igstAmount = 0;
    final cgstRates = <double>{};
    final sgstRates = <double>{};
    final igstRates = <double>{};

    for (final item in items) {
      if (item.subtotal <= 0) continue;
      final net = item.subtotal * (1 - discountRatio);
      final combined = item.cgstPercent + item.sgstPercent;
      if (combined <= 0) {
        taxableValue += net;
        continue;
      }

      if (forceIgst) {
        igstRates.add(combined);
        if (gstMode == GstMode.includeGst) {
          final base = net / (1 + combined / 100);
          taxableValue += base;
          igstAmount += base * (combined / 100);
        } else {
          taxableValue += net;
          igstAmount += net * (combined / 100);
        }
      } else {
        if (item.cgstPercent > 0) cgstRates.add(item.cgstPercent);
        if (item.sgstPercent > 0) sgstRates.add(item.sgstPercent);
        if (gstMode == GstMode.includeGst) {
          final base = net / (1 + combined / 100);
          taxableValue += base;
          cgstAmount += base * (item.cgstPercent / 100);
          sgstAmount += base * (item.sgstPercent / 100);
        } else {
          taxableValue += net;
          cgstAmount += net * (item.cgstPercent / 100);
          sgstAmount += net * (item.sgstPercent / 100);
        }
      }
    }

    final totalTax = cgstAmount + sgstAmount + igstAmount;
    return TaxBreakdown(
      taxableValue: taxableValue,
      cgstPercent: cgstRates.length == 1 ? cgstRates.first : 0,
      sgstPercent: sgstRates.length == 1 ? sgstRates.first : 0,
      igstPercent: igstRates.length == 1 ? igstRates.first : 0,
      otherTaxPercent: 0,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      otherTaxAmount: 0,
      totalTaxAmount: totalTax,
      subtotal: subtotal,
      isInclusive: gstMode == GstMode.includeGst,
    );
  }

  BillTaxSettings copyWith({
    bool? enableCgst,
    bool? enableSgst,
    bool? enableIgst,
    bool? enableOtherTax,
    bool? enableExtraCharges,
    double? cgstPercent,
    double? sgstPercent,
    double? igstPercent,
    String? otherTaxName,
    double? otherTaxPercent,
    bool? defaultIncludeTax,
  }) {
    return BillTaxSettings(
      enableCgst: enableCgst ?? this.enableCgst,
      enableSgst: enableSgst ?? this.enableSgst,
      enableIgst: enableIgst ?? this.enableIgst,
      enableOtherTax: enableOtherTax ?? this.enableOtherTax,
      enableExtraCharges: enableExtraCharges ?? this.enableExtraCharges,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      igstPercent: igstPercent ?? this.igstPercent,
      otherTaxName: otherTaxName ?? this.otherTaxName,
      otherTaxPercent: otherTaxPercent ?? this.otherTaxPercent,
      defaultIncludeTax: defaultIncludeTax ?? this.defaultIncludeTax,
    );
  }
}

// Computed tax breakdown for a specific bill
class TaxBreakdown {
  final double taxableValue;
  final double cgstPercent;
  final double sgstPercent;
  final double igstPercent;
  final double otherTaxPercent;
  final String otherTaxName;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double otherTaxAmount;
  final double totalTaxAmount;
  final double subtotal;
  final bool isInclusive;

  const TaxBreakdown({
    required this.taxableValue,
    required this.cgstPercent,
    required this.sgstPercent,
    this.igstPercent = 0,
    required this.otherTaxPercent,
    this.otherTaxName = '',
    required this.cgstAmount,
    required this.sgstAmount,
    this.igstAmount = 0,
    required this.otherTaxAmount,
    required this.totalTaxAmount,
    required this.subtotal,
    required this.isInclusive,
  });

  // No-tax breakdown
  factory TaxBreakdown.zero({required double subtotal}) {
    return TaxBreakdown(
      taxableValue: subtotal,
      cgstPercent: 0,
      sgstPercent: 0,
      igstPercent: 0,
      otherTaxPercent: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      otherTaxAmount: 0,
      totalTaxAmount: 0,
      subtotal: subtotal,
      isInclusive: false,
    );
  }

  // Grand total after tax and discount
  double grandTotal({double discount = 0.0}) {
    if (isInclusive) {
      return subtotal - discount;
    }
    return subtotal + totalTaxAmount - discount;
  }

  bool get hasCgst => cgstAmount > 0;
  bool get hasSgst => sgstAmount > 0;
  bool get hasIgst => igstAmount > 0;
  bool get hasOtherTax => otherTaxPercent > 0 && otherTaxAmount > 0;
  bool get hasAnyTax => totalTaxAmount > 0;

  Map<String, dynamic> toJson() {
    return {
      'taxableValue': taxableValue,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'igstPercent': igstPercent,
      'otherTaxPercent': otherTaxPercent,
      'otherTaxName': otherTaxName,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'otherTaxAmount': otherTaxAmount,
      'totalTaxAmount': totalTaxAmount,
      'isInclusive': isInclusive,
    };
  }

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) {
    return TaxBreakdown(
      taxableValue: ((json['taxableValue'] ?? 0) as num).toDouble(),
      cgstPercent: ((json['cgstPercent'] ?? 0) as num).toDouble(),
      sgstPercent: ((json['sgstPercent'] ?? 0) as num).toDouble(),
      igstPercent: ((json['igstPercent'] ?? 0) as num).toDouble(),
      otherTaxPercent: ((json['otherTaxPercent'] ?? 0) as num).toDouble(),
      otherTaxName: (json['otherTaxName'] ?? '') as String,
      cgstAmount: ((json['cgstAmount'] ?? 0) as num).toDouble(),
      sgstAmount: ((json['sgstAmount'] ?? 0) as num).toDouble(),
      igstAmount: ((json['igstAmount'] ?? 0) as num).toDouble(),
      otherTaxAmount: ((json['otherTaxAmount'] ?? 0) as num).toDouble(),
      totalTaxAmount: ((json['totalTaxAmount'] ?? 0) as num).toDouble(),
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      isInclusive: (json['isInclusive'] ?? false) as bool,
    );
  }
}
