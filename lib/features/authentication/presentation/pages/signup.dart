import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.grey[100]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Branding
                  SlideTransition(
                    position: _offsetAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Column(
                        children: [
                          Text(
                            'C-BILLING',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B4D3E),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your account',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Signup card
                  SlideTransition(
                    position: _offsetAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // First Name field
                            _buildInputField(
                              label: 'First Name',
                              controller: _firstController,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            // Middle Name field
                            _buildInputField(
                              label: 'Middle Name',
                              controller: _middleController,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            // Last Name field
                            _buildInputField(
                              label: 'Last Name',
                              controller: _lastController,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            // Email field
                            _buildInputField(
                              label: 'Email Address',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            // Contact field
                            _buildInputField(
                              label: 'Contact Number',
                              controller: _contactController,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 16),
                            // Address field
                            _buildInputField(
                              label: 'Address',
                              controller: _addressController,
                              keyboardType: TextInputType.streetAddress,
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),
                            // Password field
                            _buildInputField(
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
                            // Confirm Password field
                            _buildInputField(
                              label: 'Confirm Password',
                              controller: _confirmController,
                              obscureText: true,
                              icon: Icons.lock_outline,
                            ),
                            const SizedBox(height: 24),
                            // Create Account button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4D3E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
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
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFF1B4D3E),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 40),
                ],
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
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[500],
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }
}
