import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'package:c_billing/core/access/access_control_service.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

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
  static const _contactPhone = '+91 99706 62978';

  static const _stepLabels = [
    'Checking license',
    'Connecting to cloud sync',
    'Loading your workspace',
    'Preparing dashboard',
  ];

  Timer? _timer;
  Timer? _creepTimer;
  late CredentialsManager _credentialsManager;
  late AppLocalizations _localizations;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _showUnlockButton = false;

  /// Index of the step currently running (0..3). Steps below are done.
  int _activeStep = 0;
  double _creepCeiling = 0.12;

  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _bgRingController;
  late final AnimationController _progressController;

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
      duration: const Duration(milliseconds: 3200),
    );
    _bgRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8400),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
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
    _pulseScale = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _introController.forward();
    _pulseController.repeat(reverse: true);
    _ringController.repeat();
    _bgRingController.repeat();

    _credentialsManager = CredentialsManager();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage('assets/images/app_logo.png'), context);
      }
    });

    Future.microtask(() => _initializeApp());
  }

  void _startCreep(double ceiling) {
    _creepCeiling = ceiling.clamp(0.0, 1.0);
    _creepTimer?.cancel();
    _creepTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted || _showUnlockButton) return;
      final cur = _progressController.value;
      if (cur >= _creepCeiling) return;
      final next = (cur + 0.01).clamp(0.0, _creepCeiling);
      _progressController.value = next;
      setState(() {});
    });
  }

  void _stopCreep() {
    _creepTimer?.cancel();
    _creepTimer = null;
  }

  Future<void> _setLoadState({
    required int step,
    required double progress,
  }) async {
    if (!mounted) return;
    final next = progress.clamp(0.0, 1.0);
    _stopCreep();
    setState(() {
      _activeStep = step.clamp(0, _stepLabels.length - 1);
    });
    await _progressController.animateTo(
      next,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    // Keep the bar alive between milestones.
    final ceiling = (next + 0.14).clamp(0.0, 0.96);
    if (next < 0.96) _startCreep(ceiling);
  }

  Future<void> _initializeApp() async {
    try {
      await _setLoadState(step: 0, progress: 0.08);
      // Let the first fill paint before heavy work.
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _setLoadState(step: 0, progress: 0.18);

      await initializeServices();
      await _setLoadState(step: 1, progress: 0.36);

      _credentialsManager = CredentialsManager();
      await _credentialsManager.init();
      if (mounted) {
        setState(() {
          _localizations = AppLocalizations.of(
            LanguageService.instance.currentLanguage,
          );
        });
      }

      debugPrint('[DEBUG] Splash page - checking for remembered login');
      await _setLoadState(step: 1, progress: 0.45);

      if (await _credentialsManager.isRemembered()) {
        debugPrint('[DEBUG] Remembered login found, attempting auto-login');
        await _setLoadState(step: 2, progress: 0.58);

        final currentUser = await _restoredUser();
        if (currentUser != null) {
          debugPrint(
            '[DEBUG] Firebase user already authenticated: ${currentUser.uid}',
          );
          try {
            await AccessControlService.instance.loadForCurrentUser();
            initializeSyncServices();
          } catch (e) {
            debugPrint('[ERROR] Access/sync start failed: $e');
            if (mounted) {
              GlassyToast.show(
                context,
                'Account access denied. Contact your shop admin.',
                isError: true,
              );
            }
            _goToLogin();
            return;
          }
          await _setLoadState(step: 3, progress: 0.92);
          _reloadSettingsInBackground();
          _goToDashboard();
          return;
        }

        if (kIsWeb) {
          debugPrint('[DEBUG] No web session to restore, going to login');
          await _setLoadState(step: 3, progress: 1);
          _goToLogin();
          return;
        }

        await _attemptAutoLogin();
      } else {
        debugPrint('[DEBUG] Remember me is off, going to login');
        try {
          if (FirebaseAuth.instance.currentUser != null) {
            await FirebaseAuth.instance.signOut();
          }
        } catch (e) {
          debugPrint('[ERROR] Sign out before login failed: $e');
        }
        await _setLoadState(step: 3, progress: 1);
        _timer = Timer(widget.duration, _goToLogin);
      }
    } catch (e) {
      debugPrint('[ERROR] Error during initialization: $e');
      await _setLoadState(step: 3, progress: 1);
      _timer = Timer(widget.duration, _goToLogin);
    }
  }

  Future<User?> _restoredUser() async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return existing;
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return FirebaseAuth.instance.currentUser;
    }
  }

  Future<void> _attemptAutoLogin() async {
    try {
      final credentials = await _credentialsManager.getStoredCredentials();

      if (credentials == null) {
        debugPrint('[DEBUG] Stored credentials are invalid');
        await _setLoadState(step: 3, progress: 1);
        _timer = Timer(const Duration(seconds: 1), _goToLogin);
        return;
      }

      final email = credentials['email'] as String;
      final password = credentials['password'] as String;

      debugPrint('[DEBUG] Attempting auto-login with email: ***');
      await _setLoadState(step: 2, progress: 0.7);

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 8));

      if (userCredential.user != null) {
        debugPrint(
          '[DEBUG] Auto-login successful for: ${userCredential.user!.uid}',
        );
        try {
          await AccessControlService.instance.loadForCurrentUser();
          initializeSyncServices();
        } catch (e) {
          debugPrint('[ERROR] Access/sync start failed: $e');
          if (mounted) {
            GlassyToast.show(
              context,
              'Account access denied. Contact your shop admin.',
              isError: true,
            );
          }
          _goToLogin();
          return;
        }
        await _setLoadState(step: 3, progress: 0.95);
        _reloadSettingsInBackground();
        _goToDashboard();
      } else {
        debugPrint('[ERROR] Auto-login failed: user is null');
        _goToLogin();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[ERROR] Auto-login failed: ${e.code} - ${e.message}');
      await _credentialsManager.clearCredentials();
      await _setLoadState(step: 3, progress: 1);
      _timer = Timer(const Duration(seconds: 1), _goToLogin);
    } on TimeoutException catch (_) {
      debugPrint('[ERROR] Auto-login timed out - going to login');
      await _setLoadState(step: 3, progress: 1);
      _timer = Timer(const Duration(milliseconds: 500), _goToLogin);
    } catch (e) {
      debugPrint('[ERROR] Unexpected error during auto-login: $e');
      await _setLoadState(step: 3, progress: 1);
      _timer = Timer(const Duration(seconds: 1), _goToLogin);
    }
  }

  void _goToLogin() {
    _stopCreep();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPageV2()));
    }
  }

  void _reloadSettingsInBackground() {
    Future.microtask(() async {
      try {
        await BillReportSettingsService.instance.reload();
        await StockReportSettingsService.instance.reload();
      } catch (e) {
        debugPrint(
          '[DEBUG] Background settings reload error (non-critical): $e',
        );
      }
    });
  }

  void _goToDashboard() {
    if (mounted) {
      debugPrint('[DEBUG] User logged in, checking biometric lock status');
      _checkBiometricLockAndNavigate();
    }
  }

  Future<void> _checkBiometricLockAndNavigate() async {
    try {
      final biometricService = BiometricService.instance;
      final isLockEnabled = await biometricService.isBiometricLockEnabled();

      debugPrint('[DEBUG] Biometric lock enabled: $isLockEnabled');

      if (isLockEnabled && mounted) {
        setState(() {
          _showUnlockButton = true;
        });
      } else {
        _navigateToDashboard();
      }
    } catch (e) {
      debugPrint('[ERROR] Error checking biometric lock: $e');
      final canUse = await BiometricService.instance.canUseBiometrics();
      if (!mounted) return;
      if (canUse) {
        setState(() => _showUnlockButton = true);
      } else {
        _navigateToDashboard();
      }
    }
  }

  Future<void> _signInWithPasswordInstead() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[ERROR] Sign out before password login failed: $e');
    }
    _goToLogin();
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
        if (mounted) {
          GlassyToast.show(
            context,
            'Authentication cancelled. Tap "Unlock Now" to try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('[ERROR] Error during fingerprint authentication: $e');
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

    try {
      await AccessControlService.instance.loadForCurrentUser();
    } catch (e) {
      debugPrint('[ERROR] Access control load failed: $e');
      if (mounted) {
        GlassyToast.show(
          context,
          'Account access denied. Contact your shop admin.',
          isError: true,
        );
        _goToLogin();
      }
      return;
    }

    try {
      debugPrint('[DEBUG] Checking subscription status...');
      await _setLoadState(step: 3, progress: 0.98);
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
    _stopCreep();
    _introController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _bgRingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String get _appTitle {
    final name = _localizations.appName;
    return name == 'C-BILLING' ? 'C-Billing' : name;
  }

  String get _tagline {
    final t = _localizations.tagline;
    if (t == 'THE BACKBONE FOR YOUR\nBUSINESS') {
      return 'THE BACKBONE OF YOUR BUSINESS';
    }
    return t.replaceAll('\n', ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (DesktopCanvas.isDesktopPlatform) return _buildDesktopSplash(context);
    return _buildMobileSplash(context);
  }

  // Desktop and web compact splash. Phones keep the centered mobile layout.
  Widget _buildDesktopSplash(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = isDark ? const Color(0xFF3DDC84) : const Color(0xFF1E9A62);
    final titleColor = isDark ? AppTheme.white : const Color(0xFF161A18);
    final muted = isDark ? const Color(0xFF9AA59E) : const Color(0xFF6A756F);
    final ring = isDark
        ? AppTheme.white.withValues(alpha: 0.10)
        : const Color(0xFFD5DED8);
    const loading = 'Loading your workspace...';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF07110D)
          : const Color(0xFFF4F7F5),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.08, -0.12),
            radius: 1.15,
            colors: isDark
                ? const [
                    Color(0xFF173528),
                    Color(0xFF0C1A14),
                    Color(0xFF07110D),
                  ]
                : const [
                    Color(0xFFF7FBF8),
                    Color(0xFFF3F6F4),
                    Color(0xFFE7EEEA),
                  ],
            stops: const [0.0, 0.46, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _bgRingController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CompactSplashRingsPainter(
                    color: ring,
                    progress: _bgRingController.value,
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 24, 36, 28),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _nameSlide,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _DesktopBrandLockup(
                            title: _appTitle,
                            tagline: _tagline.toUpperCase(),
                            titleColor: titleColor,
                            muted: muted,
                            accent: accent,
                            line: _lineProgress,
                            taglineFade: _taglineFade,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _footerFade,
                      child: _showUnlockButton
                          ? Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 420),
                                child: _buildUnlockButton(accent),
                              ),
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: muted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    loading,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Text(
                                  _localizations.version,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // —— Mobile / narrow splash (existing centered layout) ——

  Widget _buildMobileSplash(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final titleColor = isDark ? AppTheme.white : AppTheme.headerDarkEnd;
    final muted = isDark ? AppTheme.paletteFF8E9892 : AppTheme.paletteFF5E6B64;
    final themeColor = AppColors.action(context);
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
                      _appTitle,
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
                      : _buildMobileProgress(isDark, muted, themeColor),
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
                        if (kIsWeb ||
                            defaultTargetPlatform == TargetPlatform.windows)
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          )
                        else
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
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: themeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _contactPhone,
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

  Widget _buildMobileProgress(bool isDark, Color muted, Color themeColor) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final value = _progressController.value.clamp(0.0, 1.0);
        return Column(
          children: [
            SizedBox(
              width: 200,
              child: _SplashProgressBar(
                value: value < 0.08 ? 0.08 : value,
                trackColor: isDark
                    ? AppTheme.paletteFF2A3330
                    : AppTheme.paletteFFD7E0DB,
                fillColor: themeColor,
                height: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _stepLabels[_activeStep.clamp(0, _stepLabels.length - 1)],
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
      child: Column(
        children: [
          SizedBox(
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
                    const Icon(
                      Icons.fingerprint,
                      color: AppTheme.white,
                      size: 22,
                    ),
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
          TextButton(
            onPressed: _signInWithPasswordInstead,
            child: Text(
              _localizations.signIn,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                color: themeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashProgressBar extends StatelessWidget {
  final double value;
  final Color trackColor;
  final Color fillColor;
  final double height;

  const _SplashProgressBar({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = constraints.maxWidth * clamped;
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: trackColor)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: fillWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          fillColor,
                          Color.lerp(fillColor, AppTheme.greenAccent, 0.35)!,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopBrandLockup extends StatelessWidget {
  final String title;
  final String tagline;
  final Color titleColor;
  final Color muted;
  final Color accent;
  final Animation<double> line;
  final Animation<double> taglineFade;

  const _DesktopBrandLockup({
    required this.title,
    required this.tagline,
    required this.titleColor,
    required this.muted,
    required this.accent,
    required this.line,
    required this.taglineFade,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        const SizedBox(width: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: taglineFade,
              child: Text(
                tagline,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                  letterSpacing: 1.7,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: line,
              builder: (context, _) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 220 * line.value,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactSplashRingsPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _CompactSplashRingsPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.46);
    final base = math.min(size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final t = (progress + (i / 3)) % 1.0;
      final fade = math.sin(t * math.pi);
      paint.color = color.withValues(alpha: color.a * fade);
      canvas.drawCircle(center, base * (0.16 + (t * 0.74)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompactSplashRingsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
