import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../../../core/services/session_manager.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _firstController = TextEditingController();
  final _middleController = TextEditingController();
  final _lastController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void dispose() {
    _animController.dispose();
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    Future.delayed(const Duration(milliseconds: 150), () => _animController.forward());
  }

  void _submit() {
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final pw = _passwordController.text;
    final cpw = _confirmController.text;

    // Validate all required fields
    if (email.isEmpty || contact.isEmpty || pw.isEmpty || cpw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    if (pw != cpw) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Validate phone number format
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(contact)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit phone number')));
      return;
    }

    // Create user with email and password
    FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: pw,
    ).then((userCredential) async {
      final currentUser = userCredential.user;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account creation failed')));
        return;
      }

      print('[DEBUG] User account created: ${currentUser.uid}');
      
      try {
        print('[DEBUG] Writing user profile to Firestore...');
        final doc = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        await doc.set({
          'firstName': _firstController.text.trim(),
          'middleName': _middleController.text.trim(),
          'lastName': _lastController.text.trim(),
          'address': _addressController.text.trim(),
          'email': email,
          'contact': contact,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('[DEBUG] Firestore write successful for UID: ${currentUser.uid}');
        
        // Initialize session for new user
        final sessionManager = SessionManager();
        sessionManager.initializeSession(currentUser, () {
          print('[CRITICAL] Session expired - logging out user');
          FirebaseAuth.instance.signOut().then((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session expired. Please login again.'))
              );
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          });
        });
        print('[DEBUG] Session initialized with 2-hour timeout');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account created successfully'),
            backgroundColor: Colors.green,
          ));
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('[ERROR] Account setup error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }).catchError((e) {
      print('[ERROR] Account creation failed: $e');
      if (mounted) {
        final msg = e is FirebaseAuthException ? e.message ?? 'Account creation failed' : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] SignupPage build() called');
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo image outside card
                SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF0C3314),
                              child: const Icon(
                                Icons.receipt_long,
                                size: 50,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Header outside card
                SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Create Account',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0C3314),
                              letterSpacing: 0.5,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Join us to get started',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black45,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Signup form card with glass effect
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
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E4),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0C3314).withOpacity(0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Name fields row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      theme,
                                      label: 'First Name',
                                      controller: _firstController,
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      theme,
                                      label: 'Last Name',
                                      controller: _lastController,
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Email field
                              _buildInputField(
                                theme,
                                label: 'Email Address',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 16),
                              // Contact field
                              _buildInputField(
                                theme,
                                label: 'Contact Number',
                                controller: _contactController,
                                keyboardType: TextInputType.phone,
                                icon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 16),
                              // Address field
                              _buildInputField(
                                theme,
                                label: 'Address',
                                controller: _addressController,
                                keyboardType: TextInputType.text,
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 16),
                              // Password fields
                              _buildInputField(
                                  theme,
                                  label: 'Password',
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(right: 12),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  theme,
                                  label: 'Confirm Password',
                                  controller: _confirmController,
                                  obscureText: true,
                                  icon: Icons.lock_outline,
                                ),
                                const SizedBox(height: 24),
                                // Create account button
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF0C3314),
                                    shadowColor: const Color(0xFF0C3314),
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              // Divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(thickness: 1, color: Colors.grey, height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      'or',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(thickness: 1, color: Colors.grey, height: 1)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Already have account link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: Color(0xFF0C3314),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    try {
      print('[DEBUG] Building input field: $label');
      return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          label: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    } catch (e) {
      print('[ERROR] Error building input field for $label: $e');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Text(
          'Error rendering $label field: $e',
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        ),
      );
    }
  }
}
