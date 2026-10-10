import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/product_settings_service.dart';
import '../../../../core/services/purchase_report_settings_service.dart';
import '../../../../core/services/bill_report_settings_service.dart';
import '../../../../core/services/stock_report_settings_service.dart';
import '../../../../main.dart' show initializeSyncServices;
import '../../../dashboard/presentation/pages/optimized_dashboard_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/ui/subscription_screen.dart';
import 'signup.dart';
import 'change_password_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/core/theme/app_theme.dart';

class LoginPageV2 extends StatefulWidget {
  const LoginPageV2({super.key});

  @override
  State<LoginPageV2> createState() => _LoginPageV2State();
}

class _LoginPageV2State extends State<LoginPageV2>
    with TickerProviderStateMixin {
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AppLocalizations _localizations;
  late final AnimationController _animController;
  late final AnimationController _staggerController;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;
  late final List<Animation<Offset>> _fieldAnimations;
  late final List<Animation<double>> _fieldFadeAnimations;

  @override
  void dispose() {
    _animController.dispose();
    _staggerController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    // Staggered field animations
    _fieldAnimations = List.generate(4, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _fieldFadeAnimations = List.generate(4, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    // start after a short delay
    Future.delayed(
      const Duration(milliseconds: 200),
      () => _animController.forward(),
    );
    Future.delayed(
      const Duration(milliseconds: 600),
      () => _staggerController.forward(),
    );
  }

  void _submit() {
    final emailOrPhone = _emailOrPhoneController.text.trim();
    final password = _passwordController.text;
    if (emailOrPhone.isEmpty || password.isEmpty) {
      GlassyToast.show(context, _localizations.enterEmailPhone);
      return;
    }

    setState(() => _loading = true);
    print('[DEBUG] Attempting login with: $emailOrPhone');

    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: emailOrPhone, password: password)
        .then((cred) {
          print('[DEBUG] Login successful for user: ${cred.user?.uid}');

          // Start sync services now that user is authenticated
          initializeSyncServices();

          // Reload product settings to fetch custom columns for this user
          ProductSettingsService.instance.reload();
          PurchaseReportSettingsService.instance.reload();
          BillReportSettingsService.instance.reload();
          StockReportSettingsService.instance.reload();

          // Initialize session with 2-hour timeout
          final sessionManager = SessionManager();
          sessionManager.initializeSession(cred.user!, () {
            print('[CRITICAL] Session expired - clearing data and logging out');
            // Use LogoutService to ensure all local data is cleared on session expiry
            if (mounted) {
              GlassyToast.show(context, _localizations.sessionExpired);
              LogoutService.instance.onSessionExpired(context);
            }
          });

          // Save credentials for persistent login
          final credentialsManager = CredentialsManager();
          credentialsManager
              .saveCredentials(
                email: emailOrPhone,
                password: password,
                userId: cred.user!.uid,
              )
              .then((_) {
                print('[DEBUG] User credentials saved for persistent login');
              })
              .catchError((e) {
                print('[ERROR] Failed to save credentials: $e');
              });

          setState(() => _loading = false);
          GlassyToast.show(context, _localizations.loginSuccessful);
          print('[DEBUG] Session timeout set for 2 hours');

          // Check subscription status before navigating
          _checkSubscriptionAndNavigate();
        })
        .catchError((e) {
          print('[ERROR] Login failed: $e');
          setState(() => _loading = false);
          final msg = e is FirebaseAuthException
              ? e.message ?? 'Auth error'
              : e.toString();
          GlassyToast.show(context, msg);
        });
  }

  Future<void> _checkSubscriptionAndNavigate() async {
    try {
      final subscriptionService = SubscriptionService();
      final isValid = await subscriptionService.isSubscriptionValid();

      if (!mounted) return;

      if (isValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      }
    } catch (e) {
      print('[ERROR] Error checking subscription: $e');
      // Fail closed — require subscription screen on errors
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.isDark(context)
                ? const [
                    AppTheme.darkScaffold,
                    AppTheme.darkSurface,
                    AppTheme.darkScaffold,
                  ]
                : const [
                    Color(0xFFE8F5E9),
                    Color(0xFFF5F5F5),
                    Color(0xFFE8F5E9),
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final isDesktop = constraints.maxWidth >= 1000;
              final maxFormWidth = isTablet ? 480.0 : double.infinity;

              // Desktop: side-by-side layout with branding left, form right
              if (isDesktop) {
                return Row(
                  children: [
                    // Left panel — branding
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1B4D3E),
                              Color(0xFF134E3A),
                              Color(0xFF0F3B2F),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SlideTransition(
                            position: _offsetAnimation,
                            child: FadeTransition(
                              opacity: _opacityAnimation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 32,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      width: 120,
                                      height: 120,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _localizations.appName,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _localizations.backboneOfBusiness,
                                    style: TextStyle(
                                      fontFamily: 'Literata',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  // Feature highlights
                                  ...[
                                    '📊 ${_localizations.salesProfitAnalysis}',
                                    '📦 ${_localizations.trackPurchases}',
                                    '👥 ${_localizations.manageCustomers}',
                                  ].map(
                                    (text) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontFamily: 'Literata',
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
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
                    // Right panel — form
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48.0,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: _buildLoginForm(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Mobile/Tablet: existing layout (unchanged)
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? constraints.maxWidth * 0.1 : 24.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: _offsetAnimation,
                          child: FadeTransition(
                            opacity: _opacityAnimation,
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14352C),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.mint.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 36,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppTheme.mint,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  _localizations.appName,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryText(context),
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _localizations.backboneOfBusiness,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Login Card with Glassmorphism
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxFormWidth),
                            child: SlideTransition(
                              position: _offsetAnimation,
                              child: FadeTransition(
                                opacity: _opacityAnimation,
                                child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Welcome Back Header
                                          Text(
                                            _localizations.welcomeBack,
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryText(context),
                                              fontFamily: 'Literata',
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _localizations.signInToAccount,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.mutedText(context),
                                              fontFamily: 'Literata',
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          // Email field with animation
                                          SlideTransition(
                                            position: _fieldAnimations[0],
                                            child: FadeTransition(
                                              opacity: _fieldFadeAnimations[0],
                                              child: _buildAnimatedInputField(
                                                controller:
                                                    _emailOrPhoneController,
                                                hintText:
                                                    _localizations.emailAddress,
                                                icon: Icons.mail_outline,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Password field with animation
                                          SlideTransition(
                                            position: _fieldAnimations[1],
                                            child: FadeTransition(
                                              opacity: _fieldFadeAnimations[1],
                                              child:
                                                  _buildAnimatedPasswordField(),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Forgot password with animation
                                          SlideTransition(
                                            position: _fieldAnimations[2],
                                            child: FadeTransition(
                                              opacity: _fieldFadeAnimations[2],
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const ChangePasswordPage(),
                                                      ),
                                                    );
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    _localizations
                                                        .forgotPasswordQuestion,
                                                    style: TextStyle(
                                                      color: AppColors.accent(
                                                        context,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                      fontFamily: 'Literata',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Sign In Button with animation
                                          SlideTransition(
                                            position: _fieldAnimations[3],
                                            child: FadeTransition(
                                              opacity: _fieldFadeAnimations[3],
                                              child: _buildSignInButton(),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // OR Divider
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                child: Text(
                                                  _localizations.orDivider,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1,
                                                    fontFamily: 'Literata',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          // Google Sign In Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () {},
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                side: BorderSide(
                                                  color: AppColors.border(
                                                    context,
                                                  ),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/google.png',
                                                    width: 22,
                                                    height: 22,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Container(
                                                            width: 22,
                                                            height: 22,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                            child: const Center(
                                                              child: Text(
                                                                'G',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    _localizations
                                                        .continueWithGoogle,
                                                    style: TextStyle(
                                                      color: AppColors.primaryText(context),
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Literata',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const SizedBox(height: 40),
                        // Sign up link
                        SlideTransition(
                          position: _offsetAnimation,
                          child: FadeTransition(
                            opacity: _opacityAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _localizations.dontHaveAccount,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SignupPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _localizations.signUp,
                                    style: TextStyle(
                                      color: AppTheme.mint,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Reusable login form widget used by both desktop and mobile layouts.
  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Back Header
        Text(
          _localizations.welcomeBack,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText(context),
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _localizations.signInToAccount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[700],
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 28),
        SlideTransition(
          position: _fieldAnimations[0],
          child: FadeTransition(
            opacity: _fieldFadeAnimations[0],
            child: _buildAnimatedInputField(
              controller: _emailOrPhoneController,
              hintText: _localizations.emailAddress,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SlideTransition(
          position: _fieldAnimations[1],
          child: FadeTransition(
            opacity: _fieldFadeAnimations[1],
            child: _buildAnimatedPasswordField(),
          ),
        ),
        const SizedBox(height: 12),
        SlideTransition(
          position: _fieldAnimations[2],
          child: FadeTransition(
            opacity: _fieldFadeAnimations[2],
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _localizations.forgotPasswordQuestion,
                  style: TextStyle(
                    color: AppTheme.mint,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SlideTransition(
          position: _fieldAnimations[3],
          child: FadeTransition(
            opacity: _fieldFadeAnimations[3],
            child: _buildSignInButton(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _localizations.orDivider,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontFamily: 'Literata',
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.border(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, _, _) => Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _localizations.continueWithGoogle,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _localizations.dontHaveAccount,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => SignupPage()));
              },
              child: Text(
                _localizations.signUp,
                style: TextStyle(
                  color: AppTheme.mint,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? hintText,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'Literata',
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.mutedText(context),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Literata',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _localizations.password,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: _localizations.password,
              hintStyle: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'Literata',
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.mutedText(context),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.mutedText(context),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Literata',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mint.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.mint,
          disabledBackgroundColor: AppColors.chipFill(context),
          foregroundColor: AppTheme.onMint,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onMint),
                  strokeWidth: 2,
                ),
              )
            : Text(
                _localizations.signIn,
                style: TextStyle(
                  color: AppTheme.onMint,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
      ),
    );
  }
}
