import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../services/language_service.dart';
import 'payment_screen.dart';

/// Subscription screen shown when user's subscription has expired
/// Premium UI matching the app's elegant design language
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  static const String contactNumber = '9970662978';

  AppLocalizations get _localizations =>
      AppLocalizations.of(LanguageService.instance.currentLanguage);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
  }

  Future<void> _callSupport() async {
    final Uri phoneUrl = Uri.parse('tel:$contactNumber');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFE8E8E4)),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Language Selector
                      _buildLanguageSelector(),
                      const SizedBox(height: 20),
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 24),
                      // App Name
                      _buildAppName(),
                      const SizedBox(height: 20),
                      // Expiry Badge
                      _buildExpiryBadge(),
                      const SizedBox(height: 32),
                      // Pricing Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildPricingCard(),
                      ),
                      const SizedBox(height: 28),
                      // Benefits
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildBenefitsCard(),
                      ),
                      const SizedBox(height: 32),
                      // Subscribe Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: _buildSubscribeButton(),
                      ),
                      const SizedBox(height: 24),
                      // Contact Section
                      _buildContactSection(),
                      const SizedBox(height: 40),
                      // Bottom Branding
                      _buildBottomBranding(),
                      const SizedBox(height: 30),
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

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: LanguageService.instance.currentLanguage,
                isDense: true,
                icon: Icon(
                  Icons.language,
                  size: 18,
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                ),
                style: const TextStyle(
                  color: Color(0xFF1B4D3E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
                dropdownColor: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Hindi', child: Text('हिंदी')),
                  DropdownMenuItem(value: 'Marathi', child: Text('मराठी')),
                ],
                onChanged: (String? newLanguage) {
                  if (newLanguage != null) {
                    setState(() {
                      LanguageService.instance.setLanguage(newLanguage);
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildAppName() {
    return Column(
      children: [
        const Text(
          'C-BILLING',
          style: TextStyle(
            color: Color(0xFF1B4D3E),
            fontSize: 36,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _localizations.premiumFinancialSolutions,
          style: TextStyle(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _localizations.subscriptionExpired,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Literata',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B4D3E).withValues(alpha: 0.15),
                  const Color(0xFF2E7D32).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Premium Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localizations.premiumPlan,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                    const Text(
                      '3,999',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _localizations.perYear,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.6),
                    fontFamily: 'Literata',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                // Hurry up badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _localizations.hurryUpFirstUsers,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[700],
                            fontFamily: 'Literata',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Divider
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                        const Color(0xFF1B4D3E),
                        const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Monthly breakdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _localizations.justPerMonth,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizations.whatsIncluded,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
              fontFamily: 'Literata',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(_localizations.unlimitedBillGeneration),
          _buildBenefitItem(_localizations.completeInventoryManagement),
          _buildBenefitItem(_localizations.customerSupplierTracking),
          _buildBenefitItem(_localizations.advancedReportsAnalytics),
          _buildBenefitItem(_localizations.posPrinterSupport),
          _buildBenefitItem(_localizations.cloudBackupPrioritySupport),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF1B4D3E), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                fontFamily: 'Literata',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B4D3E).withValues(alpha: 0.9),
                  const Color(0xFF2E7D32).withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleSubscribe,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.diamond_outlined,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _localizations.subscribeNow,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                          letterSpacing: 0.5,
                        ),
                      ),
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

  Widget _buildContactSection() {
    return Column(
      children: [
        Text(
          _localizations.needHelpContactUs,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.5),
            fontFamily: 'Literata',
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _callSupport,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                const Text(
                  contactNumber,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4D3E),
                    fontFamily: 'Literata',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBranding() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1B4D3E).withValues(alpha: 0.05),
                const Color(0xFF1B4D3E),
                const Color(0xFF1B4D3E).withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _localizations.poweredBy,
                style: TextStyle(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.35),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Literata',
                ),
              ),
              TextSpan(
                text: _localizations.chaturbhujSolutions,
                style: const TextStyle(
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
    );
  }
}
