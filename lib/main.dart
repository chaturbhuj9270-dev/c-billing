import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/injection.dart' as di;
import 'core/ui/splash_page.dart';
import 'core/services/credentials_manager.dart';
import 'core/services/language_service.dart';
import 'core/services/purchase_settings_service.dart';
import 'core/services/product_settings_service.dart';
import 'core/services/isar_service.dart';
import 'core/services/error_logging_service.dart';
import 'features/customer/data/services/customer_sync_service.dart';
import 'features/product/data/services/product_sync_service.dart';
import 'features/supplier/data/services/supplier_sync_service.dart';
import 'features/company/data/services/company_sync_service.dart';
import 'features/inventory_management/data/services/purchase_sync_service.dart';
import 'features/inventory_management/data/services/purchase_batch_sync_service.dart';
import 'features/billing/data/services/bill_sync_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error logging service early to capture all errors
  ErrorLoggingService.initialize();
  
  // Firebase MUST be initialized before runApp because services
  // like SubscriptionService access FirebaseFirestore.instance at construction time
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  
  // Run app — splash screen renders while remaining services init
  runApp(const MyApp());
}

/// Initialize non-Firebase services. Called from SplashPage so the UI is visible.
Future<void> initializeServices() async {
  try {
    await di.init();
  } catch (e) {
    debugPrint('DI init error: $e');
  }
  
  try {
    await CredentialsManager().init();
  } catch (e) {
    debugPrint('CredentialsManager init error: $e');
  }
  
  try {
    await LanguageService.instance.init();
  } catch (e) {
    debugPrint('LanguageService init error: $e');
  }
  
  try {
    await PurchaseSettingsService.instance.init();
  } catch (e) {
    debugPrint('PurchaseSettingsService init error: $e');
  }
  
  try {
    await ProductSettingsService.instance.init();
  } catch (e) {
    debugPrint('ProductSettingsService init error: $e');
  }
  
  // Initialize Isar database for offline-first support
  try {
    await IsarService.instance.initialize();
  } catch (e) {
    debugPrint('Isar init error: $e');
  }
}

/// Initialize sync services. Call ONLY after user is authenticated.
void initializeSyncServices() {
  CustomerSyncService.instance.initialize();
  ProductSyncService.instance.initialize();
  SupplierSyncService.instance.initialize();
  CompanySyncService.instance.initialize();
  PurchaseSyncService.instance.initialize();
  PurchaseBatchSyncService.instance.initialize();
  BillSyncService.instance.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C-Billing',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Literata'),
      home: const SplashPage(),
    );
  }
}
