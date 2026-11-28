import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/config/app_store_config.dart';
import 'core/di/injection.dart' as di;
import 'core/ui/splash_page.dart';
import 'core/services/credentials_manager.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/purchase_settings_service.dart';
import 'core/services/product_settings_service.dart';
import 'core/services/event_order_settings_service.dart';
import 'core/services/purchase_report_settings_service.dart';
import 'core/services/bill_report_settings_service.dart';
import 'core/services/stock_report_settings_service.dart';
import 'core/services/local_database.dart';
import 'core/services/error_logging_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_scroll_behavior.dart';
import 'core/services/sync_bootstrap.dart';
import 'core/services/live_sync_service.dart';
import 'core/services/sync_query_helper.dart';
import 'firebase_options.dart';

Future<void>? _firebaseReady;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local error buffer first; Crashlytics hooks are layered after Firebase init.
  ErrorLoggingService.initialize();

  // Start Firebase without blocking the first frame — splash paints immediately.
  unawaited(ensureFirebaseReady());

  // Theme preference before first frame so the correct mode is used immediately.
  await _safeInit(() => ThemeService.instance.init(), 'ThemeService');

  // Run app - splash screen renders while Firebase + remaining services init
  runApp(const MyApp());
}

/// Completes once Firebase (and desktop Firestore settings) are ready.
/// Safe to call multiple times; work runs once.
Future<void> ensureFirebaseReady() {
  return _firebaseReady ??= _initFirebase();
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    // Crashlytics after Firebase core — no-ops on web/desktop unsupported targets.
    await CrashlyticsService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Firestore's on-disk cache aborts the desktop process if that database is locked or unreadable. This app keeps its own offline database, so Windows and macOS use memory only. Apply this before any other Firestore call.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows)) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    } catch (e) {
      debugPrint('Firestore settings error: $e');
    }
  }
}

// Initialize services. Called from SplashPage so the UI is already visible.
Future<void> initializeServices() async {
  // Firebase must be ready before Auth / Firestore / DI paths that touch it.
  await ensureFirebaseReady();

  // Run all independent initializations in parallel for faster startup
  await Future.wait([
    _safeInit(() => di.init(), 'DI'),
    _safeInit(() => CredentialsManager().init(), 'CredentialsManager'),
    _safeInit(() => LanguageService.instance.init(), 'LanguageService'),
    _safeInit(() => LocalDatabase.instance.initialize(), 'LocalDatabase'),
  ]);

  // These can run in background after basic services are ready
  unawaited(
    Future.wait([
      _safeInit(
        () => PurchaseSettingsService.instance.init(),
        'PurchaseSettingsService',
      ),
      _safeInit(
        () => ProductSettingsService.instance.init(),
        'ProductSettingsService',
      ),
      _safeInit(
        () => EventOrderSettingsService.instance.init(),
        'EventOrderSettingsService',
      ),
      _safeInit(
        () => PurchaseReportSettingsService.instance.init(),
        'PurchaseReportSettingsService',
      ),
      _safeInit(
        () => BillReportSettingsService.instance.init(),
        'BillReportSettingsService',
      ),
      _safeInit(
        () => StockReportSettingsService.instance.init(),
        'StockReportSettingsService',
      ),
    ]),
  );
}

// Safe initialization wrapper
Future<void> _safeInit(Future<void> Function() init, String name) async {
  try {
    await init();
  } catch (e) {
    debugPrint('$name init error: $e');
  }
}

// Initialize sync services. Call ONLY after user is authenticated
// and AccessControlService.loadForCurrentUser() has completed.
void initializeSyncServices() {
  // Must come first: marks the start of this user's session so incremental
  // pull cursors from a previous account/session are never reused.
  SyncQueryHelper.beginSession(FirebaseAuth.instance.currentUser?.uid);

  SyncBootstrap.initializeServices();

  // Real-time push/pull between devices and the web (free: Firestore
  // listeners + local DB change events drive the services above).
  LiveSyncService.instance.start();
}

// Full server → local pull right after login / session restore.
Future<void> syncAfterLogin() => SyncBootstrap.startAfterLogin();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppStoreConfig.appName,
          theme: AppTheme.lightFor(ThemeService.instance.accentColors),
          darkTheme: AppTheme.dark,
          themeMode: ThemeService.instance.themeMode,
          scrollBehavior: const AppScrollBehavior(),
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: const AppScrollBehavior(),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
