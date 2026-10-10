import 'package:flutter/material.dart';
import 'package:c_billing/core/theme/app_theme.dart';
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

/// Opens the quick-actions sheet used by billing and purchase.
Future<void> showQuickActionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return QuickActionsPanel(
        actions: buildQuickActionItems(
          context,
          beforeNavigate: () => Navigator.pop(sheetContext),
        ),
      );
    },
  );
}

List<QuickActionItem> buildQuickActionItems(
  BuildContext context, {
  VoidCallback? beforeNavigate,
}) {
  final l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);

  void open(Widget page) {
    beforeNavigate?.call();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  return [
    QuickActionItem(
      icon: Icons.receipt_long_rounded,
      label: l10n.invoices,
      color: const Color(0xFF7C8CFF),
      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
      onTap: () => open(const BillsListPage()),
    ),
    QuickActionItem(
      icon: Icons.inventory_2_rounded,
      label: l10n.products,
      color: const Color(0xFFC084FC),
      gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
      onTap: () => open(const EnhancedProductPage()),
    ),
    QuickActionItem(
      icon: Icons.local_shipping_rounded,
      label: l10n.suppliers,
      color: const Color(0xFFFF8A65),
      gradient: const [Color(0xFFFF6B6B), Color(0xFFee5a24)],
      onTap: () => open(const EnhancedSupplierPage()),
    ),
    QuickActionItem(
      icon: Icons.business_rounded,
      label: l10n.companies,
      color: const Color(0xFFB388FF),
      gradient: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
      onTap: () => open(const EnhancedCompanyPage()),
    ),
    QuickActionItem(
      icon: Icons.keyboard_return_rounded,
      label: l10n.purchaseReturnShort,
      color: const Color(0xFFFFB74D),
      gradient: const [Color(0xFFE65100), Color(0xFFFF8F00)],
      onTap: () => open(const PurchaseReturnScreen()),
    ),
    QuickActionItem(
      icon: Icons.auto_awesome_rounded,
      label: l10n.events,
      color: const Color(0xFFB39DDB),
      gradient: const [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
      onTap: () => open(const EventOrderListPage()),
    ),
    QuickActionItem(
      icon: Icons.description_outlined,
      label: l10n.quotations,
      color: const Color(0xFF64B5F6),
      gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
      onTap: () => open(const QuotationListPage()),
    ),
    QuickActionItem(
      icon: Icons.qr_code_scanner_rounded,
      label: l10n.barcode,
      color: const Color(0xFF69F0AE),
      gradient: const [Color(0xFF00897B), Color(0xFF004D40)],
      onTap: () => open(const BarcodeGeneratorPage()),
    ),
    QuickActionItem(
      icon: Icons.people_alt_rounded,
      label: l10n.customers,
      color: const Color(0xFF4DD0E1),
      gradient: const [Color(0xFF00ACC1), Color(0xFF0097A7)],
      onTap: () => open(const EnhancedCustomerPage()),
    ),
  ];
}

/// Bottom sheet grid: "Quick actions" / "Jump to any section".
class QuickActionsPanel extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActionsPanel({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF161A18)
            : AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText(context).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.quickActions,
            style: TextStyle(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Jump to any section',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 13,
              color: AppColors.mutedText(context),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) => _ActionTile(item: actions[index]),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final QuickActionItem item;

  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.isDark(context)
          ? const Color(0xFF1E2422)
          : AppColors.chipFill(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Literata',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A global Quick Actions FAB + overlay that can be placed in any Scaffold.
///
/// Usage: Add [GlobalQuickActionsFAB] to a Stack on top of your page content.
/// It manages its own open/close state internally.
class GlobalQuickActionsFAB extends StatefulWidget {
  /// Distance from the bottom of the stack. Raise this when a floating
  /// bottom nav bar overlays the body (e.g. with [Scaffold.extendBody]).
  final double bottomOffset;

  const GlobalQuickActionsFAB({super.key, this.bottomOffset = 16});

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: QuickActionsPanel(
                    actions: buildQuickActionItems(
                      context,
                      beforeNavigate: _close,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: widget.bottomOffset,
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 0.9).animate(_scaleAnimation),
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  _isOpen ? Icons.close_rounded : Icons.apps_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
