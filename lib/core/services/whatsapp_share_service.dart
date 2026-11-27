import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens a customer's WhatsApp chat with a document and a message already
/// attached, so the user only has to press Send.
///
/// WhatsApp only allows this on Android (the chat is chosen through the `jid`
/// extra of a share intent). No paid API is involved. On every other platform
/// [sendFileToChat] returns false and the caller falls back to the system share
/// sheet / a plain `wa.me` chat.
class WhatsAppShareService {
  WhatsAppShareService._();

  static const MethodChannel _channel = MethodChannel('c_billing/whatsapp');
  static const String _readyChatsKey = 'whatsapp_ready_chats';

  /// True once a chat with this number was opened through the app. WhatsApp can
  /// then jump straight into it with a file attached; before that it may only
  /// show its contact list for numbers that are not saved in the phone.
  static Future<bool> isChatReady(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_readyChatsKey) ?? const <String>[])
          .contains(normalizePhone(phone));
    } catch (_) {
      return false;
    }
  }

  static Future<void> markChatReady(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_readyChatsKey) ?? <String>[];
      final number = normalizePhone(phone);
      if (!list.contains(number)) {
        list.add(number);
        await prefs.setStringList(_readyChatsKey, list);
      }
    } catch (_) {}
  }

  static bool get supportsDirectChat =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Digits only with the country code (10 digit numbers get India's 91).
  static String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 10) digits = '91$digits';
    return digits;
  }

  /// Returns true when WhatsApp was opened on the customer's chat with the file
  /// and message attached. Returns false if that is not possible (not Android,
  /// WhatsApp missing, file not shareable) so the caller can fall back.
  static Future<bool> sendFileToChat({
    required String phone,
    required String filePath,
    required String message,
    String mimeType = 'application/pdf',
  }) async {
    if (!supportsDirectChat) return false;
    final number = normalizePhone(phone);
    if (number.length < 10) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('sendFile', {
        'phone': number,
        'path': filePath,
        'message': message,
        'mime': mimeType,
      });
      return ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('[WhatsAppShare] native error: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
