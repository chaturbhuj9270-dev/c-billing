import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences keys and helpers for the Event / Order invoice format.
class EventOrderFormatSettings {
  EventOrderFormatSettings._();

  // `pos` = thermal receipt (same layout as the billing POS receipt),
  // `normal` = A4 tabular invoice (the original event/order invoice).
  static const String keyFormatType = 'event_order_type';

  // Default keeps the invoice users already get today.
  static const String defaultFormat = 'normal';

  static Future<String> getFormatType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(keyFormatType);
      return value == 'pos' ? 'pos' : defaultFormat;
    } catch (_) {
      return defaultFormat;
    }
  }

  static Future<void> setFormatType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFormatType, value == 'pos' ? 'pos' : 'normal');
  }

  static bool isPosFormat(String type) => type == 'pos';
}
