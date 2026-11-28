import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin Firebase Crashlytics wrapper. Safe on unsupported platforms (web /
/// Windows / Linux) — all methods no-op so callers never break.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  bool _ready = false;

  /// Android, iOS, and macOS are supported by the Flutter Crashlytics plugin.
  static bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  bool get isReady => _ready;

  /// Call after [Firebase.initializeApp]. Enables collection and is idempotent.
  Future<void> initialize() async {
    if (!isSupported || _ready) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _ready = true;
      debugPrint('[Crashlytics] Initialized');
    } catch (e) {
      debugPrint('[Crashlytics] Init skipped: $e');
      _ready = false;
    }
  }

  Future<void> setUserId(String? userId) async {
    if (!_ready || !isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (e) {
      debugPrint('[Crashlytics] setUserId failed: $e');
    }
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (!_ready || !isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('[Crashlytics] setCustomKey failed: $e');
    }
  }

  Future<void> log(String message) async {
    if (!_ready || !isSupported) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = true,
  }) async {
    if (!_ready || !isSupported) return;
    try {
      if (fatal) {
        await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        await FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    } catch (e) {
      debugPrint('[Crashlytics] recordFlutterError failed: $e');
    }
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_ready || !isSupported) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        fatal: fatal,
        reason: reason,
      );
    } catch (e) {
      debugPrint('[Crashlytics] recordError failed: $e');
    }
  }
}
