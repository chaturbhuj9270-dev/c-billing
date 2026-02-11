import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/injection.dart' as di;
import 'core/ui/splash_page.dart';
import 'core/services/credentials_manager.dart';
import 'core/services/language_service.dart';
import 'core/services/purchase_settings_service.dart';
import 'core/services/isar_service.dart';
import 'features/customer/data/services/customer_sync_service.dart';
import 'features/product/data/services/product_sync_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  
  // Initialize CredentialsManager early
  await CredentialsManager().init();
  
  // Initialize LanguageService
  await LanguageService.instance.init();
  
  // Initialize PurchaseSettingsService
  await PurchaseSettingsService.instance.init();
  
  // Initialize Firebase FIRST (before services that depend on it)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Continue anyway for development; Firebase features will fail at runtime
    debugPrint('Firebase init error: $e');
  }
  
  // Initialize Isar database for offline-first support
  await IsarService.instance.initialize();
  
  // Initialize Customer Sync Service (after Firebase is ready)
  CustomerSyncService.instance.initialize();
  
  // Initialize Product Sync Service (after Firebase is ready)
  ProductSyncService.instance.initialize();
  
  runApp(const MyApp());
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
