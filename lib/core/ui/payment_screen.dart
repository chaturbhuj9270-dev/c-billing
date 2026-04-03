import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../services/language_service.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

/// Payment screen with QR code for subscription payment
/// Premium UI matching the app's elegant design language
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String contactNumber = '9970662978';

  AppLocalizations get _localizations =>
      AppLocalizations.of(LanguageService.instance.currentLanguage);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/91$contactNumber?text=Hi, I have made the payment for C-BILLING subscription. Please find the screenshot attached.',
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        GlassyToast.show(context, _localizations.couldNotOpenWhatsApp, isError: true);
      }
    }
  }

  Future<void> _callSupport() async {
    final Uri phoneUrl = Uri.parse('tel:$contactNumber');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    }
  }

  void _copyNumber() {
    Clipboard.setData(const ClipboardData(text: contactNumber));
    GlassyToast.show(context, _localizations.phoneNumberCopied);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFE8E8E4)),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Custom App Bar
                  _buildAppBar(),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Amount Display
                            _buildAmountSection(),
                            const SizedBox(height: 28),
                            // QR Code Card
                            _buildQRCard(),
                            const SizedBox(height: 24),
                            // Instructions
                            _buildInstructions(),
                            const SizedBox(height: 28),
                            // Action Buttons
                            _buildActionButtons(),
                            const SizedBox(height: 30),
                            // Bottom Branding
                            _buildBottomBranding(),
                            const SizedBox(height: 20),
                          ],
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
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _localizations.payment,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B4D3E).withValues(alpha: 0.15),
                const Color(0xFF2E7D32).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                _localizations.amountToPay,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.6),
                  fontFamily: 'Literata',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                        fontFamily: 'Literata',
                      ),
                    ),
                  ),
                  const Text(
                    '3,999',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4D3E),
                      fontFamily: 'Literata',
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _localizations.oneYearSubscription,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Literata',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _localizations.scanQRCodeToPay,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
              fontFamily: 'Literata',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/payment_qr.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 80,
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'QR Code',
                          style: TextStyle(
                            color: const Color(
                              0xFF1B4D3E,
                            ).withValues(alpha: 0.5),
                            fontSize: 14,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // UPI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _localizations.payViaAnyUPIApp,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE082).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFFFF8F00),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _localizations.important,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE65100),
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _localizations.pleaseShareScreenshotOn,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
              fontFamily: 'Literata',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _copyNumber,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 18, color: Color(0xFF1B4D3E)),
                  const SizedBox(width: 8),
                  const Text(
                    contactNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4D3E),
                      fontFamily: 'Literata',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.copy,
                      size: 14,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _localizations.subscriptionActivatedWithin24Hours,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.6),
              fontFamily: 'Literata',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // WhatsApp Button - Primary
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openWhatsApp,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _localizations.shareOnWhatsApp,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
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
        ),
        const SizedBox(height: 12),
        // Call Support Button - Secondary
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _callSupport,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call_outlined,
                        size: 20,
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _localizations.callSupport,
                        style: TextStyle(
                          color: const Color(0xFF1B4D3E).withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          width: 150,
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 14,
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              _localizations.securePayment,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
