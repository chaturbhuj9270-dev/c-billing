import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/injection.dart' as di;
import 'core/ui/splash_page.dart';
import 'core/services/credentials_manager.dart';
import 'core/services/language_service.dart';
import 'core/services/purchase_settings_service.dart';
import 'core/services/product_settings_service.dart';
import 'core/services/event_order_settings_service.dart';
import 'core/services/purchase_report_settings_service.dart';
import 'core/services/bill_report_settings_service.dart';
import 'core/services/stock_report_settings_service.dart';
import 'core/services/isar_service.dart';
import 'core/services/error_logging_service.dart';
import 'features/customer/data/services/customer_sync_service.dart';
import 'features/customer/data/services/customer_transaction_sync_service.dart';
import 'features/product/data/services/product_sync_service.dart';
import 'features/supplier/data/services/supplier_sync_service.dart';
import 'features/company/data/services/company_sync_service.dart';
import 'features/inventory_management/data/services/purchase_sync_service.dart';
import 'features/inventory_management/data/services/purchase_batch_sync_service.dart';
import 'features/billing/data/services/bill_sync_service.dart';
import 'features/event_order/data/services/event_order_sync_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error logging service early to capture all errors
  ErrorLoggingService.initialize();

  // Firebase MUST be initialized before runApp because services
  // like SubscriptionService access FirebaseFirestore.instance at construction time.
  // Timeout avoids an indefinite blank screen when Play Services is slow/broken
  // (common on some Android emulators, especially 16KB page-size images).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Run app — splash screen renders while remaining services init
  runApp(const MyApp());
}

/// Initialize non-Firebase services. Called from SplashPage so the UI is visible.
Future<void> initializeServices() async {
  // Run all independent initializations in parallel for faster startup
  await Future.wait([
    _safeInit(() => di.init(), 'DI'),
    _safeInit(() => CredentialsManager().init(), 'CredentialsManager'),
    _safeInit(() => LanguageService.instance.init(), 'LanguageService'),
    _safeInit(() => IsarService.instance.initialize(), 'Isar'),
  ]);

  // These can run in background after basic services are ready
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
  ]);
}

/// Safe initialization wrapper
Future<void> _safeInit(Future<void> Function() init, String name) async {
  try {
    await init();
  } catch (e) {
    debugPrint('$name init error: $e');
  }
}

/// Initialize sync services. Call ONLY after user is authenticated.
void initializeSyncServices() {
  CustomerSyncService.instance.initialize();
  CustomerTransactionSyncService.instance.initialize();
  ProductSyncService.instance.initialize();
  SupplierSyncService.instance.initialize();
  CompanySyncService.instance.initialize();
  PurchaseSyncService.instance.initialize();
  PurchaseBatchSyncService.instance.initialize();
  BillSyncService.instance.initialize();
  EventOrderSyncService.instance.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C-Billing',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Literata'),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
