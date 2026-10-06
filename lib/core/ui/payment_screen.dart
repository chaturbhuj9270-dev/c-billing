import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/subscription_products.dart';
import '../localization/app_localizations.dart';
import '../services/language_service.dart';
import '../services/play_billing_service.dart';
import '../services/subscription_service.dart';
import '../../features/dashboard/presentation/pages/optimized_dashboard_page.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Google Play Billing payment screen for yearly subscription (₹3999).
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

  bool _isPaying = false;
  bool _loadingProduct = true;
  String? _statusMessage;
  String? _productError;
  String _priceLabel = SubscriptionProducts.fallbackPriceLabel;

  final PlayBillingService _playBilling = PlayBillingService();
  final SubscriptionService _subscriptionService = SubscriptionService();

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
    _loadStoreProduct();
  }

  Future<void> _loadStoreProduct() async {
    setState(() {
      _loadingProduct = true;
      _productError = null;
    });
    try {
      await _playBilling.initialize();
      if (!mounted) return;
      setState(() {
        _priceLabel = _playBilling.displayPrice;
        _loadingProduct = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProduct = false;
        _productError = e.toString();
        _priceLabel = SubscriptionProducts.fallbackPriceLabel;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startPlayPurchase() async {
    if (_isPaying) return;

    setState(() {
      _isPaying = true;
      _statusMessage = _localizations.preparingSecurePayment;
    });

    try {
      final result = await _playBilling.purchaseYearlySubscription();
      if (!mounted) return;
      await _handleBillingResult(result);
    } catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        '${_localizations.paymentFailedTryAgain}: $e',
        isError: true,
      );
      setState(() {
        _statusMessage = null;
        _isPaying = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (_isPaying) return;

    setState(() {
      _isPaying = true;
      _statusMessage = _localizations.restoringPurchases;
    });

    try {
      final result = await _playBilling.restorePurchases();
      if (!mounted) return;
      await _handleBillingResult(result);
    } catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        '${_localizations.paymentFailedTryAgain}: $e',
        isError: true,
      );
      setState(() {
        _statusMessage = null;
        _isPaying = false;
      });
    }
  }

  Future<void> _handleBillingResult(PlayBillingResult result) async {
    if (result.success) {
      setState(() => _statusMessage = _localizations.activatingSubscription);

      final active = await _subscriptionService.waitUntilActive(
        timeout: const Duration(seconds: 12),
      );

      if (!mounted) return;

      if (active) {
        GlassyToast.show(context, _localizations.subscriptionActivatedSuccess);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OptimizedDashboardPage()),
          (_) => false,
        );
        return;
      }

      GlassyToast.show(context, _localizations.paymentReceivedActivatingSoon);
      setState(() {
        _statusMessage = _localizations.paymentReceivedActivatingSoon;
        _isPaying = false;
      });
      return;
    }

    final canceled = result.status == 'CANCELED';
    if (!canceled) {
      GlassyToast.show(
        context,
        result.message.isNotEmpty
            ? result.message
            : _localizations.paymentFailedTryAgain,
        isError: true,
      );
    }

    setState(() {
      _statusMessage = null;
      _isPaying = false;
    });
  }

  Future<void> _callSupport() async {
    final Uri phoneUrl = Uri.parse('tel:$contactNumber');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
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
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildAmountSection(),
                            const SizedBox(height: 28),
                            _buildPlayBillingCard(),
                            const SizedBox(height: 24),
                            _buildInstructions(),
                            const SizedBox(height: 28),
                            _buildActionButtons(),
                            const SizedBox(height: 30),
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
            onTap: _isPaying ? null : () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentSoft(context, 0.1)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.accentSoft(context, 0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _localizations.payment,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.accent(context),
                fontFamily: 'Literata',
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 40),
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
                  color: AppColors.accentSoft(context, 0.6),
                  fontFamily: 'Literata',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingProduct)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent(context),
                    ),
                  ),
                )
              else
                Text(
                  _priceLabel,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent(context),
                    fontFamily: 'Literata',
                    height: 1,
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent(context),
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

  Widget _buildPlayBillingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSoft(context, 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shop_outlined,
              size: 34,
              color: AppColors.accent(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _localizations.payViaGooglePlay,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accentSoft(context, 0.85),
              fontFamily: 'Literata',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localizations.googlePlayPaymentModesHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accentSoft(context, 0.55),
              fontFamily: 'Literata',
              height: 1.4,
            ),
          ),
          if (_productError != null) ...[
            const SizedBox(height: 14),
            Text(
              _localizations.playProductNotReady,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
                fontFamily: 'Literata',
                height: 1.35,
              ),
            ),
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPaying)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent(context),
                    ),
                  ),
                if (_isPaying) const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            _localizations.googlePlayPaymentInstructions,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.accentSoft(context, 0.8),
              fontFamily: 'Literata',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canPay = !_isPaying && !_loadingProduct && _productError == null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1B4D3E).withValues(alpha: 0.95),
                      const Color(0xFF2E7D32).withValues(alpha: 0.88),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentSoft(context, 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canPay ? _startPlayPurchase : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPaying)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.payment,
                              size: 22,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 10),
                          Text(
                            _isPaying
                                ? _localizations.processingPayment
                                : _localizations.payWithGooglePlay,
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
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentSoft(context, 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isPaying ? null : _restorePurchases,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restore,
                        size: 20,
                        color: AppColors.accentSoft(context, 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _localizations.restorePurchases,
                        style: TextStyle(
                          color: AppColors.accentSoft(context, 0.9),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentSoft(context, 0.3),
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
                        color: AppColors.accentSoft(context, 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _localizations.callSupport,
                        style: TextStyle(
                          color: AppColors.accentSoft(context, 0.9),
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
              color: AppColors.accentSoft(context, 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              _localizations.securePaymentPoweredByGooglePlay,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.accentSoft(context, 0.4),
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
