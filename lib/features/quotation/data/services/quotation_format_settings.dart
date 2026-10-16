import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys and helpers for quotation print/PDF format.
class QuotationFormatSettings {
  QuotationFormatSettings._();

  /// `pos` = thermal receipt (standard), `normal` = tabular A4-style PDF.
  static const String keyQuotationType = 'quotation_type';

  static Future<String> getFormatType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyQuotationType) ?? 'pos';
  }

  static Future<void> setFormatType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyQuotationType, value);
  }

  static bool isNormalFormat(String type) => type == 'normal';
}
