import 'dart:async';

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
import 'package:c_billing/common_widgets/app_logo_mark.dart';
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
      duration: const Duration(milliseconds: 2800),
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

      debugPrint('[DEBUG] Splash page - checking for stored credentials');

      // Check if user has valid stored credentials
      if (_credentialsManager.isLoggedIn()) {
        debugPrint('[DEBUG] Stored credentials found, attempting auto-login');

        // Check if Firebase user is already authenticated
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint(
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
        debugPrint('[DEBUG] No stored credentials found, going to login');
        // Proceed normally to login after splash duration
        _timer = Timer(widget.duration, _goToLogin);
      }
    } catch (e) {
      debugPrint('[ERROR] Error during initialization: $e');
      _timer = Timer(widget.duration, _goToLogin);
    }
  }

  Future<void> _attemptAutoLogin() async {
    try {
      final credentials = _credentialsManager.getStoredCredentials();

      if (credentials == null) {
        debugPrint('[DEBUG] Stored credentials are invalid');
        _timer = Timer(const Duration(seconds: 1), _goToLogin);
        return;
      }

      final email = credentials['email'] as String;
      final password = credentials['password'] as String;

      debugPrint('[DEBUG] Attempting auto-login with email: ***');

      // Attempt Firebase login with stored credentials (with timeout)
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 8));

      if (userCredential.user != null) {
        debugPrint('[DEBUG] Auto-login successful for: ${userCredential.user!.uid}');
        // Start sync services now that user is authenticated
        initializeSyncServices();
        // Reload settings in background - don't wait
        _reloadSettingsInBackground();
        _goToDashboard();
      } else {
        debugPrint('[ERROR] Auto-login failed: user is null');
        _goToLogin();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[ERROR] Auto-login failed: ${e.code} - ${e.message}');
      // Clear invalid credentials
      await _credentialsManager.clearCredentials();
      _timer = Timer(const Duration(seconds: 1), _goToLogin);
    } on TimeoutException catch (_) {
      debugPrint('[ERROR] Auto-login timed out - going to login');
      _timer = Timer(const Duration(milliseconds: 500), _goToLogin);
    } catch (e) {
      debugPrint('[ERROR] Unexpected error during auto-login: $e');
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
        debugPrint('[DEBUG] Background settings reload error (non-critical): $e');
      }
    });
  }

  void _goToDashboard() {
    if (mounted) {
      debugPrint('[DEBUG] User logged in, checking biometric lock status');
      // Navigate immediately without waiting for splash animation
      _checkBiometricLockAndNavigate();
    }
  }

  Future<void> _checkBiometricLockAndNavigate() async {
    try {
      final biometricService = BiometricService.instance;
      final isLockEnabled = await biometricService.isBiometricLockEnabled();

      debugPrint('[DEBUG] Biometric lock enabled: $isLockEnabled');

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
      debugPrint('[ERROR] Error checking biometric lock: $e');
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
        debugPrint('[DEBUG] Fingerprint authentication successful');
        _navigateToDashboard();
      } else {
        debugPrint('[DEBUG] Fingerprint authentication cancelled/failed');
        // Stay on splash screen - user can tap unlock again
        if (mounted) {
          GlassyToast.show(
            context,
            'Authentication cancelled. Tap "Unlock Now" to try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('[ERROR] Error during fingerprint authentication: $e');
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
      debugPrint('[DEBUG] Checking subscription status...');
      final isSubscriptionValid = await _subscriptionService
          .isSubscriptionValid()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);

      if (!isSubscriptionValid) {
        debugPrint(
          '[DEBUG] Subscription expired/missing, redirecting to subscription screen',
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          );
        }
        return;
      }

      debugPrint('[DEBUG] Subscription valid, navigating to dashboard');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
        );
      }
    } catch (e) {
      debugPrint('[ERROR] Error checking subscription: $e');
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
      debugPrint('[DEBUG] Unlock Now tapped, showing fingerprint dialog');
      _showFingerprintDialog(currentUser.uid);
    } else {
      debugPrint('[ERROR] No current user found');
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final titleColor = isDark ? AppTheme.white : AppTheme.headerDarkEnd;
    final muted = isDark ? AppTheme.paletteFF8E9892 : AppTheme.paletteFF5E6B64;
    final themeColor = AppColors.action(context);
    final appTitle = _localizations.appName == 'C-BILLING'
        ? 'C-Billing'
        : _localizations.appName;
    final tagline = _localizations.tagline == 'THE BACKBONE FOR YOUR\nBUSINESS'
        ? 'THE BACKBONE FOR\nYOUR BUSINESS'
        : _localizations.tagline;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.paletteFF070908
          : AppTheme.darkTextPrimary,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.22),
            radius: isDark ? 0.95 : 1.05,
            colors: isDark
                ? const [
                    AppTheme.paletteFF1A4034,
                    AppTheme.paletteFF0E1C17,
                    AppTheme.paletteFF070908,
                  ]
                : const [
                    AppTheme.paletteFFD7F6E8,
                    AppTheme.paletteFFEEF6F2,
                    AppTheme.darkTextPrimary,
                  ],
            stops: const [0.0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AppLogoMark(
                      isDark: isDark,
                      rings: _ringController,
                      pulse: _pulseScale,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                FadeTransition(
                  opacity: _nameFade,
                  child: SlideTransition(
                    position: _nameSlide,
                    child: Text(
                      appTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Literata',
                        letterSpacing: -0.4,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _lineProgress,
                  builder: (context, _) {
                    return Container(
                      width: 42 * _lineProgress.value,
                      height: 3,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      letterSpacing: 1.6,
                      height: 1.45,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _footerFade,
                  child: _showUnlockButton
                      ? _buildUnlockButton(themeColor)
                      : _buildReadyBar(isDark, muted, themeColor),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _footerFade,
                  child: SlideTransition(
                    position: _footerSlide,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkOutline
                                  : AppTheme.paletteFFD3DDD7,
                            ),
                          ),
                          child: Text(
                            'PREMIUM FINANCIAL SOLUTIONS',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Literata',
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: themeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Newasa',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Literata',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.phone_outlined, size: 14, color: themeColor),
                            const SizedBox(width: 4),
                            Text(
                              '+91 99706 62978',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 13,
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
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadyBar(bool isDark, Color muted, Color themeColor) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _pulseController]),
      builder: (context, _) {
        final fill =
            (0.22 +
                    (_introController.value * 0.28) +
                    (_pulseController.value * 0.06))
                .clamp(0.18, 0.62);
        return Column(
          children: [
            Container(
              width: 168,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.paletteFF2A3330
                    : AppTheme.paletteFFD7E0DB,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill,
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _localizations.loadingData == 'Loading data...'
                  ? 'Getting things ready'
                  : _localizations.loadingData,
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnlockButton(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: themeColor,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            onTap: _showUnlockBiometric,
            borderRadius: BorderRadius.circular(26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, color: AppTheme.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  _localizations.unlockNow,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
