import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/authentication/presentation/pages/login.dart';
import '../../features/authentication/presentation/widgets/biometric_auth_overlay.dart';
import '../../features/authentication/presentation/cubit/biometric_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../core/services/biometric_service.dart';
import '../services/credentials_manager.dart';

class SplashPage extends StatefulWidget {
  final Duration duration;

  const SplashPage({super.key, this.duration = const Duration(seconds: 3)});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;
  late CredentialsManager _credentialsManager;

  @override
  void initState() {
    super.initState();
    _credentialsManager = CredentialsManager();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize credentials manager
      await _credentialsManager.init();
      print('[DEBUG] Splash page - checking for stored credentials');

      // Check if user has valid stored credentials
      if (_credentialsManager.isLoggedIn()) {
        print('[DEBUG] Stored credentials found, attempting auto-login');

        // Check if Firebase user is already authenticated
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('[DEBUG] Firebase user already authenticated: ${currentUser.uid}');
          // Go directly to dashboard
          _goToDashboard();
          return;
        }

        // Try to auto-login with stored credentials
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

      // Attempt Firebase login with stored credentials
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        print('[DEBUG] Auto-login successful for: ${userCredential.user!.uid}');
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
    } catch (e) {
      print('[ERROR] Unexpected error during auto-login: $e');
      _timer = Timer(const Duration(seconds: 1), _goToLogin);
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPageV2()),
      );
    }
  }

  void _goToDashboard() {
    if (mounted) {
      // Don't auto-show biometric - user will tap "Unlock Now" button
      // Just stay on splash screen
      print('[DEBUG] User logged in, showing splash with Unlock Now button');
    }
  }

  Future<void> _checkBiometricAndProceed(String userId) async {
    try {
      final biometricService = BiometricService.instance;
      
      // Check if device supports biometrics
      final canUseBiometrics = await biometricService.canUseBiometrics();
      
      if (canUseBiometrics && mounted) {
        print('[DEBUG] Device supports biometric, showing overlay');
        // Show biometric overlay regardless of previous preference
        // User can skip by cancelling
        _showBiometricOverlay(userId);
      } else {
        print('[DEBUG] Device does not support biometric, going directly to dashboard');
        _navigateToDashboard();
      }
    } catch (e) {
      print('[ERROR] Error checking biometric: $e');
      _navigateToDashboard();
    }
  }

  void _showBiometricOverlay(String userId) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext bottomSheetContext) {
        return BlocProvider<BiometricCubit>(
          create: (context) => BiometricCubit(
            biometricService: BiometricService.instance,
            userId: userId,
          )..checkBiometricAvailability(),
          child: BiometricAuthOverlay(
            userId: userId,
            onSuccess: () {
              print('[DEBUG] Biometric authentication successful');
              // First pop the bottom sheet, then navigate
              Navigator.pop(context);
              _navigateToDashboard();
            },
            onCancel: () {
              print('[DEBUG] Biometric skipped by user');
              // First pop the bottom sheet, then navigate
              Navigator.pop(context);
              _navigateToDashboard();
            },
          ),
        );
      },
    );
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  void _showUnlockBiometric() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('[DEBUG] Unlock Now tapped, showing biometric overlay');
      _showBiometricOverlay(currentUser.uid);
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
        decoration: const BoxDecoration(
          color: Color(0xFFE8E8E4),
        ),
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
                  const Text(
                    'C-BILLING',
                    style: TextStyle(
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
                      'THE BACKBONE FOR OUR\nBUSINESS',
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
                  
                  // Unlock Now Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showUnlockBiometric,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Unlock Now',
                              style: TextStyle(
                                color: Colors.white,
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
