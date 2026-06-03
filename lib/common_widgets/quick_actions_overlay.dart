import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/language_service.dart';
import '../features/billing/presentation/pages/bills_list_page.dart';
import '../features/inventory_management/presentation/pages/enhanced_product_page.dart';
import '../features/supplier/presentation/pages/enhanced_supplier_page.dart';
import '../features/company/presentation/pages/enhanced_company_page.dart';
import '../features/purchase_return/presentation/pages/purchase_return_screen.dart';
import '../features/event_order/presentation/pages/event_order_list_page.dart';
import '../features/quotation/presentation/pages/quotation_list_page.dart';
import '../features/inventory_management/presentation/pages/barcode_generator_page.dart';
import '../features/customer/presentation/pages/enhanced_customer_page.dart';

/// Data class for a quick-action item
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    this.onTap,
  });
}

/// A global Quick Actions FAB + overlay that can be placed in any Scaffold.
///
/// Usage: Add [GlobalQuickActionsFAB] to a Stack on top of your page content.
/// It manages its own open/close state internally.
class GlobalQuickActionsFAB extends StatefulWidget {
  const GlobalQuickActionsFAB({super.key});

  @override
  State<GlobalQuickActionsFAB> createState() => _GlobalQuickActionsFABState();
}

class _GlobalQuickActionsFABState extends State<GlobalQuickActionsFAB>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  List<QuickActionItem> _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    return [
      QuickActionItem(
        icon: Icons.receipt_long_rounded,
        label: l10n.invoices,
        color: const Color(0xFF667eea),
        gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillsListPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.inventory_2_rounded,
        label: l10n.products,
        color: const Color(0xFFf093fb),
        gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnhancedProductPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.local_shipping_rounded,
        label: l10n.suppliers,
        color: const Color(0xFFFF6B6B),
        gradient: const [Color(0xFFFF6B6B), Color(0xFFee5a24)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnhancedSupplierPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.business_rounded,
        label: l10n.companies,
        color: const Color(0xFF9C27B0),
        gradient: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnhancedCompanyPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.keyboard_return_rounded,
        label: 'P. Return',
        color: const Color(0xFFE65100),
        gradient: const [Color(0xFFE65100), Color(0xFFFF8F00)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseReturnScreen()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.celebration_rounded,
        label: l10n.events,
        color: const Color(0xFF6C63FF),
        gradient: const [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventOrderListPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.request_quote_rounded,
        label: l10n.quotations,
        color: const Color(0xFF1565C0),
        gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuotationListPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.qr_code_2_rounded,
        label: l10n.barcode,
        color: const Color(0xFF00897B),
        gradient: const [Color(0xFF00897B), Color(0xFF004D40)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BarcodeGeneratorPage()),
          );
        },
      ),
      QuickActionItem(
        icon: Icons.people_alt_rounded,
        label: l10n.customers,
        color: const Color(0xFF00ACC1),
        gradient: const [Color(0xFF00ACC1), Color(0xFF0097A7)],
        onTap: () {
          _close();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnhancedCustomerPage()),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Full-screen scrim + overlay when open
        if (_isOpen) _buildOverlay(context),
        // FAB button — bottom-right
        Positioned(right: 16, bottom: 16, child: _buildFAB()),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final actions = _buildActions(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {}, // prevent close when tapping card
                    child: _buildGlassCard(actions),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(List<QuickActionItem> actions) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33FFFFFF),
            Color(0x99FFFFFF),
            Color(0x4D1B4D3E),
            Color(0x99FFFFFF),
            Color(0x33FFFFFF),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xD9FFFFFF),
                  Color(0xBFFFFFFF),
                  Color(0xCCF8FFFC),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(width: 1.5, color: const Color(0xCCFFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x261B4D3E),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: Offset(0, 15),
                ),
                BoxShadow(
                  color: Color(0xCCFFFFFF),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: Offset(-5, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildGrid(actions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.quickActions,
            style: const TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF1B4D3E),
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: _close,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF1B4D3E),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<QuickActionItem> actions) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: actions
          .asMap()
          .entries
          .map((e) => _buildChip(e.value, e.key))
          .toList(),
    );
  }

  Widget _buildChip(QuickActionItem item, int index) {
    return GestureDetector(
      onTap: item.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 350)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white.withValues(alpha: 0.4),
                    item.color.withValues(alpha: 0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: -2,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: item.gradient,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                      letterSpacing: -0.2,
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

  Widget _buildFAB() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.9).animate(_scaleAnimation),
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.5, end: 1.0).animate(animation),
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              _isOpen ? Icons.close_rounded : Icons.dashboard_customize_rounded,
              key: ValueKey(_isOpen),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
