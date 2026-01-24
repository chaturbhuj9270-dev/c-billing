import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

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

  bool _otpSent = false;
  bool _otpVerified = false;
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

  void _sendOtp() {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter contact number first')));
      return;
    }
    // Simulate sending OTP
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent')));
    _showOtpDialog();
  }

  void _showOtpDialog() async {
    final otpController = TextEditingController();
    final valid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 10,
        title: Text(
          'Verify OTP',
          style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0C3314),
            fontSize: 22,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit OTP sent to your phone',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    letterSpacing: 3,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final v = otpController.text.trim();
              if (v.length == 6) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid 6-digit OTP'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C3314),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 6,
              shadowColor: const Color(0xFF0C3314),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Verify',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    if (valid == true) {
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _submit() {
    if (!_otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify OTP first')));
      return;
    }
    final pw = _passwordController.text;
    final cpw = _confirmController.text;
    if (pw.isEmpty || cpw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter password and confirm')));
      return;
    }
    if (pw != cpw) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Create Firebase user and store profile in Firestore
    final email = _emailController.text.trim();
    print('[DEBUG] Starting signup for email: $email');
    
    FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pw).then((cred) async {
      final uid = cred.user?.uid;
      print('[DEBUG] Firebase Auth successful. UID: $uid');
      
      if (uid != null) {
        try {
          print('[DEBUG] Writing user profile to Firestore...');
          final doc = FirebaseFirestore.instance.collection('users').doc(uid);
          await doc.set({
            'firstName': _firstController.text.trim(),
            'middleName': _middleController.text.trim(),
            'lastName': _lastController.text.trim(),
            'address': _addressController.text.trim(),
            'email': email,
            'contact': _contactController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('[DEBUG] Firestore write successful for UID: $uid');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup successful')));
            Navigator.of(context).pop();
          }
        } catch (firestoreError) {
          print('[ERROR] Firestore write failed: $firestoreError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database error: $firestoreError')));
          }
        }
      } else {
        print('[ERROR] No UID returned from Firebase Auth');
      }
    }).catchError((e) {
      print('[ERROR] Firebase Auth error: $e');
      final msg = e is FirebaseAuthException ? e.message ?? 'Signup error' : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFE6EDE7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header
                SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Create Account',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0C3314),
                            letterSpacing: 0.5,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join us to get started',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black45,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                            color: Colors.white.withOpacity(0.90),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0C3314).withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                                spreadRadius: 2,
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
                              // Get OTP button
                              ElevatedButton(
                                onPressed: _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: const Color(0xFF0C3314),
                                  shadowColor: const Color(0xFF0C3314),
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _otpSent ? 'Resend OTP' : 'Get OTP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (_otpVerified) ...[
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
                              ] else ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!, width: 1),
                                  ),
                                  child: const Text(
                                    'Verify your phone with OTP to set password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
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
  }
}
