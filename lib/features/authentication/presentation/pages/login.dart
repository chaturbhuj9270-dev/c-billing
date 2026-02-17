import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../main.dart' show initializeSyncServices;
import '../../../dashboard/presentation/pages/optimized_dashboard_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/ui/subscription_screen.dart';
import 'signup.dart';
import 'change_password_page.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.enterEmailPhone)),
      );
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

          // Initialize session with 2-hour timeout
          final sessionManager = SessionManager();
          sessionManager.initializeSession(cred.user!, () {
            print('[CRITICAL] Session expired - clearing data and logging out');
            // Use LogoutService to ensure all local data is cleared on session expiry
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_localizations.sessionExpired),
                ),
              );
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_localizations.loginSuccessful)));
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
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
      // If error, navigate to dashboard anyway
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFF5F5F5), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SlideTransition(
                    position: _offsetAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1B4D3E,
                                  ).withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _localizations.appName,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B4D3E),
                              letterSpacing: 2,
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
                              color: Color(0xFF5D6D68),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Login Card with Glassmorphism
                  SlideTransition(
                    position: _offsetAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Back Header
                                Text(
                                  _localizations.welcomeBack,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
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
                                // Email field with animation
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
                                // Password field with animation
                                SlideTransition(
                                  position: _fieldAnimations[1],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[1],
                                    child: _buildAnimatedPasswordField(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Forgot password with animation
                                SlideTransition(
                                  position: _fieldAnimations[2],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[2],
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const ChangePasswordPage(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          _localizations.forgotPasswordQuestion,
                                          style: TextStyle(
                                            color: Color(0xFF1B4D3E),
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
                                      padding: const EdgeInsets.symmetric(
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
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
                                                            FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _localizations.continueWithGoogle,
                                          style: TextStyle(
                                            color: Color(0xFF1A1A1A),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
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
                                  builder: (_) => const SignupPage(),
                                ),
                              );
                            },
                            child: Text(
                              _localizations.signUp,
                              style: TextStyle(
                                color: Color(0xFF1B4D3E),
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
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Literata',
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF1B4D3E), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  Widget _buildAnimatedPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: _localizations.password,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Literata',
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: const Color(0xFF1B4D3E),
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF1B4D3E),
              size: 22,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E).withValues(alpha: 0.9),
              disabledBackgroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _localizations.signIn,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
