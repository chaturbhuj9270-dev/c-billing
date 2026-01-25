import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/injection.dart' as di;
import 'core/ui/splash_page.dart';
import 'core/services/credentials_manager.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  
  // Initialize CredentialsManager early
  await CredentialsManager().init();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Continue anyway for development; Firebase features will fail at runtime
  }
  
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
