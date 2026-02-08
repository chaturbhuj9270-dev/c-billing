import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/subscription_service.dart';
import '../../features/dashboard/presentation/pages/optimized_dashboard_page.dart';

/// Subscription screen shown when user's subscription has expired
/// This is a full-screen modal that cannot be dismissed
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      // In production, integrate with actual payment gateway (Razorpay, Stripe, etc.)
      await Future.delayed(const Duration(seconds: 2));

      // Activate subscription
      final success = await _subscriptionService.activateSubscription();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Subscription activated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
            (route) => false,
          );
        }
      } else {
        throw Exception('Failed to activate subscription');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D3B2E), Color(0xFF1B4D3E), Color(0xFF2A5F4E)],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // App Logo
                      _buildLogo(),
                      const SizedBox(height: 32),
                      // Expiry Message
                      _buildExpiryMessage(),
                      const SizedBox(height: 40),
                      // Subscription Card
                      _buildSubscriptionCard(),
                      const SizedBox(height: 32),
                      // Benefits List
                      _buildBenefitsList(),
                      const SizedBox(height: 40),
                      // Subscribe Button
                      _buildSubscribeButton(),
                      const SizedBox(height: 24),
                      // Terms text
                      _buildTermsText(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'C',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4D3E),
            fontFamily: 'Literata',
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryMessage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Subscription Expired',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your subscription has expired',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Literata',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Renew now to continue using all features',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Literata',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PREMIUM PLAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  fontFamily: 'Literata',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
                  ),
                ),
                Text(
                  '3,999',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Valid for 1 Year',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Literata',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Just ₹333/month',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1B4D3E).withOpacity(0.8),
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {'icon': Icons.receipt_long, 'text': 'Unlimited Bill Generation'},
      {
        'icon': Icons.inventory_2_outlined,
        'text': 'Complete Inventory Management',
      },
      {'icon': Icons.people_outline, 'text': 'Customer & Supplier Tracking'},
      {
        'icon': Icons.analytics_outlined,
        'text': 'Advanced Analytics & Reports',
      },
      {'icon': Icons.print_outlined, 'text': 'POS Printer Support'},
      {'icon': Icons.cloud_outlined, 'text': 'Cloud Backup & Sync'},
      {'icon': Icons.support_agent_outlined, 'text': 'Priority Support'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What you get:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map(
          (benefit) => _buildBenefitItem(
            benefit['icon'] as IconData,
            benefit['text'] as String,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Literata',
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.greenAccent.withOpacity(0.8),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handleSubscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: const Color(0xFF1B4D3E),
          disabledBackgroundColor: Colors.grey,
          elevation: 8,
          shadowColor: const Color(0xFFFFD700).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4D3E)),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond_outlined, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Subscribe Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Secure Payment',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'By subscribing, you agree to our Terms of Service',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
            fontFamily: 'Literata',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
