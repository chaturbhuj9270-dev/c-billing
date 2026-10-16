import 'package:shared_preferences/shared_preferences.dart';

/// GST tax mode for billing
enum GstMode {
  /// No GST applied
  noGst,

  /// GST applied and added on top of subtotal
  excludeGst,

  /// GST is included in the item prices (extracted for display)
  includeGst,
}

/// Model for persisting GST/tax configuration in Bill Settings
class BillTaxSettings {
  // SharedPreferences keys
  static const String _keyEnableCgst = 'tax_enable_cgst';
  static const String _keyEnableSgst = 'tax_enable_sgst';
  static const String _keyEnableOtherTax = 'tax_enable_other_tax';
  static const String _keyCgstPercent = 'tax_cgst_percent';
  static const String _keySgstPercent = 'tax_sgst_percent';
  static const String _keyOtherTaxName = 'tax_other_tax_name';
  static const String _keyOtherTaxPercent = 'tax_other_tax_percent';
  static const String _keyDefaultIncludeTax = 'tax_default_include';

  final bool enableCgst;
  final bool enableSgst;
  final bool enableOtherTax;
  final double cgstPercent;
  final double sgstPercent;
  final String otherTaxName;
  final double otherTaxPercent;
  final bool defaultIncludeTax;

  const BillTaxSettings({
    this.enableCgst = false,
    this.enableSgst = false,
    this.enableOtherTax = false,
    this.cgstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.otherTaxName = '',
    this.otherTaxPercent = 0.0,
    this.defaultIncludeTax = true,
  });

  /// Default (all disabled)
  static const BillTaxSettings defaultSettings = BillTaxSettings();

  /// Effective CGST percent (0 if disabled)
  double get effectiveCgstPercent =>
      (enableCgst && cgstPercent > 0) ? cgstPercent : 0.0;

  /// Effective SGST percent (0 if disabled)
  double get effectiveSgstPercent =>
      (enableSgst && sgstPercent > 0) ? sgstPercent : 0.0;

  /// Effective Other Tax percent (0 if disabled)
  double get effectiveOtherTaxPercent =>
      (enableOtherTax && otherTaxPercent > 0) ? otherTaxPercent : 0.0;

  /// Total effective tax percentage (sum of all enabled taxes)
  double get totalTaxPercent =>
      effectiveCgstPercent + effectiveSgstPercent + effectiveOtherTaxPercent;

  /// Whether any tax is effectively enabled (enabled + percent > 0)
  bool get hasAnyTaxEnabled => totalTaxPercent > 0;

  /// The default GST mode based on settings
  GstMode get defaultGstMode {
    if (!hasAnyTaxEnabled) return GstMode.noGst;
    return defaultIncludeTax ? GstMode.includeGst : GstMode.excludeGst;
  }

  /// Load from SharedPreferences
  static Future<BillTaxSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return BillTaxSettings(
      enableCgst: prefs.getBool(_keyEnableCgst) ?? false,
      enableSgst: prefs.getBool(_keyEnableSgst) ?? false,
      enableOtherTax: prefs.getBool(_keyEnableOtherTax) ?? false,
      cgstPercent: prefs.getDouble(_keyCgstPercent) ?? 0.0,
      sgstPercent: prefs.getDouble(_keySgstPercent) ?? 0.0,
      otherTaxName: prefs.getString(_keyOtherTaxName) ?? '',
      otherTaxPercent: prefs.getDouble(_keyOtherTaxPercent) ?? 0.0,
      defaultIncludeTax: prefs.getBool(_keyDefaultIncludeTax) ?? true,
    );
  }

  /// Save to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableCgst, enableCgst);
    await prefs.setBool(_keyEnableSgst, enableSgst);
    await prefs.setBool(_keyEnableOtherTax, enableOtherTax);
    await prefs.setDouble(_keyCgstPercent, cgstPercent);
    await prefs.setDouble(_keySgstPercent, sgstPercent);
    await prefs.setString(_keyOtherTaxName, otherTaxName);
    await prefs.setDouble(_keyOtherTaxPercent, otherTaxPercent);
    await prefs.setBool(_keyDefaultIncludeTax, defaultIncludeTax);
  }

  /// Calculate tax breakdown for a given subtotal and GST mode
  TaxBreakdown calculateTax({
    required double subtotal,
    required GstMode gstMode,
  }) {
    if (gstMode == GstMode.noGst || !hasAnyTaxEnabled) {
      return TaxBreakdown.zero(subtotal: subtotal);
    }

    if (gstMode == GstMode.excludeGst) {
      // GST added on top of subtotal
      final cgst = subtotal * (effectiveCgstPercent / 100);
      final sgst = subtotal * (effectiveSgstPercent / 100);
      final other = subtotal * (effectiveOtherTaxPercent / 100);
      final totalTax = cgst + sgst + other;
      return TaxBreakdown(
        taxableValue: subtotal,
        cgstPercent: effectiveCgstPercent,
        sgstPercent: effectiveSgstPercent,
        otherTaxPercent: effectiveOtherTaxPercent,
        otherTaxName: otherTaxName,
        cgstAmount: cgst,
        sgstAmount: sgst,
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
    final other = taxableValue * (effectiveOtherTaxPercent / 100);
    final totalTax = cgst + sgst + other;
    return TaxBreakdown(
      taxableValue: taxableValue,
      cgstPercent: effectiveCgstPercent,
      sgstPercent: effectiveSgstPercent,
      otherTaxPercent: effectiveOtherTaxPercent,
      otherTaxName: otherTaxName,
      cgstAmount: cgst,
      sgstAmount: sgst,
      otherTaxAmount: other,
      totalTaxAmount: totalTax,
      subtotal: subtotal,
      isInclusive: true,
    );
  }

  BillTaxSettings copyWith({
    bool? enableCgst,
    bool? enableSgst,
    bool? enableOtherTax,
    double? cgstPercent,
    double? sgstPercent,
    String? otherTaxName,
    double? otherTaxPercent,
    bool? defaultIncludeTax,
  }) {
    return BillTaxSettings(
      enableCgst: enableCgst ?? this.enableCgst,
      enableSgst: enableSgst ?? this.enableSgst,
      enableOtherTax: enableOtherTax ?? this.enableOtherTax,
      cgstPercent: cgstPercent ?? this.cgstPercent,
      sgstPercent: sgstPercent ?? this.sgstPercent,
      otherTaxName: otherTaxName ?? this.otherTaxName,
      otherTaxPercent: otherTaxPercent ?? this.otherTaxPercent,
      defaultIncludeTax: defaultIncludeTax ?? this.defaultIncludeTax,
    );
  }
}

/// Computed tax breakdown for a specific bill
class TaxBreakdown {
  final double taxableValue;
  final double cgstPercent;
  final double sgstPercent;
  final double otherTaxPercent;
  final String otherTaxName;
  final double cgstAmount;
  final double sgstAmount;
  final double otherTaxAmount;
  final double totalTaxAmount;
  final double subtotal;
  final bool isInclusive;

  const TaxBreakdown({
    required this.taxableValue,
    required this.cgstPercent,
    required this.sgstPercent,
    required this.otherTaxPercent,
    this.otherTaxName = '',
    required this.cgstAmount,
    required this.sgstAmount,
    required this.otherTaxAmount,
    required this.totalTaxAmount,
    required this.subtotal,
    required this.isInclusive,
  });

  /// No-tax breakdown
  factory TaxBreakdown.zero({required double subtotal}) {
    return TaxBreakdown(
      taxableValue: subtotal,
      cgstPercent: 0,
      sgstPercent: 0,
      otherTaxPercent: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      otherTaxAmount: 0,
      totalTaxAmount: 0,
      subtotal: subtotal,
      isInclusive: false,
    );
  }

  /// Grand total after tax and discount
  double grandTotal({double discount = 0.0}) {
    if (isInclusive) {
      // Inclusive: prices already include tax, just subtract discount
      return subtotal - discount;
    }
    // Exclusive: add tax on top, then subtract discount
    return subtotal + totalTaxAmount - discount;
  }

  bool get hasCgst => cgstPercent > 0 && cgstAmount > 0;
  bool get hasSgst => sgstPercent > 0 && sgstAmount > 0;
  bool get hasOtherTax => otherTaxPercent > 0 && otherTaxAmount > 0;
  bool get hasAnyTax => totalTaxAmount > 0;

  Map<String, dynamic> toJson() {
    return {
      'taxableValue': taxableValue,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'otherTaxPercent': otherTaxPercent,
      'otherTaxName': otherTaxName,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
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
      otherTaxPercent: ((json['otherTaxPercent'] ?? 0) as num).toDouble(),
      otherTaxName: (json['otherTaxName'] ?? '') as String,
      cgstAmount: ((json['cgstAmount'] ?? 0) as num).toDouble(),
      sgstAmount: ((json['sgstAmount'] ?? 0) as num).toDouble(),
      otherTaxAmount: ((json['otherTaxAmount'] ?? 0) as num).toDouble(),
      totalTaxAmount: ((json['totalTaxAmount'] ?? 0) as num).toDouble(),
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      isInclusive: (json['isInclusive'] ?? false) as bool,
    );
  }
}
