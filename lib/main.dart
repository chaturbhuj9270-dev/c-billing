import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/injection.dart' as di;
import 'core/ui/splash_page.dart';
import 'core/services/credentials_manager.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await di.init();
    print('[DEBUG] DI initialization complete');
  } catch (e) {
    print('[ERROR] DI initialization failed: $e');
  }
  
  try {
    // Initialize CredentialsManager early
    await CredentialsManager().init();
    print('[DEBUG] CredentialsManager initialization complete');
  } catch (e) {
    print('[ERROR] CredentialsManager initialization failed: $e');
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[DEBUG] Firebase initialization complete');
  } catch (e) {
    print('[ERROR] Firebase initialization failed: $e');
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
      // Add error handler
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('App Error'),
                  const SizedBox(height: 16),
                  Text(details.exceptionAsString()),
                ],
              ),
            ),
          );
        };
        return child!;
      },
    );
  }
}
