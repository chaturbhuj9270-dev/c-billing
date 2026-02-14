import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart' show initializeServices, initializeSyncServices;
import '../../features/authentication/presentation/pages/login.dart';
import '../../features/dashboard/presentation/pages/optimized_dashboard_page.dart';
import '../../core/services/biometric_service.dart';
import '../services/credentials_manager.dart';
import '../services/language_service.dart';
import '../services/subscription_service.dart';
import '../localization/app_localizations.dart';
import 'subscription_screen.dart';

class SplashPage extends StatefulWidget {
  final Duration duration;

  const SplashPage({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;
  late CredentialsManager _credentialsManager;
  late AppLocalizations _localizations;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _showUnlockButton = false;

  @override
  void initState() {
    super.initState();
    _credentialsManager = CredentialsManager();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize all services FIRST (splash screen is visible during this)
      await initializeServices();

      // Re-initialize after services are ready
      _credentialsManager = CredentialsManager();
      await _credentialsManager.init();
      if (mounted) {
        setState(() {
          _localizations = AppLocalizations.of(
            LanguageService.instance.currentLanguage,
          );
        });
      }

      print('[DEBUG] Splash page - checking for stored credentials');

      // Check if user has valid stored credentials
      if (_credentialsManager.isLoggedIn()) {
        print('[DEBUG] Stored credentials found, attempting auto-login');

        // Check if Firebase user is already authenticated
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print(
            '[DEBUG] Firebase user already authenticated: ${currentUser.uid}',
          );
          // Start sync services now that user is authenticated
          initializeSyncServices();
          // Go directly to dashboard
          _goToDashboard();
          return;
        }

        // Try to auto-login with stored credentials (with timeout)
        await _attemptAutoLogin();
      } else {
        print('[DEBUG] No stored credentials found, going to login');
        // Proceed normally to login after splash duration
        _timer = Timer(widget.duration, _goToLogin);
      }
    } catch (e) {
      print('[ERROR] Error during initialization: $e');
      _timer = Timer(widget.duration, _goToLogin);
    }
  }

  Future<void> _attemptAutoLogin() async {
    try {
      final credentials = _credentialsManager.getStoredCredentials();

      if (credentials == null) {
        print('[DEBUG] Stored credentials are invalid');
        _timer = Timer(const Duration(seconds: 1), _goToLogin);
        return;
      }

      final email = credentials['email'] as String;
      final password = credentials['password'] as String;

      print('[DEBUG] Attempting auto-login with email: ***');

      // Attempt Firebase login with stored credentials (with timeout)
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 8));

      if (userCredential.user != null) {
        print('[DEBUG] Auto-login successful for: ${userCredential.user!.uid}');
        // Start sync services now that user is authenticated
        initializeSyncServices();
        _goToDashboard();
      } else {
        print('[ERROR] Auto-login failed: user is null');
        _goToLogin();
      }
    } on FirebaseAuthException catch (e) {
      print('[ERROR] Auto-login failed: ${e.code} - ${e.message}');
      // Clear invalid credentials
      await _credentialsManager.clearCredentials();
      _timer = Timer(const Duration(seconds: 1), _goToLogin);
    } on TimeoutException catch (_) {
      print('[ERROR] Auto-login timed out - going to login');
      _timer = Timer(const Duration(milliseconds: 500), _goToLogin);
    } catch (e) {
      print('[ERROR] Unexpected error during auto-login: $e');
      _timer = Timer(const Duration(seconds: 1), _goToLogin);
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPageV2()));
    }
  }

  void _goToDashboard() {
    if (mounted) {
      print('[DEBUG] User logged in, checking biometric lock status');
      // Wait for splash animation to complete, then check biometric setting
      _timer = Timer(widget.duration, () {
        _checkBiometricLockAndNavigate();
      });
    }
  }

  Future<void> _checkBiometricLockAndNavigate() async {
    try {
      final biometricService = BiometricService.instance;
      final isLockEnabled = await biometricService.isBiometricLockEnabled();
      
      print('[DEBUG] Biometric lock enabled: $isLockEnabled');
      
      if (isLockEnabled && mounted) {
        // Show unlock button instead of auto-prompting
        setState(() {
          _showUnlockButton = true;
        });
      } else {
        // Biometric lock is disabled, go directly to dashboard
        _navigateToDashboard();
      }
    } catch (e) {
      print('[ERROR] Error checking biometric lock: $e');
      // On error, go directly to dashboard
      _navigateToDashboard();
    }
  }

  Future<void> _showFingerprintDialog(String userId) async {
    try {
      final biometricService = BiometricService.instance;

      final isAuthenticated = await biometricService.authenticate(
        reason: 'Verify your identity to continue',
        useErrorDialogs: true,
      );

      if (isAuthenticated && mounted) {
        print('[DEBUG] Fingerprint authentication successful');
        _navigateToDashboard();
      } else {
        print(
          '[DEBUG] Fingerprint authentication cancelled/failed',
        );
        // Stay on splash screen - user can tap unlock again
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication cancelled. Tap "Unlock Now" to try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('[ERROR] Error during fingerprint authentication: $e');
      // Show error but stay on splash screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToDashboard() async {
    if (!mounted) return;

    // Check subscription status before navigating to dashboard
    try {
      print('[DEBUG] Checking subscription status...');
      final isSubscriptionValid = await _subscriptionService
          .isSubscriptionValid()
          .timeout(const Duration(seconds: 5), onTimeout: () => true);

      if (!isSubscriptionValid) {
        print(
          '[DEBUG] Subscription expired, redirecting to subscription screen',
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          );
        }
        return;
      }

      print('[DEBUG] Subscription valid, navigating to dashboard');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
        );
      }
    } catch (e) {
      print('[ERROR] Error checking subscription: $e');
      // If error checking subscription, still allow access
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
        );
      }
    }
  }

  void _showUnlockBiometric() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('[DEBUG] Unlock Now tapped, showing fingerprint dialog');
      _showFingerprintDialog(currentUser.uid);
    } else {
      print('[ERROR] No current user found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFE8E8E4)),
        child: Column(
          children: [
            // Top spacer - smaller
            const SizedBox(height: 40),

            // Center section with logo and text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo image
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4D3E).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App name
                  Text(
                    _localizations.appName,
                    style: const TextStyle(
                      color: Color(0xFF1B4D3E),
                      fontSize: 46,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _localizations.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1B4D3E).withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Literata',
                        letterSpacing: 2,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Unlock Now Button - Only visible when biometric lock is enabled
                  if (_showUnlockButton)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.25),
                                    const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _showUnlockBiometric,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_open,
                                          size: 20,
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _localizations.unlockNow,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Literata',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom branding section
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                children: [
                  // Divider line
                  Container(
                    width: 280,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B4D3E),
                          const Color(0xFF1B4D3E).withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Premium label
                  Text(
                    'PREMIUM FINANCIAL SOLUTIONS',
                    style: TextStyle(
                      color: const Color(0xFF1B4D3E).withOpacity(0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Powered by
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Powered by ',
                          style: TextStyle(
                            color: const Color(0xFF1B4D3E).withOpacity(0.35),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const TextSpan(
                          text: 'CHATURBHUJ SOLUTIONS',
                          style: TextStyle(
                            color: Color(0xFF1B4D3E),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Newasa +91 9970662978',
                    style: TextStyle(
                      color: Color(0xFF1B4D3E),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
