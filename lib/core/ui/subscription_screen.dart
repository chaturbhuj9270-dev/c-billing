import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';
import '../services/language_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import 'desktop_canvas.dart';
import 'payment_screen.dart';

/// Subscription screen shown when the user's subscription has expired.
/// Web/desktop uses a two-column renew layout; mobile keeps a vertical stack.
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

  bool get _desktop => DesktopCanvas.isDesktopPlatform;

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

  List<({IconData icon, String label})> get _features => [
        (
          icon: Icons.receipt_long_outlined,
          label: _localizations.unlimitedBillGeneration,
        ),
        (
          icon: Icons.inventory_2_outlined,
          label: _localizations.completeInventoryManagement,
        ),
        (
          icon: Icons.groups_outlined,
          label: _localizations.customerSupplierTracking,
        ),
        (
          icon: Icons.bar_chart_rounded,
          label: _localizations.advancedReportsAnalytics,
        ),
        (
          icon: Icons.print_outlined,
          label: _localizations.posPrinterSupport,
        ),
        (
          icon: Icons.cloud_done_outlined,
          label: _localizations.cloudBackupPrioritySupport,
        ),
      ];

  BoxDecoration _pageDecoration(BuildContext context) {
    final dark = AppColors.isDark(context);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [
                Color(0xFF0A1210),
                Color(0xFF0E1A16),
                Color(0xFF08100E),
              ]
            : const [
                Color(0xFFF4F7F4),
                Color(0xFFEAF2EC),
                Color(0xFFF7F8F5),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _pageDecoration(context),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -40,
                child: _GlowOrb(
                  size: _desktop ? 320 : 220,
                  color: AppColors.action(context).withValues(
                    alpha: AppColors.isDark(context) ? 0.18 : 0.12,
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -30,
                child: _GlowOrb(
                  size: _desktop ? 280 : 180,
                  color: AppColors.action(context).withValues(
                    alpha: AppColors.isDark(context) ? 0.14 : 0.08,
                  ),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _desktop
                        ? _buildDesktopLayout()
                        : _buildMobileLayout(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 28,
                vertical: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDesktopHeader(),
                  const SizedBox(height: 36),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: _buildDesktopLeftColumn(fillHeight: true),
                              ),
                              const SizedBox(width: 36),
                              Expanded(
                                flex: 10,
                                child: _buildDesktopFeaturesCard(
                                  fillHeight: true,
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildDesktopLeftColumn(fillHeight: false),
                                const SizedBox(height: 28),
                                _buildDesktopFeaturesCard(fillHeight: false),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader() {
    final dark = AppColors.isDark(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'C-Billing',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _localizations.premiumFinancialSolutions,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        _buildLanguageChip(compact: true, darkSurface: dark),
      ],
    );
  }

  Widget _buildDesktopLeftColumn({required bool fillHeight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpiryBadge(compact: true),
        const SizedBox(height: 22),
        Text(
          _localizations.renewToKeepBilling,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 40,
            fontWeight: FontWeight.w700,
            fontFamily: 'Literata',
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            _localizations.subscriptionEndedRenewBody,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 15,
              height: 1.55,
              fontFamily: 'Literata',
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildDesktopPricingCard(),
        if (fillHeight) const Spacer() else const SizedBox(height: 28),
        _buildContactLink(),
      ],
    );
  }

  Widget _buildDesktopPricingCard() {
    final dark = AppColors.isDark(context);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        const Color(0xFF1A3A2E),
                        const Color(0xFF143528),
                        const Color(0xFF0F2A20),
                      ]
                    : [
                        const Color(0xFF1B4A38),
                        const Color(0xFF164033),
                        const Color(0xFF12352B),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.white.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withValues(alpha: dark ? 0.45 : 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizations.premiumPlan,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white.withValues(alpha: 0.72),
                    letterSpacing: 1.6,
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '₹${SubscriptionService.subscriptionRegularPriceDisplay}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white.withValues(alpha: 0.45),
                          fontFamily: 'Literata',
                          decoration: TextDecoration.lineThrough,
                          decorationColor:
                              AppTheme.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹ ${SubscriptionService.subscriptionPriceDisplay}',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                        fontFamily: 'Literata',
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _localizations.perYear,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.white.withValues(alpha: 0.7),
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _localizations.justPerMonth,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.white.withValues(alpha: 0.65),
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildRenewButton(desktopStyle: true),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A227).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        _localizations.offerFirst100Users,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8C96A),
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
    );
  }

  Widget _buildDesktopFeaturesCard({required bool fillHeight}) {
    final dark = AppColors.isDark(context);
    final featureList = Column(
      mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < _features.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: AppColors.border(context).withValues(alpha: 0.55),
            ),
          _buildFeatureRow(_features[i].icon, _features[i].label),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
      decoration: BoxDecoration(
        color: dark
            ? AppTheme.darkCard.withValues(alpha: 0.92)
            : AppTheme.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? AppTheme.white.withValues(alpha: 0.08)
              : AppTheme.white.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: dark ? 0.35 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizations.whatsIncluded,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _localizations.everythingIncludedSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText(context),
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 22),
          if (fillHeight) Expanded(child: featureList) else featureList,
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    final accent = AppColors.actionBright(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
                fontFamily: 'Literata',
              ),
            ),
          ),
          Icon(Icons.check_circle, size: 20, color: accent),
        ],
      ),
    );
  }

  Widget _buildContactLink() {
    return InkWell(
      onTap: _callSupport,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 16,
              color: AppColors.mutedText(context),
            ),
            const SizedBox(width: 8),
            Text(
              _localizations.needHelpContactUs,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText(context),
                fontFamily: 'Literata',
                decoration: TextDecoration.underline,
                decorationColor: AppColors.mutedText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'C-Billing',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                _buildLanguageChip(compact: true),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildExpiryBadge(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              _localizations.renewToKeepBilling,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _localizations.subscriptionEndedRenewBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Literata',
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildDesktopPricingCard(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildMobileFeaturesCard(),
          ),
          const SizedBox(height: 24),
          _buildContactLink(),
          const SizedBox(height: 20),
          _buildBottomBranding(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildMobileFeaturesCard() {
    final dark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: dark
            ? AppTheme.darkCard.withValues(alpha: 0.92)
            : AppTheme.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizations.whatsIncluded,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _localizations.everythingIncludedSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText(context),
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 8),
          for (final feature in _features)
            _buildFeatureRow(feature.icon, feature.label),
        ],
      ),
    );
  }

  Widget _buildLanguageChip({
    bool compact = false,
    bool darkSurface = false,
  }) {
    final dark = AppColors.isDark(context) || darkSurface;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: dark
            ? AppTheme.white.withValues(alpha: 0.06)
            : AppTheme.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? AppTheme.white.withValues(alpha: 0.12)
              : AppColors.accentSoft(context, 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: LanguageService.instance.currentLanguage,
          isDense: true,
          icon: Icon(
            Icons.language,
            size: 18,
            color: AppColors.secondaryText(context),
          ),
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
          ),
          dropdownColor: AppColors.card(context),
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
    );
  }

  Widget _buildExpiryBadge({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.red.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _localizations.subscriptionExpired,
            style: TextStyle(
              color: AppTheme.red700,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Literata',
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewButton({bool desktopStyle = false}) {
    final dark = AppColors.isDark(context);
    final bg = desktopStyle
        ? (dark ? AppColors.actionBright(context) : AppTheme.white)
        : AppColors.action(context);
    final fg = desktopStyle
        ? (dark ? AppTheme.white : const Color(0xFF143F30))
        : AppTheme.white;

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: _handleSubscribe,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: desktopStyle ? 22 : 18,
              vertical: desktopStyle ? 14 : 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  desktopStyle
                      ? _localizations.renewNow
                      : _localizations.subscribeNow,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
                if (desktopStyle) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBranding() {
    return Column(
      children: [
        Container(
          width: 160,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.action(context).withValues(alpha: 0.05),
                AppColors.action(context),
                AppColors.action(context).withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _localizations.poweredBy,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Literata',
                ),
              ),
              TextSpan(
                text: _localizations.chaturbhujSolutions,
                style: TextStyle(
                  color: AppColors.primaryText(context),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
