import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/authentication/presentation/pages/login.dart';

class SplashPage extends StatefulWidget {
  final Duration duration;

  const SplashPage({super.key, this.duration = const Duration(seconds: 4)});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _goNext);
  }

  void _goNext() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPageV2()));
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
                      'THE BACKBONE OF YOUR\nBUSINESS',
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
                          text: 'CHATURBHUJ SOFTWARE',
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
                    'Newasa +91 9270788949',
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
