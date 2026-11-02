/// Helpers for fractional inventory (kg / ltr / ml) without float drift bugs.
class Qty {
  Qty._();

  static const double epsilon = 1e-9;

  static bool isZero(double value) => value.abs() <= epsilon;

  static bool isPositive(double value) => value > epsilon;

  static bool nearlyEqual(double a, double b) => (a - b).abs() <= epsilon;

  /// Treat near-zero remaining as fully consumed.
  static bool isConsumed(double remaining) => remaining <= epsilon;

  static double clampNonNegative(double value) =>
      value < 0 && value.abs() <= epsilon ? 0.0 : (value < 0 ? 0.0 : value);

  /// Parse user/OCR qty; accepts `1`, `1.5`, `1,5`, `7.250`.
  static double? tryParse(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static double parseOrZero(String? raw) => tryParse(raw) ?? 0.0;

  /// Compact display for typed qty (keeps up to 3 decimal places).
  static String formatDisplay(num value) {
    final v = value.toDouble();
    if (v == v.roundToDouble()) return v.toInt().toString();
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}
