import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart' show initializeServices, initializeSyncServices;
import '../../features/authentication/presentation/pages/login.dart';
import '../../features/dashboard/presentation/pages/optimized_dashboard_page.dart';
import '../services/bill_report_settings_service.dart';
import '../services/stock_report_settings_service.dart';
import '../../core/services/biometric_service.dart';
import '../services/credentials_manager.dart';
import '../services/language_service.dart';
import '../services/subscription_service.dart';
import '../localization/app_localizations.dart';
import 'subscription_screen.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  final Duration duration;

  const SplashPage({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  Timer? _timer;
  late CredentialsManager _credentialsManager;
  late AppLocalizations _localizations;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _showUnlockButton = false;

  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _lineProgress;
  late final Animation<double> _taglineFade;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _nameFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.28, 0.62, curve: Curves.easeOut),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.28, 0.68, curve: Curves.easeOutCubic),
          ),
        );
    _lineProgress = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.48, 0.75, curve: Curves.easeOutCubic),
    );
    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.68, 1, curve: Curves.easeOut),
    );
    _footerSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.68, 1, curve: Curves.easeOutCubic),
          ),
        );
    _pulseScale = Tween<double>(begin: 1, end: 1.045).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _introController.forward();
    _pulseController.repeat(reverse: true);
    _ringController.repeat();

    _credentialsManager = CredentialsManager();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Precache logo for instant display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage('assets/images/app_logo.png'), context);
      }
    });

    // Defer initialization until after first frame is rendered
    // This ensures splash screen shows immediately
    Future.microtask(() => _initializeApp());
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
          // Reload settings in background - don't wait
          _reloadSettingsInBackground();
          // Go directly to dashboard immediately
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
        // Reload settings in background - don't wait
        _reloadSettingsInBackground();
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

  /// Reload settings in background without blocking navigation
  void _reloadSettingsInBackground() {
    // Fire and forget - don't await these
    Future.microtask(() async {
      try {
        await BillReportSettingsService.instance.reload();
        await StockReportSettingsService.instance.reload();
      } catch (e) {
        print('[DEBUG] Background settings reload error (non-critical): $e');
      }
    });
  }

  void _goToDashboard() {
    if (mounted) {
      print('[DEBUG] User logged in, checking biometric lock status');
      // Navigate immediately without waiting for splash animation
      _checkBiometricLockAndNavigate();
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
        print('[DEBUG] Fingerprint authentication cancelled/failed');
        // Stay on splash screen - user can tap unlock again
        if (mounted) {
          GlassyToast.show(
            context,
            'Authentication cancelled. Tap "Unlock Now" to try again.',
          );
        }
      }
    } catch (e) {
      print('[ERROR] Error during fingerprint authentication: $e');
      // Show error but stay on splash screen
      if (mounted) {
        GlassyToast.show(
          context,
          'Authentication error: ${e.toString()}',
          isError: true,
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
          .timeout(const Duration(seconds: 8), onTimeout: () => false);

      if (!isSubscriptionValid) {
        print(
          '[DEBUG] Subscription expired/missing, redirecting to subscription screen',
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
      // Fail closed — block access until subscription can be confirmed
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
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
      GlassyToast.show(context, 'Please log in first', isError: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Widget _pulseRing(double phase) {
    final t = (_ringController.value + phase) % 1.0;
    final size = 120 + (t * 78);
    final opacity = (1 - t) * 0.32;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1B4D3E).withValues(alpha: opacity),
          width: 1.6,
        ),
      ),
    );
  }

  Widget _loadingDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final wave = ((_pulseController.value + index * 0.18) % 1.0);
            final lift = wave < 0.5 ? wave * 2 : (1 - wave) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -5 * lift),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1B4D3E,
                    ).withValues(alpha: 0.35 + (0.5 * lift)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.isDark(context)
                ? const [
                    AppTheme.darkScaffold,
                    AppTheme.darkSurface,
                    AppTheme.darkCard,
                  ]
                : [
                    AppColors.chipFill(context),
                    const Color(0xFFE8E8E4),
                    const Color(0xFFF1F8E9),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer
              SizedBox(height: screenHeight * 0.08),

              // Center section with logo and text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with entrance scale and a soft pulse ring
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _ringController,
                            builder: (context, _) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [_pulseRing(0), _pulseRing(0.5)],
                              );
                            },
                          ),
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: ScaleTransition(
                                scale: _pulseScale,
                                child: Hero(
                                  tag: 'app_logo',
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF1B4D3E,
                                          ).withValues(alpha: 0.25),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: AppColors.card(context),
                                          blurRadius: 15,
                                          offset: const Offset(-5, -5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.asset(
                                        'assets/images/app_logo.png',
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        cacheWidth: 360,
                                        cacheHeight: 360,
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
                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _nameFade,
                      child: SlideTransition(
                        position: _nameSlide,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: AppColors.headerGradient(context),
                          ).createShader(bounds),
                          child: Text(
                            _localizations.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              letterSpacing: 2.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    AnimatedBuilder(
                      animation: _lineProgress,
                      builder: (context, _) {
                        return Container(
                          width: 60 * _lineProgress.value,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.headerGradient(context),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    FadeTransition(
                      opacity: _taglineFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _localizations.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accentSoft(context, 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Literata',
                            letterSpacing: 1.2,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!_showUnlockButton)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FadeTransition(
                    opacity: _footerFade,
                    child: _loadingDots(),
                  ),
                ),

              // Unlock Now Button - Only visible when biometric lock is enabled
              if (_showUnlockButton)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.white.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1B4D3E,
                                ).withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showUnlockBiometric,
                              borderRadius: BorderRadius.circular(28),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          size: 24,
                                          color: AppColors.accent(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF1B4D3E),
                                            Color(0xFF2E7D5B),
                                          ],
                                        ).createShader(bounds),
                                    child: Text(
                                      _localizations.unlockNow,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Literata',
                                        letterSpacing: 0.5,
                                      ),
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

              // Spacer to push footer up or down based on button visibility
              SizedBox(height: _showUnlockButton ? 12 : 32),

              FadeTransition(
                opacity: _footerFade,
                child: SlideTransition(
                  position: _footerSlide,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: _showUnlockButton ? 40 : 50,
                    ),
                    child: Column(
                      children: [
                        // Elegant divider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1B4D3E,
                                  ).withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF1B4D3E,
                                    ).withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Premium label with better styling
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft(context, 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PREMIUM FINANCIAL SOLUTIONS',
                            style: TextStyle(
                              color: const Color(
                                0xFF1B4D3E,
                              ).withValues(alpha: 0.65),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Contact with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: AppColors.accentSoft(context, 0.5),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Newasa',
                              style: TextStyle(
                                color: AppColors.accent(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Literata',
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.phone_outlined,
                              size: 11,
                              color: AppColors.accentSoft(context, 0.5),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '+91 9970662978',
                              style: TextStyle(
                                color: AppColors.accent(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
