import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/logout_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _firstController = TextEditingController();
  final _middleController = TextEditingController();
  final _lastController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
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
    _firstController.dispose();
    _middleController.dispose();
    _lastController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      duration: const Duration(milliseconds: 1200),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    // Staggered field animations (8 fields)
    _fieldAnimations = List.generate(8, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
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

    _fieldFadeAnimations = List.generate(8, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
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

    Future.delayed(
      const Duration(milliseconds: 150),
      () => _animController.forward(),
    );
    Future.delayed(
      const Duration(milliseconds: 600),
      () => _staggerController.forward(),
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final pw = _passwordController.text;
    final cpw = _confirmController.text;

    // Validate all required fields
    if (email.isEmpty || contact.isEmpty || pw.isEmpty || cpw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.pleaseFillAllFields)),
      );
      return;
    }

    if (pw != cpw) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_localizations.passwordsDoNotMatch)));
      return;
    }

    // Validate phone number format
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(contact)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizations.enterValid10DigitPhone)),
      );
      return;
    }

    // Create user with email and password
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: pw)
        .then((userCredential) async {
          final currentUser = userCredential.user;
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_localizations.accountCreationFailed)),
            );
            return;
          }

          print('[DEBUG] User account created: ${currentUser.uid}');

          try {
            print('[DEBUG] Writing user profile to Firestore...');
            final doc = FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid);
            await doc.set({
              'firstName': _firstController.text.trim(),
              'middleName': _middleController.text.trim(),
              'lastName': _lastController.text.trim(),
              'address': _addressController.text.trim(),
              'email': email,
              'contact': contact,
              'createdAt': FieldValue.serverTimestamp(),
              // Set subscription date to today - user gets full 1 year subscription
              'subscriptionDate': FieldValue.serverTimestamp(),
            });
            print(
              '[DEBUG] Firestore write successful for UID: ${currentUser.uid}',
            );

            // Initialize session for new user
            final sessionManager = SessionManager();
            sessionManager.initializeSession(currentUser, () {
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
            print('[DEBUG] Session initialized with 2-hour timeout');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_localizations.accountCreated),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            }
          } catch (e) {
            print('[ERROR] Account setup error: $e');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
            }
          }
        })
        .catchError((e) {
          print('[ERROR] Account creation failed: $e');
          if (mounted) {
            final msg = e is FirebaseAuthException
                ? e.message ?? 'Account creation failed'
                : e.toString();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
        });
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
                  const SizedBox(height: 20),
                  // Branding - Logo and C-BILLING text
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
                              width: 70,
                              height: 70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _localizations.appName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B4D3E),
                              letterSpacing: 2,
                              fontFamily: 'Literata',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _localizations.createYourAccount,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700],
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Signup card with Glassmorphism
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // First Name field
                                SlideTransition(
                                  position: _fieldAnimations[0],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[0],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.firstName,
                                      controller: _firstController,
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Middle Name field
                                SlideTransition(
                                  position: _fieldAnimations[1],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[1],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.middleName,
                                      controller: _middleController,
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Last Name field
                                SlideTransition(
                                  position: _fieldAnimations[2],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[2],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.lastName,
                                      controller: _lastController,
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Email field
                                SlideTransition(
                                  position: _fieldAnimations[3],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[3],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.emailAddress,
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      icon: Icons.email_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Contact field
                                SlideTransition(
                                  position: _fieldAnimations[4],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[4],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.contactNumber,
                                      controller: _contactController,
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Address field
                                SlideTransition(
                                  position: _fieldAnimations[5],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[5],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.address,
                                      controller: _addressController,
                                      keyboardType: TextInputType.streetAddress,
                                      icon: Icons.location_on_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Password field
                                SlideTransition(
                                  position: _fieldAnimations[6],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[6],
                                    child: _buildAnimatedPasswordField(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Confirm Password field
                                SlideTransition(
                                  position: _fieldAnimations[7],
                                  child: FadeTransition(
                                    opacity: _fieldFadeAnimations[7],
                                    child: _buildAnimatedInputField(
                                      label: _localizations.confirmPassword,
                                      controller: _confirmController,
                                      obscureText: true,
                                      icon: Icons.lock_outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Create Account button
                                _buildCreateAccountButton(),
                                const SizedBox(height: 24),
                                // Divider
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
                                // Sign in link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _localizations.alreadyHaveAccount,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontFamily: 'Literata',
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Text(
                                        _localizations.signIn,
                                        style: TextStyle(
                                          color: Color(0xFF1B4D3E),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Literata',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    bool obscureText = false,
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
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'Literata',
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF1B4D3E), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
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
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'Literata',
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: const Color(0xFF1B4D3E),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF1B4D3E),
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E).withValues(alpha: 0.9),
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
            child: Text(
              _localizations.createAccount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
    );
  }
}
