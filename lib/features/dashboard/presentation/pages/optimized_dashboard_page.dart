import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../customer/presentation/pages/enhanced_customer_page.dart';
import '../../../inventory_management/presentation/pages/enhanced_purchase_screen.dart';
import '../../../inventory_management/presentation/pages/purchase_settings_page.dart';
import '../../../inventory_management/presentation/pages/purchase_report_settings_page.dart';
import '../../../inventory_management/presentation/pages/stock_report_settings_page.dart';
import '../../../billing/presentation/pages/billing_page.dart';
import '../../../billing/presentation/pages/bills_list_page.dart';
import '../../../company/presentation/pages/enhanced_company_page.dart';
import '../../../event_order/presentation/pages/event_order_list_page.dart';
import '../../../inventory_management/presentation/pages/barcode_generator_page.dart';
import '../../../inventory_management/presentation/pages/enhanced_product_page.dart';
import '../../../purchase_return/presentation/pages/purchase_return_screen.dart';
import '../../../quotation/presentation/pages/quotation_list_page.dart';
import '../../../supplier/presentation/pages/enhanced_supplier_page.dart';
import '../../../billing/presentation/pages/bill_settings_page.dart';
import '../../../billing/presentation/pages/bill_report_settings_page.dart';
import '../../../availability/presentation/pages/availability_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../../data/repositories/dashboard_offline_repository.dart';
import '../cubit/optimized_dashboard_cubit.dart';
import '../cubit/optimized_dashboard_state.dart';
import '../widgets/shimmer_widgets.dart';
import 'package:c_billing/common_widgets/app_pill_button.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';
import 'flyout_menu.dart';
import 'profile_page.dart';
import 'web_shell.dart';
import '../../../authentication/presentation/pages/change_password_page.dart';
import '../../../expense/presentation/pages/expenses_page.dart';
import '../../../shop/presentation/pages/shop_details_page.dart';
import '../../../settings/presentation/pages/logs_viewer_page.dart';
import '../../../../common_widgets/action_menu.dart';
import '../../../../common_widgets/app_top_bar.dart';
import '../../../../common_widgets/glassy_bottom_nav_bar.dart';
import '../../../../common_widgets/glass_bevel_frame.dart';
import '../../../../common_widgets/range_calendar_sheet.dart';
import '../../../../common_widgets/quick_actions_overlay.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:c_billing/core/ui/glassy_toast.dart';

/// High-performance dashboard page with cache-first loading
/// Renders instantly with cached data, updates smoothly when fresh data arrives
class OptimizedDashboardPage extends StatelessWidget {
  const OptimizedDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = OptimizedDashboardCubit();
        // Initialize async but don't block UI
        cubit.initialize();
        return cubit;
      },
      child: const _OptimizedDashboardView(),
    );
  }
}

class _OptimizedDashboardView extends StatefulWidget {
  const _OptimizedDashboardView();

  @override
  State<_OptimizedDashboardView> createState() =>
      _OptimizedDashboardViewState();
}

class _OptimizedDashboardViewState extends State<_OptimizedDashboardView>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  late SessionManager _sessionManager;
  late AppLocalizations _localizations;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Real data for quick insights (using offline repository for consistency)
  final DashboardOfflineRepository _repository =
      DashboardOfflineRepository.instance;
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _isLoadingExpandableData = false;
  bool _expandableReloadQueued = false;

  // Dashboard refresh subscription
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
    _localizations = AppLocalizations.of(
      LanguageService.instance.currentLanguage,
    );

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);

    // Listen for dashboard refresh events (when data changes in other pages)
    _refreshSubscription = DashboardRefreshService.instance.onRefreshNeeded
        .listen((_) {
          _onDataChanged();
        });

    // Fade animation for content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    if (DesktopCanvas.isDesktopPlatform) {
      WebShell.register((index) {
        if (!mounted) return;
        setState(() => _selectedIndex = index);
      });
    }

    // Load expandable section data
    _loadExpandableSectionData();
  }

  /// Called when data changes in other pages (customers, suppliers, etc.)
  void _onDataChanged() {
    if (mounted) {
      // Cubit handles its own refresh via DashboardRefreshService subscription.
      // Here we only reload expandable section data (quick insights).
      _loadExpandableSectionData();
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _localizations = AppLocalizations.of(
          LanguageService.instance.currentLanguage,
        );
      });
    }
  }

  /// Load data for all expandable sections in parallel
  Future<void> _loadExpandableSectionData() async {
    if (_isLoadingExpandableData) {
      _expandableReloadQueued = true;
      return;
    }

    setState(() => _isLoadingExpandableData = true);

    try {
      final results = await Future.wait([
        _repository.getUpcomingPaymentDues(limit: 5),
        _repository.getTopSellingProducts(limit: 5),
        _repository.getCustomersWithPendingBalance(limit: 5),
        _repository.getRecentPendingBills(limit: 5),
        _repository.getLowStockProducts(limit: 5),
        _repository.getUpcomingEvents(limit: 5),
      ]);

      // Debug logging for Quick Insights data
      debugPrint('[Dashboard] Quick Insights Data Loaded:');
      debugPrint('  - Upcoming Payments: ${results[0].length}');
      debugPrint('  - Top Products: ${results[1].length}');
      debugPrint('  - Pending Payments: ${results[2].length}');
      debugPrint('  - Last Dues: ${results[3].length}');
      debugPrint('  - Low Stock Items: ${results[4].length}');
      debugPrint('  - Upcoming Events: ${results[5].length}');

      if (mounted) {
        setState(() {
          _topProducts = results[1];
          _pendingPayments = results[2];
          _lowStockItems = results[4];
          _upcomingEvents = results[5];
          _isLoadingExpandableData = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[OptimizedDashboardPage] Error loading expandable data: $e');
      debugPrint('[OptimizedDashboardPage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingExpandableData = false);
      }
    } finally {
      if (_expandableReloadQueued && mounted) {
        _expandableReloadQueued = false;
        _loadExpandableSectionData();
      }
    }
  }

  @override
  void dispose() {
    if (DesktopCanvas.isDesktopPlatform) WebShell.register(null);
    _refreshSubscription?.cancel();
    LanguageService.instance.removeListener(_onLanguageChanged);
    _fadeController.dispose();
    super.dispose();
  }

  void _resetSessionTimer() {
    _sessionManager.resetSession();
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return _localizations.dashboard;
      case 1:
        return _localizations.customers;
      case 2:
        return _localizations.billing;
      case 3:
        return _localizations.availability;
      case 4:
        return _localizations.purchase;
      default:
        return 'C-Billing';
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return _localizations.businessOverview;
      case 1:
        return _localizations.manageCustomers;
      case 2:
        return _localizations.generateInvoice;
      case 3:
        return _localizations.stockAvailability;
      case 4:
        return _localizations.trackPurchases;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    _resetSessionTimer();
    if (DesktopCanvas.isDesktopPlatform) return _buildWebShell();
    final isWide = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: Stack(
          children: [
            Column(
              children: [
                // Common header for all tabs
                _buildCommonHeader(),
                // Tab content with optional side nav
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            _buildDesktopSideNav(),
                            Expanded(child: _buildTabContent()),
                          ],
                        )
                      : _buildTabContent(),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: isWide ? null : _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildWebShell() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold(context),
        body: Row(
          children: [
            _buildDesktopSideNav(),
            Expanded(child: _buildWebContent()),
          ],
        ),
      ),
    );
  }

  final List<Widget?> _webPanes = List<Widget?>.filled(WebShell.count, null);

  bool _webChildOpen = false;
  late final WebShellRouteObserver _webRouteObserver = WebShellRouteObserver(
    _onWebRouteChanged,
  );

  void _onWebRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final open = WebShell.navigatorKey.currentState?.canPop() ?? false;
      if (open != _webChildOpen) setState(() => _webChildOpen = open);
    });
  }

  Widget _buildWebContent() {
    _webPanes[_selectedIndex] ??= _createWebPane(_selectedIndex);
    final stack = IndexedStack(
      index: _selectedIndex,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < WebShell.count; i++)
          _webPanes[i] ?? const SizedBox.shrink(),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_webChildOpen) _buildWebScreenTitle(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              stack,
              // Pushed pages sit above the section. The root route stays
              // transparent so the section underneath remains visible.
              IgnorePointer(
                ignoring: !_webChildOpen,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    pageTransitionsTheme: const PageTransitionsTheme(
                      builders: {
                        TargetPlatform.android: InstantPageTransitionsBuilder(),
                        TargetPlatform.iOS: InstantPageTransitionsBuilder(),
                        TargetPlatform.macOS: InstantPageTransitionsBuilder(),
                        TargetPlatform.linux: InstantPageTransitionsBuilder(),
                        TargetPlatform.windows: InstantPageTransitionsBuilder(),
                        TargetPlatform.fuchsia: InstantPageTransitionsBuilder(),
                      },
                    ),
                  ),
                  child: Navigator(
                    key: WebShell.navigatorKey,
                    observers: [_webRouteObserver],
                    onGenerateRoute: (settings) {
                      return PageRouteBuilder<void>(
                        settings: settings,
                        opaque: false,
                        pageBuilder: (_, _, _) => const SizedBox.shrink(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebScreenTitle() {
    final subtitle = _webScreenSubtitle();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _webScreenIcon(),
              color: AppColors.action(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _webScreenTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 13,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedIndex == WebShell.customers)
            AppPillButton(
              label: _localizations.addCustomer,
              icon: Icons.add,
              onPressed: () => CustomerScreenActions.add?.call(),
            ),
        ],
      ),
    );
  }

  String _webScreenTitle() {
    switch (_selectedIndex) {
      case WebShell.dashboard:
        return _localizations.dashboard;
      case WebShell.customers:
        return _localizations.customers;
      case WebShell.billing:
        return _localizations.billing;
      case WebShell.availability:
        return _localizations.availability;
      case WebShell.purchase:
        return _localizations.purchase;
      case WebShell.invoices:
        return _localizations.invoices;
      case WebShell.products:
        return _localizations.products;
      case WebShell.suppliers:
        return _localizations.suppliers;
      case WebShell.companies:
        return _localizations.companies;
      case WebShell.purchaseReturn:
        return _localizations.purchaseReturn;
      case WebShell.events:
        return _localizations.events;
      case WebShell.quotations:
        return _localizations.quotations;
      case WebShell.barcode:
        return _localizations.barcode;
      case WebShell.expenses:
        return 'Expenses';
      case WebShell.shop:
        return _localizations.shopDetails;
      case WebShell.profile:
        return _localizations.myProfile;
      case WebShell.password:
        return _localizations.changePasswordTitle;
      default:
        return 'Billing';
    }
  }

  String _webScreenSubtitle() {
    switch (_selectedIndex) {
      case WebShell.dashboard:
        return _localizations.businessOverview;
      case WebShell.customers:
        return _localizations.manageCustomers;
      case WebShell.billing:
        return _localizations.generateInvoice;
      case WebShell.availability:
        return _localizations.stockAvailability;
      case WebShell.purchase:
        return _localizations.trackPurchases;
      case WebShell.events:
        return _localizations.manageYourEvents;
      default:
        return '';
    }
  }

  IconData _webScreenIcon() {
    switch (_selectedIndex) {
      case WebShell.dashboard:
        return Icons.dashboard_rounded;
      case WebShell.customers:
        return Icons.people_rounded;
      case WebShell.billing:
        return Icons.receipt_long_rounded;
      case WebShell.availability:
        return Icons.event_available_rounded;
      case WebShell.purchase:
        return Icons.shopping_cart_rounded;
      case WebShell.invoices:
        return Icons.receipt_long_outlined;
      case WebShell.products:
        return Icons.inventory_2_rounded;
      case WebShell.suppliers:
        return Icons.local_shipping_rounded;
      case WebShell.companies:
        return Icons.business_rounded;
      case WebShell.purchaseReturn:
        return Icons.keyboard_return_rounded;
      case WebShell.events:
        return Icons.auto_awesome_rounded;
      case WebShell.quotations:
        return Icons.description_outlined;
      case WebShell.barcode:
        return Icons.qr_code_scanner_rounded;
      case WebShell.expenses:
        return Icons.account_balance_wallet_outlined;
      case WebShell.shop:
        return Icons.storefront_outlined;
      case WebShell.profile:
        return Icons.person_rounded;
      case WebShell.password:
        return Icons.key_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  Widget _createWebPane(int index) {
    switch (index) {
      case WebShell.dashboard:
        return _dashboardPane();
      case WebShell.customers:
        return const EnhancedCustomerPage(isEmbedded: true);
      case WebShell.billing:
        return const BillingPage(isEmbedded: true);
      case WebShell.availability:
        return AvailabilityPage(isEmbedded: true);
      case WebShell.purchase:
        return EnhancedPurchaseScreen(isEmbedded: true);
      case WebShell.invoices:
        return const BillsListPage(isEmbedded: true);
      case WebShell.products:
        return const EnhancedProductPage(isEmbedded: true);
      case WebShell.suppliers:
        return const EnhancedSupplierPage(isEmbedded: true);
      case WebShell.companies:
        return const EnhancedCompanyPage(isEmbedded: true);
      case WebShell.purchaseReturn:
        return const PurchaseReturnScreen(isEmbedded: true);
      case WebShell.events:
        return const EventOrderListPage(isEmbedded: true);
      case WebShell.quotations:
        return const QuotationListPage(isEmbedded: true);
      case WebShell.barcode:
        return const BarcodeGeneratorPage(isEmbedded: true);
      case WebShell.expenses:
        return const ExpensesPage(isEmbedded: true);
      case WebShell.shop:
        return const ShopDetailsPage(isEmbedded: true);
      case WebShell.profile:
        return const ProfilePage(isEmbedded: true);
      case WebShell.password:
        return const ChangePasswordPage(isEmbedded: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _dashboardPane() {
    return BlocBuilder<OptimizedDashboardCubit, OptimizedDashboardState>(
      builder: (context, state) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<OptimizedDashboardCubit>().refresh();
              await _loadExpandableSectionData();
            },
            color: AppColors.accent(context),
            child: _buildContent(state),
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // Dashboard tab (index 0)
        _dashboardPane(),
        // Customers tab (index 1)
        const EnhancedCustomerPage(isEmbedded: true),
        // Billing tab (primary - center - index 2)
        const BillingPage(isEmbedded: true),
        // Available tab (index 3)
        AvailabilityPage(isEmbedded: true),
        // Purchase tab (index 4)
        EnhancedPurchaseScreen(isEmbedded: true),
      ],
    );
  }

  /// Desktop/tablet side navigation rail
  Widget _buildDesktopSideNav() {
    final isExpanded = MediaQuery.of(context).size.width >= 1100;
    final shell = DesktopCanvas.isDesktopPlatform;
    final darkWeb = shell && AppColors.isDark(context);
    return Container(
      width: isExpanded ? (shell ? 236 : 220) : 72,
      decoration: BoxDecoration(
        color: darkWeb ? AppTheme.darkSurface : AppColors.card(context),
        border: shell
            ? Border(right: BorderSide(color: AppColors.border(context)))
            : null,
        boxShadow: shell
            ? null
            : [
                BoxShadow(
                  color: AppTheme.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
      ),
      child: Column(
        children: [
          if (shell) _buildWebBrand(isExpanded) else const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (shell) _webNavSection('MAIN', isExpanded),
                _buildSideNavItem(
                  0,
                  Icons.dashboard_rounded,
                  _localizations.dashboard,
                  isExpanded,
                ),
                _buildSideNavItem(
                  1,
                  Icons.people_rounded,
                  _localizations.customers,
                  isExpanded,
                ),
                _buildSideNavItem(
                  2,
                  Icons.receipt_long_rounded,
                  _localizations.billing,
                  isExpanded,
                ),
                _buildSideNavItem(
                  3,
                  Icons.event_available_rounded,
                  _localizations.availability,
                  isExpanded,
                ),
                _buildSideNavItem(
                  4,
                  Icons.shopping_cart_rounded,
                  _localizations.purchase,
                  isExpanded,
                ),
                if (shell) _webNavSection('MANAGE', isExpanded),
                if (shell) ..._webQuickNavItems(isExpanded),
              ],
            ),
          ),
          if (shell) _webNavSection('SYSTEM', isExpanded),
          if (shell) ..._webPageTools(isExpanded, showDivider: !darkWeb),
          _buildSideNavItem(
            -1,
            Icons.menu_rounded,
            'Menu',
            isExpanded,
            onTap: _openFlyoutMenu,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _webNavSection(String label, bool isExpanded) {
    if (!isExpanded) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.mutedText(context),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          fontFamily: 'Literata',
        ),
      ),
    );
  }

  Widget _buildSideNavItem(
    int index,
    IconData icon,
    String label,
    bool isExpanded, {
    VoidCallback? onTap,
  }) {
    final isSelected = index >= 0 && _selectedIndex == index;
    final shell = DesktopCanvas.isDesktopPlatform;
    final darkWeb = shell && AppColors.isDark(context);
    final selectedColor = darkWeb
        ? AppTheme.white
        : (shell ? AppColors.action(context) : AppTheme.white);
    final idleColor = AppColors.secondaryText(context);
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: onTap ?? () => _navigateToPage(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 0,
              vertical: darkWeb ? 10 : 12,
            ),
            decoration: BoxDecoration(
              gradient: isSelected && !shell
                  ? LinearGradient(
                      colors: AppColors.headerGradient(context),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isSelected
                  ? AppTheme.transparent
                  : darkWeb
                  ? AppTheme.darkAction
                  : shell
                  ? AppTheme.paletteFFD7EDE3
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected && !shell
                  ? [
                      BoxShadow(
                        color: AppColors.accentSoft(context, 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isExpanded
                ? Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? selectedColor : idleColor,
                        size: darkWeb ? 20 : 22,
                      ),
                      SizedBox(width: darkWeb ? 12 : 14),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? selectedColor : idleColor,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? (darkWeb ? FontWeight.w600 : FontWeight.w700)
                                : FontWeight.w500,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Tooltip(
                      message: label,
                      child: Icon(
                        icon,
                        color: isSelected ? selectedColor : idleColor,
                        size: darkWeb ? 20 : 24,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
    if (!darkWeb || !isSelected) return item;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        item,
        Positioned(
          left: 0,
          child: Container(
            width: 3,
            height: 22,
            decoration: const BoxDecoration(
              color: AppTheme.darkActionBright,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentSoft(context, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.exit_to_app,
                color: AppColors.accent(context),
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              _localizations.exitApp,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent(context),
              ),
            ),
          ],
        ),
        content: Text(
          _localizations.exitAppConfirm,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            color: AppTheme.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _localizations.cancel,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: AppTheme.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.action(context),
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _localizations.exit,
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      // Clear session and exit the app properly
      SessionManager().endSession();
      SystemNavigator.pop();
    }
  }

  List<Widget> _webPageTools(bool isExpanded, {bool showDivider = true}) {
    final tools = <Widget>[];

    void add(IconData icon, String label, VoidCallback onTap) {
      tools.add(
        _buildSideNavItem(-1, icon, label, isExpanded, onTap: onTap),
      );
    }

    if (_selectedIndex == WebShell.billing ||
        _selectedIndex == WebShell.availability ||
        _selectedIndex == WebShell.purchase) {
      add(Icons.file_download_outlined, 'Download', () {
        if (_selectedIndex == WebShell.billing) {
          _navigateToPage(WebShell.invoices);
        } else if (_selectedIndex == WebShell.availability) {
          AvailabilityScreenActions.download();
        } else {
          PurchaseScreenActions.download();
        }
      });
    }
    if (_selectedIndex == WebShell.billing ||
        _selectedIndex == WebShell.purchase) {
      add(Icons.settings_outlined, _localizations.settings, () async {
        if (_selectedIndex == WebShell.billing) {
          final result = await WebShell.push<bool>(const BillSettingsPage());
          if (result == true && mounted) setState(() {});
        } else {
          await WebShell.push(const PurchaseSettingsPage());
          if (mounted) setState(() {});
        }
      });
    }
    if (_selectedIndex == WebShell.billing ||
        _selectedIndex == WebShell.availability ||
        _selectedIndex == WebShell.purchase) {
      add(Icons.view_column_rounded, _localizations.reportSettings, () async {
        if (_selectedIndex == WebShell.billing) {
          await WebShell.push(const BillReportSettingsPage());
        } else if (_selectedIndex == WebShell.availability) {
          await WebShell.push(const StockReportSettingsPage());
        } else {
          await WebShell.push(const PurchaseReportSettingsPage());
        }
      });
    }
    add(Icons.bug_report_outlined, _localizations.reportIssue, () {
      WebShell.push(const LogsViewerPage());
    });

    if (tools.isEmpty) return const [];
    if (!showDivider) return tools;
    return [
      Divider(height: 16, color: AppColors.border(context)),
      ...tools,
    ];
  }

  Widget _buildWebBrand(bool isExpanded) {
    final darkWeb = AppColors.isDark(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(isExpanded ? 16 : 0, 18, 12, 8),
      child: Row(
        mainAxisAlignment: isExpanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (darkWeb)
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.darkAction,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.white,
                size: 18,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.storefront_rounded,
                  color: AppColors.action(context),
                  size: 28,
                ),
              ),
            ),
          if (isExpanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                darkWeb ? 'C-Billing' : 'Billing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _webQuickNavItems(bool isExpanded) {
    Widget item(int index, IconData icon, String label) {
      return _buildSideNavItem(
        index,
        icon,
        label,
        isExpanded,
        onTap: () => _navigateToPage(index),
      );
    }

    return [
      item(WebShell.invoices, Icons.receipt_long_outlined, _localizations.invoices),
      item(WebShell.products, Icons.inventory_2_rounded, _localizations.products),
      item(WebShell.suppliers, Icons.local_shipping_rounded, _localizations.suppliers),
      item(WebShell.companies, Icons.business_rounded, _localizations.companies),
      item(
        WebShell.purchaseReturn,
        Icons.keyboard_return_rounded,
        _localizations.purchaseReturnShort,
      ),
      item(WebShell.events, Icons.auto_awesome_rounded, _localizations.events),
      item(
        WebShell.quotations,
        Icons.description_outlined,
        _localizations.quotations,
      ),
      item(
        WebShell.barcode,
        Icons.qr_code_scanner_rounded,
        _localizations.barcode,
      ),
    ];
  }

  Widget _buildCommonHeader() {
    return AppTopBar(
      title: _getPageTitle(),
      subtitle: _getPageSubtitle(),
      showBack: false,
      onTitleTap: _openFlyoutMenu,
      leading: GestureDetector(
        onTap: _openFlyoutMenu,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.white.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.business,
                color: AppTheme.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      actions: [
        AppTopBar.action(
          icon: Icons.apps_rounded,
          onTap: () => showQuickActionsSheet(context),
        ),
        _buildHeaderMenu(),
      ],
    );
  }

  Widget _buildHeaderMenu({bool outlined = false}) {
    return ActionMenu(
      outlined: outlined,
      iconColor: AppTheme.white,
      onExpandTap: (_selectedIndex == 2 ||
              _selectedIndex == 3 ||
              _selectedIndex == 4)
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    if (_selectedIndex == 2) {
                      return const BillingPage();
                    }
                    if (_selectedIndex == 3) {
                      return const AvailabilityPage();
                    }
                    return const EnhancedPurchaseScreen();
                  },
                ),
              );
            }
          : null,
      onDownloadTap: (_selectedIndex == 2 ||
              _selectedIndex == 3 ||
              _selectedIndex == 4)
          ? () {
              if (_selectedIndex == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BillsListPage(),
                  ),
                );
              } else if (_selectedIndex == 3) {
                AvailabilityScreenActions.download();
              } else {
                PurchaseScreenActions.download();
              }
            }
          : null,
      onSettingsTap: (_selectedIndex == 2 || _selectedIndex == 4)
          ? () async {
              if (_selectedIndex == 2) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillSettingsPage(),
                  ),
                );
                if (result == true && mounted) setState(() {});
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseSettingsPage(),
                  ),
                );
                if (mounted) setState(() {});
              }
            }
          : null,
      onReportSettingsTap:
          (_selectedIndex == 2 || _selectedIndex == 3 || _selectedIndex == 4)
          ? () async {
              if (_selectedIndex == 2) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillReportSettingsPage(),
                  ),
                );
              } else if (_selectedIndex == 3) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StockReportSettingsPage(),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseReportSettingsPage(),
                  ),
                );
              }
            }
          : null,
      onLanguageTap: _showLanguageDialog,
      onBugReportTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LogsViewerPage(),
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    final currentLanguage = LanguageService.instance.currentLanguage;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.amber900.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: AppTheme.amber900,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _localizations.selectLanguage,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', '🇺🇸', 'English', currentLanguage),
            const SizedBox(height: 8),
            _buildLanguageOption('Hindi', '🇮🇳', 'हिंदी', currentLanguage),
            const SizedBox(height: 8),
            _buildLanguageOption('Marathi', '🇮🇳', 'मराठी', currentLanguage),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String language,
    String flag,
    String nativeName,
    String currentLanguage,
  ) {
    final isSelected = language == currentLanguage;
    return InkWell(
      onTap: () async {
        Navigator.of(context).pop();
        await LanguageService.instance.setLanguage(language);
        if (mounted) {
          GlassyToast.show(
            context,
            '${_localizations.languageChangedTo} $language',
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.amber900.withValues(alpha: 0.1)
              : AppTheme.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.amber900
                : AppTheme.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontFamily: 'Literata',
                      color: isSelected
                          ? AppTheme.amber900
                          : AppTheme.black87,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.amber900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppTheme.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OptimizedDashboardState state) {
    if (DesktopCanvas.isDesktopPlatform) return _buildWebDashboard(state);

    // Show shimmer only when we have absolutely no data
    if (!state.hasData && state is DashboardInitialState) {
      return const DashboardShimmerLoading();
    }

    // Get data (from ready state, error state with cache, or empty)
    final data = state.data ?? DashboardSummary.empty;
    final isRefreshing = state.isRefreshing;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width >= 800
                ? 1000
                : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(state),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: _localizations.salesProfitAnalysis,
                subtitle: _getFilterLabel(state.params),
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 20),
              _buildMetricsRow(data, isRefreshing),
              const SizedBox(height: 16),
              // Profit + Margin: side by side on desktop, stacked on mobile
              if (MediaQuery.of(context).size.width >= 800) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildProfitCard(data, isRefreshing)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMarginCard(data, isRefreshing)),
                  ],
                ),
              ] else ...[
                _buildProfitCard(data, isRefreshing),
                const SizedBox(height: 12),
                _buildMarginCard(data, isRefreshing),
              ],
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: _localizations.inventoryPayments,
                subtitle: _localizations.liveStatus,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 20),
              _buildInventoryCard(data, isRefreshing),
              const SizedBox(height: 28),
              // Quick Insights Section - Glassy Stats
              _buildSectionHeader(
                title: _localizations.quickInsights,
                subtitle: _localizations.atAGlance,
                icon: Icons.insights_outlined,
              ),
              const SizedBox(height: 16),
              // Quick Insights: 2x2 grid on desktop, stacked on mobile
              if (MediaQuery.of(context).size.width >= 800) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassyStatRow(
                        title: _localizations.topProducts,
                        count: _topProducts.length,
                        icon: Icons.star_rounded,
                        gradientColors: const [
                          AppTheme.orange300,
                          AppTheme.orange,
                        ],
                        onTap: () => _showQuickInsightDetail(
                          _localizations.topProducts,
                          _topProducts,
                          'products',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassyStatRow(
                        title: _localizations.pendingPayments,
                        count: _pendingPayments.length,
                        icon: Icons.pending_actions_rounded,
                        gradientColors: const [
                          AppTheme.error,
                          AppTheme.red600,
                        ],
                        onTap: () => _showQuickInsightDetail(
                          _localizations.pendingPayments,
                          _pendingPayments,
                          'pending',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassyStatRow(
                        title: _localizations.lowStockItems,
                        count: _lowStockItems.length,
                        icon: Icons.shopping_cart_rounded,
                        gradientColors: const [
                          AppTheme.teal400,
                          AppTheme.teal600,
                        ],
                        onTap: () => _showQuickInsightDetail(
                          _localizations.lowStockItems,
                          _lowStockItems,
                          'lowstock',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassyStatRow(
                        title: _localizations.upcomingEvents,
                        count: _upcomingEvents.length,
                        icon: Icons.event_rounded,
                        gradientColors: const [
                          AppTheme.cyan,
                          AppTheme.cyan700,
                        ],
                        onTap: () => _showQuickInsightDetail(
                          _localizations.upcomingEvents,
                          _upcomingEvents,
                          'events',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _buildGlassyStatRow(
                  title: _localizations.topProducts,
                  count: _topProducts.length,
                  icon: Icons.star_rounded,
                  gradientColors: const [AppTheme.orange300, AppTheme.orange],
                  onTap: () => _showQuickInsightDetail(
                    _localizations.topProducts,
                    _topProducts,
                    'products',
                  ),
                ),
                const SizedBox(height: 10),
                _buildGlassyStatRow(
                  title: _localizations.pendingPayments,
                  count: _pendingPayments.length,
                  icon: Icons.pending_actions_rounded,
                  gradientColors: const [AppTheme.error, AppTheme.red600],
                  onTap: () => _showQuickInsightDetail(
                    _localizations.pendingPayments,
                    _pendingPayments,
                    'pending',
                  ),
                ),
                const SizedBox(height: 10),
                _buildGlassyStatRow(
                  title: _localizations.lowStockItems,
                  count: _lowStockItems.length,
                  icon: Icons.shopping_cart_rounded,
                  gradientColors: const [AppTheme.teal400, AppTheme.teal600],
                  onTap: () => _showQuickInsightDetail(
                    _localizations.lowStockItems,
                    _lowStockItems,
                    'lowstock',
                  ),
                ),
                const SizedBox(height: 10),
                _buildGlassyStatRow(
                  title: _localizations.upcomingEvents,
                  count: _upcomingEvents.length,
                  icon: Icons.event_rounded,
                  gradientColors: const [AppTheme.cyan, AppTheme.cyan700],
                  onTap: () => _showQuickInsightDetail(
                    _localizations.upcomingEvents,
                    _upcomingEvents,
                    'events',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (state is DashboardErrorState) _buildErrorBanner(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebDashboard(OptimizedDashboardState state) {
    if (!state.hasData && state is DashboardInitialState) {
      return const DashboardShimmerLoading();
    }

    final data = state.data ?? DashboardSummary.empty;
    final isRefreshing = state.isRefreshing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebFilterRow(state),
              const SizedBox(height: 22),
              Text(
                _localizations.salesProfitAnalysis,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildWebMetrics(data, isRefreshing, wide),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildWebProfitCard(data),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _buildWebStockCard(data),
                    ),
                  ],
                )
              else ...[
                _buildWebProfitCard(data),
                const SizedBox(height: 16),
                _buildWebStockCard(data),
              ],
              if (state is DashboardErrorState) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(state),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebFilterRow(OptimizedDashboardState state) {
    final filters = <(DashboardFilter, String)>[
      (DashboardFilter.today, _localizations.today),
      (DashboardFilter.thisWeek, _localizations.thisWeek),
      (DashboardFilter.thisMonth, _localizations.thisMonth),
      (DashboardFilter.thisYear, _localizations.thisYear),
      (DashboardFilter.custom, _localizations.custom),
      (DashboardFilter.all, _localizations.allTime),
    ];

    return Row(
      children: [
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  for (final filter in filters)
                    _buildWebFilterChip(filter.$1, filter.$2, state),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _getFilterLabel(state.params),
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Literata',
          ),
        ),
      ],
    );
  }

  Widget _buildWebFilterChip(
    DashboardFilter filter,
    String label,
    OptimizedDashboardState state,
  ) {
    final isSelected = state.params.filter == filter;
    return GestureDetector(
      onTap: () async {
        if (filter == DashboardFilter.custom) {
          await _showCustomDateRangePicker();
        } else {
          context.read<OptimizedDashboardCubit>().changeFilter(filter);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.action(context) : AppTheme.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.white
                : AppColors.secondaryText(context),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontFamily: 'Literata',
          ),
        ),
      ),
    );
  }

  String _formatWebAmount(double amount) {
    final formatted = NumberFormat.decimalPattern(
      'en_IN',
    ).format(amount.round());
    return amount < 0 ? '-₹${formatted.replaceFirst('-', '')}' : '₹$formatted';
  }

  Widget _buildWebMetrics(
    DashboardSummary data,
    bool isRefreshing,
    bool wide,
  ) {
    final cards = [
      _buildWebMetricCard(
        title: _localizations.totalSales,
        amount: _formatWebAmount(data.totalSales),
        subtitle:
            '${data.totalBillsCount} ${_localizations.bills.toLowerCase()} · ${data.totalItemsSold} ${_localizations.items.toLowerCase()}',
        icon: Icons.show_chart_rounded,
        iconColor: AppTheme.blue600,
        iconFill: AppTheme.blue50,
        isRefreshing: isRefreshing,
      ),
      _buildWebMetricCard(
        title: _localizations.totalPurchase,
        amount: _formatWebAmount(
          data.totalPurchases - data.totalPurchaseReturns,
        ),
        subtitle:
            '${data.purchaseOrders} ${_localizations.orders.toLowerCase()} · ${data.purchaseQty} ${_localizations.qty.toLowerCase()}',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppTheme.orange700,
        iconFill: AppTheme.orange50,
        isRefreshing: isRefreshing,
      ),
      _buildWebMetricCard(
        title: _localizations.returns,
        amount: _formatWebAmount(data.totalReturns + data.totalPurchaseReturns),
        subtitle:
            '${data.totalReturnedItems} ${_localizations.itemsReturned}',
        icon: Icons.undo_rounded,
        iconColor: AppTheme.toneRose,
        iconFill: AppTheme.red100,
        isRefreshing: isRefreshing,
      ),
      _buildWebMetricCard(
        title: _localizations.netSales,
        amount: _formatWebAmount(data.netSales),
        subtitle: _localizations.afterReturnsDeducted,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppTheme.green700,
        iconFill: AppTheme.green50,
        isRefreshing: isRefreshing,
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildWebMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconFill,
    required bool isRefreshing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isRefreshing ? 0.55 : 1,
            child: Text(
              amount,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebProfitCard(DashboardSummary data) {
    final percent = data.profitPercentage.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.action(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.profit >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: AppTheme.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.profit >= 0
                            ? _localizations.netProfit
                            : _localizations.loss,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _formatWebAmount(data.profit.abs()),
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${data.profitPercentage.toStringAsFixed(1)}% ${_localizations.profitMargin.toLowerCase()}',
                  style: TextStyle(
                    color: AppTheme.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppTheme.white.withValues(alpha: 0.2),
                    color: AppTheme.paletteFFD7F6E8,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.profitPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
                    Text(
                      _localizations.margin,
                      style: TextStyle(
                        color: AppTheme.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStockCard(DashboardSummary data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _localizations.stockAndPayments,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
              if (data.lowStockCount > 0)
                GestureDetector(
                  onTap: () => _showQuickInsightDetail(
                    _localizations.lowStockItems,
                    _lowStockItems,
                    'lowstock',
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.orange50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.orange700,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data.lowStockCount} ${_localizations.lowStock.toLowerCase()}',
                          style: const TextStyle(
                            color: AppTheme.orange700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.orange700,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWebStockStat(
                  _localizations.stockValue,
                  _formatWebAmount(data.stockValue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWebStockStat(
                  _localizations.pendingAmount,
                  _formatWebAmount(data.totalPendingAmount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebStockStat(String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.scaffold(context)
            : AppTheme.paletteFFF4F7F4,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(DashboardErrorState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppTheme.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.unableToRefresh,
              style: TextStyle(
                color: AppTheme.red800,
                fontSize: 12,
                fontFamily: 'Literata',
              ),
            ),
          ),
          if (state.canRetry)
            TextButton(
              onPressed: () =>
                  context.read<OptimizedDashboardCubit>().refresh(),
              child: Text(_localizations.retry),
            ),
        ],
      ),
    );
  }

  String _getFilterLabel(DashboardParams params) {
    switch (params.filter) {
      case DashboardFilter.today:
        return _localizations.today;
      case DashboardFilter.thisWeek:
        return _localizations.thisWeek;
      case DashboardFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case DashboardFilter.thisYear:
        return '${_localizations.year} ${DateTime.now().year}';
      case DashboardFilter.custom:
        if (params.startDate != null && params.endDate != null) {
          return '${DateFormat('dd MMM').format(params.startDate!)} - ${DateFormat('dd MMM').format(params.endDate!)}';
        }
        return _localizations.customRange;
      case DashboardFilter.all:
        return _localizations.allTime;
    }
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatCompactAmount(double amount) {
    final formatted = amount.abs().toStringAsFixed(0);
    return amount < 0 ? '-₹$formatted' : '₹$formatted';
  }

  void _openFlyoutMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      // Softer scrim so the glassy flyout reads as translucent.
      barrierColor: AppTheme.black.withValues(alpha: 0.35),
      barrierLabel: 'Flyout Menu',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (context, _) {
          return Theme(
            data: ThemeService.instance.isDark ? AppTheme.dark : AppTheme.light,
            child: const SizedBox.expand(child: FlyoutMenu()),
          );
        },
      ),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.78,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(OptimizedDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: AppColors.accent(context),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              _localizations.filterByPeriod,
              style: TextStyle(
                color: AppColors.accent(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(
                DashboardFilter.today,
                _localizations.today,
                Icons.today_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisWeek,
                _localizations.thisWeek,
                Icons.date_range_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisMonth,
                _localizations.thisMonth,
                Icons.calendar_month_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisYear,
                _localizations.thisYear,
                Icons.calendar_today_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.custom,
                _localizations.custom,
                Icons.edit_calendar_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.all,
                _localizations.allTime,
                Icons.all_inclusive_rounded,
                state,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    DashboardFilter filter,
    String label,
    IconData icon,
    OptimizedDashboardState state,
  ) {
    final isSelected = state.params.filter == filter;
    final unselectedFg = AppColors.accent(context);
    final selectedFill = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () async {
        if (filter == DashboardFilter.custom) {
          await _showCustomDateRangePicker();
        } else {
          context.read<OptimizedDashboardCubit>().changeFilter(filter);
        }
      },
      child: _raisedGlass(
        radius: 14,
        color: isSelected ? selectedFill : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.white : unselectedFg,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.white : unselectedFg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
          ),
        ),
    );
  }

  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final state = context.read<OptimizedDashboardCubit>().state;
    final initialDateRange = DateTimeRange(
      start: state.params.startDate ?? now.subtract(const Duration(days: 30)),
      end: state.params.endDate ?? now,
    );

    final picked = await showAppRangeCalendar(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialDateRange,
    );

    if (picked != null && mounted) {
      context.read<OptimizedDashboardCubit>().setCustomDateRange(
        picked.start,
        picked.end,
      );
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        _raisedGlass(
          radius: 14,
          fill: LinearGradient(colors: AppColors.headerGradient(context)),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: AppTheme.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 13,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow(DashboardSummary data, bool isLoading) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final isDark = AppColors.isDark(context);

    LinearGradient metricGradient(int index, List<Color> lightColors) {
      final colors = isDark ? AppColors.darkMetricGradient(index) : lightColors;
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
    }

    final salesCard = _buildGradientMetricCard(
      title: _localizations.totalSales,
      amount: _formatAmount(data.totalSales),
      subtitle:
          '${_localizations.bills}: ${data.totalBillsCount} • ${_localizations.items}: ${data.totalItemsSold}',
      gradient: metricGradient(0, const [AppTheme.paletteFF667EEA, AppTheme.paletteFF764BA2]),
      icon: Icons.trending_up_rounded,
      isLoading: isLoading,
    );
    final purchaseCard = _buildGradientMetricCard(
      title: _localizations.totalPurchase,
      amount: _formatAmount(data.totalPurchases - data.totalPurchaseReturns),
      subtitle: data.totalPurchaseReturns > 0
          ? '${_localizations.purchaseReturnShort}: ${_formatAmount(data.totalPurchaseReturns)} • ${_localizations.qty}: ${data.purchaseQty}'
          : '${_localizations.orders}: ${data.purchaseOrders} • ${_localizations.qty}: ${data.purchaseQty}',
      gradient: metricGradient(1, const [AppTheme.grey600, AppTheme.grey800]),
      icon: Icons.shopping_bag_rounded,
      isLoading: isLoading,
    );
    final totalAllReturns = data.totalReturns + data.totalPurchaseReturns;
    final returnsCard = _buildGradientMetricCard(
      title: _localizations.returns,
      amount: _formatAmount(totalAllReturns),
      subtitle: data.totalPurchaseReturns > 0
          ? '${_localizations.sales}: ${_formatAmount(data.totalReturns)} • ${_localizations.purchaseReturn}: ${_formatAmount(data.totalPurchaseReturns)}'
          : '${data.totalReturnedItems} ${_localizations.itemsReturned}',
      gradient: metricGradient(2, const [AppTheme.error, AppTheme.red800]),
      icon: Icons.assignment_return_rounded,
      isLoading: isLoading,
    );
    final netSalesCard = _buildGradientMetricCard(
      title: _localizations.netSales,
      amount: _formatAmount(data.netSales),
      subtitle: _localizations.afterReturnsDeducted,
      gradient: metricGradient(3, const [AppTheme.green800, AppTheme.green900]),
      icon: Icons.account_balance_wallet_rounded,
      isLoading: isLoading,
    );

    // Desktop: single row of 4 cards
    if (isWide) {
      return Row(
        children: [
          Expanded(child: salesCard),
          const SizedBox(width: 16),
          Expanded(child: purchaseCard),
          const SizedBox(width: 16),
          Expanded(child: returnsCard),
          const SizedBox(width: 16),
          Expanded(child: netSalesCard),
        ],
      );
    }

    // Mobile: 2x2 grid (original layout)
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: salesCard),
            const SizedBox(width: 16),
            Expanded(child: purchaseCard),
          ],
        ),
        const SizedBox(height: 16),
        // Returns & Net Sales row
        Row(
          children: [
            Expanded(child: returnsCard),
            const SizedBox(width: 16),
            Expanded(child: netSalesCard),
          ],
        ),
      ],
    );
  }

  Widget _raisedGlass({
    required Widget child,
    double radius = 20,
    Gradient? fill,
    Color? color,
  }) {
    final isDark = AppColors.isDark(context);
    final themeColor = Theme.of(context).primaryColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: isDark ? 0.5 : 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: themeColor.withValues(alpha: isDark ? 0.22 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: CustomPaint(
            foregroundPainter: GlassBevelBorderPainter(
              isDark: isDark,
              themeColor: themeColor,
              radius: radius,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                gradient: fill ??
                    (color == null
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.card(context).withValues(
                                alpha: isDark ? 0.72 : 0.96,
                              ),
                              AppColors.card(context).withValues(
                                alpha: isDark ? 0.92 : 0.82,
                              ),
                            ],
                          )
                        : null),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required Gradient gradient,
    required IconData icon,
    bool isLoading = false,
  }) {
    final isDark = AppColors.isDark(context);
    final lg = gradient as LinearGradient;
    return _raisedGlass(
      radius: 22,
      fill: LinearGradient(
        begin: lg.begin,
        end: lg.end,
        colors: isDark
            ? lg.colors
            : [
                lg.colors[0].withValues(alpha: 0.88),
                lg.colors[1].withValues(alpha: 0.72),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.onAccentMuted(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Literata',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppTheme.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  amount,
                  key: ValueKey(amount),
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.onAccentMuted(context),
                  fontSize: 10,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildProfitCard(DashboardSummary data, bool isLoading) {
    final isProfitable = data.profit >= 0;
    final isDark = AppColors.isDark(context);
    return _raisedGlass(
      radius: 22,
      fill: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? AppColors.darkMetricGradient(0)
            : [
                AppColors.action(context).withValues(alpha: 0.92),
                AppTheme.green800.withValues(alpha: 0.78),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfitable
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: AppTheme.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfitable
                                ? _localizations.netProfit
                                : _localizations.loss,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _formatAmount(data.profit.abs()),
                        key: ValueKey(data.profit),
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Literata',
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${data.profitPercentage.toStringAsFixed(1)}% ${_localizations.profitMargin}',
                      style: TextStyle(
                        color: AppColors.onAccentMuted(context),
                        fontSize: 12,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isProfitable
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_down_rounded,
                    color: AppTheme.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildMarginCard(DashboardSummary data, bool isLoading) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? AppTheme.white
        : (data.profit >= 0 ? AppTheme.green800 : AppTheme.red700);
    return _raisedGlass(
      radius: 22,
      fill: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [AppTheme.darkCard, AppTheme.darkSurface]
            : [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.06),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.white.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.trending_up_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizations.margin,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.secondaryText(context)
                            : color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _formatCompactAmount(data.profit),
                        key: ValueKey(data.profit),
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${data.profitPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildInventoryCard(DashboardSummary data, bool isLoading) {
    return _raisedGlass(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localizations.stockAndPayments,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
              ),
              if (data.lowStockCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? AppTheme.white.withValues(alpha: 0.1)
                        : AppTheme.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.isDark(context)
                            ? AppTheme.white
                            : AppTheme.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.lowStockCount} ${_localizations.lowStock}',
                        style: TextStyle(
                          color: AppColors.isDark(context)
                              ? AppTheme.white
                              : AppTheme.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context, 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.stockValue,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 11,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _formatAmount(data.stockValue),
                          key: ValueKey(data.stockValue),
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.chipFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.pendingAmount,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 11,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _formatAmount(data.totalPendingAmount),
                          key: ValueKey(data.totalPendingAmount),
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildBottomNavBar() {
    return GlassyBottomNavBar(
      selectedIndex: _selectedIndex,
      onTap: _navigateToPage,
      items: [
        GlassyNavItem(
          icon: Icons.dashboard_rounded,
          label: _localizations.dashboard,
        ),
        GlassyNavItem(
          icon: Icons.people_rounded,
          label: _localizations.customers,
        ),
        GlassyNavItem(
          icon: Icons.receipt_long_rounded,
          label: _localizations.billing,
          isPrimary: true,
        ),
        GlassyNavItem(
          icon: Icons.event_available_rounded,
          label: _localizations.availability,
        ),
        GlassyNavItem(
          icon: Icons.shopping_cart_rounded,
          label: _localizations.purchase,
        ),
      ],
    );
  }

  void _navigateToPage(int index) {
    _resetSessionTimer();
    if (DesktopCanvas.isDesktopPlatform) WebShell.popToRoot();
    setState(() => _selectedIndex = index);
  }

  // ============ GLASSY QUICK STATS WIDGETS ============

  Widget _buildGlassyStatRow({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final tones = isDark
        ? AppColors.darkMetricGradient(gradientColors.hashCode)
        : gradientColors;
    return GestureDetector(
      onTap: onTap,
      child: _raisedGlass(
        radius: 18,
        fill: isDark
            ? null
            : LinearGradient(
                colors: [
                  AppTheme.white.withValues(alpha: 0.86),
                  tones[0].withValues(alpha: 0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tones,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black.withValues(
                          alpha: isDark ? 0.35 : 0.15,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? AppTheme.white : AppTheme.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.white.withValues(alpha: 0.1) : null,
                    gradient: isDark
                        ? null
                        : LinearGradient(
                            colors: [
                              tones[0].withValues(alpha: 0.15),
                              tones[1].withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.white.withValues(alpha: 0.2)
                          : tones[0].withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.white : tones[0],
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText(context),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _showQuickInsightDetail(
    String title,
    List<Map<String, dynamic>> data,
    String type,
  ) {
    // Get icon and gradient colors based on type
    IconData icon;
    List<Color> gradientColors;

    switch (type) {
      case 'upcoming':
        icon = Icons.schedule_rounded;
        gradientColors = [AppTheme.paletteFF4A90E2, AppTheme.paletteFF7B68EE];
        break;
      case 'products':
        icon = Icons.star_rounded;
        gradientColors = [AppTheme.orange300, AppTheme.orange];
        break;
      case 'pending':
        icon = Icons.pending_actions_rounded;
        gradientColors = [AppTheme.error, AppTheme.red600];
        break;
      case 'dues':
        icon = Icons.receipt_long_rounded;
        gradientColors = [AppTheme.deepPurple300, AppTheme.deepPurple400];
        break;
      case 'lowstock':
        icon = Icons.shopping_cart_rounded;
        gradientColors = [AppTheme.teal400, AppTheme.teal600];
        break;
      default:
        icon = Icons.info_outline;
        gradientColors = [AppTheme.paletteFF667EEA, AppTheme.paletteFF764BA2];
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppTheme.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 60,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: 400,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.action(context).withValues(alpha: 0.65),
                              AppTheme.paletteFF0D2B20.withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with gradient
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.white.withValues(alpha: 0.08),
                                    AppTheme.white.withValues(alpha: 0.03),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon with gradient background
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradientColors,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gradientColors[0].withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      icon,
                                      color: AppTheme.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Title and count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.white,
                                            fontFamily: 'Literata',
                                            letterSpacing: -0.3,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${data.length} ${data.length == 1 ? 'item' : 'items'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontFamily: 'Literata',
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Close button
                                  InkWell(
                                    onTap: () => Navigator.of(context).pop(),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppTheme.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: AppTheme.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Divider
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.transparent,
                                    AppTheme.white.withValues(alpha: 0.2),
                                    AppTheme.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Content
                            Flexible(
                              child: data.isEmpty
                                  ? _buildGlassyEmptyState(gradientColors)
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      itemCount: data.length,
                                      itemBuilder: (context, index) {
                                        final item = data[index];
                                        return _buildGlassyListItem(
                                          item,
                                          type,
                                          index,
                                          gradientColors,
                                        );
                                      },
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
        );
      },
    );
  }

  Widget _buildGlassyEmptyState(List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors[0].withValues(alpha: 0.3),
                  colors[1].withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _localizations.noDataAvailableDashboard,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.white.withValues(alpha: 0.7),
              fontFamily: 'Literata',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyListItem(
    Map<String, dynamic> item,
    String type,
    int index,
    List<Color> colors,
  ) {
    switch (type) {
      case 'upcoming':
        final daysPending = (item['daysPending'] ?? 0) as int;
        final isOverdue = (item['isOverdue'] ?? false) as bool;
        return _buildGlassyUpcomingItem(
          customerName: item['customerName'] ?? 'Unknown',
          amount: ((item['pendingAmount'] ?? 0) as num).toDouble(),
          daysPending: daysPending,
          isOverdue: isOverdue,
          colors: colors,
        );
      case 'pending':
        return _buildGlassyPaymentItem(
          customerName: item['name'] ?? 'Unknown',
          amount: ((item['currentPendingAmount'] ?? 0) as num).toDouble(),
          colors: colors,
        );
      case 'dues':
        return _buildGlassyDuesItem(
          customerName: item['customerName'] ?? 'Unknown',
          amount: ((item['pendingAmount'] ?? 0) as num).toDouble(),
          billDate: _parseDate(item['billDate']),
          colors: colors,
        );
      case 'products':
        return _buildGlassyProductItem(
          rank: index + 1,
          name: item['productName'] ?? item['name'] ?? 'Unknown',
          quantity: ((item['totalQty'] ?? item['quantity'] ?? 0) as num)
              .toDouble(),
          revenue: ((item['totalAmount'] ?? item['revenue'] ?? 0) as num)
              .toDouble(),
          colors: colors,
        );
      case 'lowstock':
        return _buildGlassyLowStockItem(
          name: item['name'] ?? 'Unknown',
          currentStock: (item['currentStock'] ?? item['stock'] ?? 0) as int,
          minStock: (item['minStockLevel'] ?? 10) as int,
          colors: colors,
        );
      case 'events':
        return _buildGlassyEventItem(
          eventName: item['orderName'] ?? 'Unknown Event',
          customerName: item['customerName'] ?? 'Unknown',
          eventDate: _parseDate(item['eventDate']),
          daysUntil: (item['daysUntil'] ?? 0) as int,
          colors: colors,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGlassyUpcomingItem({
    required String customerName,
    required double amount,
    required int daysPending,
    required bool isOverdue,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppTheme.red.withValues(alpha: 0.15)
            : AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppTheme.red.withValues(alpha: 0.3)
              : AppTheme.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOverdue
                    ? [AppTheme.error, AppTheme.red600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  daysPending == 0
                      ? 'Due today'
                      : daysPending == 1
                      ? '1 day overdue'
                      : '$daysPending days overdue',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOverdue
                        ? AppTheme.toneRose
                        : AppTheme.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOverdue
                    ? [AppTheme.error, AppTheme.red600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatAmount(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyPaymentItem({
    required String customerName,
    required double amount,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatAmount(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyDuesItem({
    required String customerName,
    required double amount,
    DateTime? billDate,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (billDate != null)
                  Text(
                    _formatDate(billDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Literata',
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatAmount(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyProductItem({
    required int rank,
    required String name,
    required double quantity,
    required double revenue,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white,
                  fontFamily: 'Literata',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 12,
                      color: AppTheme.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quantity == quantity.truncate() ? quantity.toInt() : quantity.toStringAsFixed(1)} sold',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Literata',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatCompactAmount(revenue),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyLowStockItem({
    required String name,
    required int currentStock,
    required int minStock,
    required List<Color> colors,
  }) {
    final isOutOfStock = currentStock == 0;
    final stockPercent = minStock > 0
        ? (currentStock / minStock * 100).clamp(0, 100)
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? AppTheme.red.withValues(alpha: 0.15)
            : AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock
              ? AppTheme.red.withValues(alpha: 0.3)
              : AppTheme.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOutOfStock
                    ? [AppTheme.error, AppTheme.red600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOutOfStock ? Icons.error_outline : Icons.inventory_2_outlined,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stockPercent / 100,
                    backgroundColor: AppTheme.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      isOutOfStock ? AppTheme.toneRose : colors[0],
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOutOfStock
                    ? [AppTheme.error, AppTheme.red600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOutOfStock ? 'Out' : '$currentStock',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
                fontFamily: 'Literata',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyEventItem({
    required String eventName,
    required String customerName,
    required DateTime? eventDate,
    required int daysUntil,
    required List<Color> colors,
  }) {
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.cyan.withValues(alpha: 0.15)
            : AppTheme.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTheme.cyan.withValues(alpha: 0.3)
              : AppTheme.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday
                    ? [AppTheme.cyan400, AppTheme.cyan600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isToday ? Icons.celebration_rounded : Icons.event_rounded,
              color: AppTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  eventName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.white.withValues(alpha: 0.7),
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [AppTheme.cyan400, AppTheme.cyan600]
                        : colors,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isToday
                      ? 'Today'
                      : isTomorrow
                      ? 'Tomorrow'
                      : '$daysUntil days',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (eventDate != null)
                Text(
                  _formatDate(eventDate),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.white.withValues(alpha: 0.6),
                    fontFamily: 'Literata',
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
