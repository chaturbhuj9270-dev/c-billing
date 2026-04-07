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
import 'flyout_menu.dart';
import '../../../settings/presentation/pages/logs_viewer_page.dart';
import '../../../../common_widgets/action_menu.dart';
import '../../../../common_widgets/quick_actions_overlay.dart';
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
  List<Map<String, dynamic>> _upcomingPayments = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _lastDues = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _isLoadingExpandableData = false;

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
    if (_isLoadingExpandableData) return;

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
      print('[Dashboard] Quick Insights Data Loaded:');
      print('  - Upcoming Payments: ${results[0].length}');
      print('  - Top Products: ${results[1].length}');
      print('  - Pending Payments: ${results[2].length}');
      print('  - Last Dues: ${results[3].length}');
      print('  - Low Stock Items: ${results[4].length}');
      print('  - Upcoming Events: ${results[5].length}');

      if (mounted) {
        setState(() {
          _upcomingPayments = results[0];
          _topProducts = results[1];
          _pendingPayments = results[2];
          _lastDues = results[3];
          _lowStockItems = results[4];
          _upcomingEvents = results[5];
          _isLoadingExpandableData = false;
        });
      }
    } catch (e, stackTrace) {
      print('[OptimizedDashboardPage] Error loading expandable data: $e');
      print('[OptimizedDashboardPage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingExpandableData = false);
      }
    }
  }

  @override
  void dispose() {
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
    final isWide = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
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
            // Global Quick Actions FAB overlay
            const Positioned.fill(child: GlobalQuickActionsFAB()),
          ],
        ),
        bottomNavigationBar: isWide ? null : _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildTabContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // Dashboard tab (index 0)
        BlocBuilder<OptimizedDashboardCubit, OptimizedDashboardState>(
          builder: (context, state) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<OptimizedDashboardCubit>().refresh();
                  await _loadExpandableSectionData();
                },
                color: const Color(0xFF1B4D3E),
                child: _buildContent(state),
              ),
            );
          },
        ),
        // Customers tab (index 1)
        const EnhancedCustomerPage(isEmbedded: true),
        // Billing tab (primary - center - index 2)
        const BillingPage(isEmbedded: true),
        // Available tab (index 3)
        const AvailabilityPage(isEmbedded: true),
        // Purchase tab (index 4)
        const EnhancedPurchaseScreen(isEmbedded: true),
      ],
    );
  }

  /// Desktop/tablet side navigation rail
  Widget _buildDesktopSideNav() {
    final isExpanded = MediaQuery.of(context).size.width >= 1100;
    return Container(
      width: isExpanded ? 220 : 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
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
          const Spacer(),
          // Flyout menu trigger at bottom
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

  Widget _buildSideNavItem(
    int index,
    IconData icon,
    String label,
    bool isExpanded, {
    VoidCallback? onTap,
  }) {
    final isSelected = index >= 0 && _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _navigateToPage(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
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
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
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
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
          ),
        ),
      ),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.exit_to_app,
                color: Color(0xFF1B4D3E),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _localizations.exitApp,
              style: const TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        content: Text(
          _localizations.exitAppConfirm,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _localizations.cancel,
              style: const TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _localizations.exit,
              style: const TextStyle(
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

  Widget _buildCommonHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: _openFlyoutMenu,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openFlyoutMenu,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPageTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        _getPageSubtitle(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Menu (Settings, Language, Bug Report) - Three dots menu
              ActionMenu(
                menuColor: const Color(0xFF1B4D3E),
                iconColor: Colors.white,
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
                              builder: (context) =>
                                  const PurchaseSettingsPage(),
                            ),
                          );
                          if (mounted) setState(() {});
                        }
                      }
                    : null,
                onReportSettingsTap:
                    (_selectedIndex == 2 ||
                        _selectedIndex == 3 ||
                        _selectedIndex == 4)
                    ? () async {
                        if (_selectedIndex == 2) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BillReportSettingsPage(),
                            ),
                          );
                        } else if (_selectedIndex == 3) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StockReportSettingsPage(),
                            ),
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PurchaseReportSettingsPage(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Premium header action button with consistent glassmorphic styling
  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
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
                color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: Color(0xFFFF6F00),
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
              ? const Color(0xFFFF6F00).withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6F00)
                : Colors.grey.withValues(alpha: 0.2),
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
                          ? const Color(0xFFFF6F00)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
                  color: Color(0xFFFF6F00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OptimizedDashboardState state) {
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
                          Color(0xFFFFB74D),
                          Color(0xFFFF9800),
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
                          Color(0xFFEF5350),
                          Color(0xFFE53935),
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
                          Color(0xFF26A69A),
                          Color(0xFF00897B),
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
                          Color(0xFF00BCD4),
                          Color(0xFF0097A7),
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
                  gradientColors: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
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
                  gradientColors: const [Color(0xFFEF5350), Color(0xFFE53935)],
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
                  gradientColors: const [Color(0xFF26A69A), Color(0xFF00897B)],
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
                  gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
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

  Widget _buildErrorBanner(DashboardErrorState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _localizations.unableToRefresh,
              style: TextStyle(
                color: Colors.red[800],
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
      barrierColor: Colors.black54,
      barrierLabel: 'Flyout Menu',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const SizedBox.expand(child: FlyoutMenu()),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
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
            const Icon(
              Icons.filter_list_rounded,
              color: Color(0xFF1B4D3E),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _localizations.filterByPeriod,
              style: const TextStyle(
                color: Color(0xFF1B4D3E),
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
    return GestureDetector(
      onTap: () async {
        if (filter == DashboardFilter.custom) {
          await _showCustomDateRangePicker();
        } else {
          context.read<OptimizedDashboardCubit>().changeFilter(filter);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFF1B4D3E).withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF1B4D3E),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1B4D3E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
          ],
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

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4D3E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1B4D3E),
            ),
          ),
          child: child!,
        );
      },
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
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

    final salesCard = _buildGradientMetricCard(
      title: _localizations.totalSales,
      amount: _formatAmount(data.totalSales),
      subtitle:
          '${_localizations.bills}: ${data.totalBillsCount} • ${_localizations.items}: ${data.totalItemsSold}',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      icon: Icons.trending_up_rounded,
      isLoading: isLoading,
    );
    final purchaseCard = _buildGradientMetricCard(
      title: _localizations.totalPurchase,
      amount: _formatAmount(data.totalPurchases),
      subtitle:
          '${_localizations.orders}: ${data.purchaseOrders} • ${_localizations.qty}: ${data.purchaseQty}',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF757575), Color(0xFF424242)],
      ),
      icon: Icons.shopping_bag_rounded,
      isLoading: isLoading,
    );
    final returnsCard = _buildGradientMetricCard(
      title: _localizations.returns,
      amount: _formatAmount(data.totalReturns),
      subtitle: '${data.totalReturnedItems} ${_localizations.itemsReturned}',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEF5350), Color(0xFFC62828)],
      ),
      icon: Icons.assignment_return_rounded,
      isLoading: isLoading,
    );
    final netSalesCard = _buildGradientMetricCard(
      title: _localizations.netSales,
      amount: _formatAmount(data.netSales),
      subtitle: _localizations.afterReturnsDeducted,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ),
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

  Widget _buildGradientMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required Gradient gradient,
    required IconData icon,
    bool isLoading = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: (gradient as LinearGradient).begin,
              end: gradient.end,
              colors: [
                gradient.colors[0].withValues(alpha: 0.7),
                gradient.colors[1].withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Literata',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
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
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Literata',
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitCard(DashboardSummary data, bool isLoading) {
    final isProfitable = data.profit >= 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isProfitable
                  ? [
                      const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                      const Color(0xFF2E7D32).withValues(alpha: 0.7),
                    ]
                  : [
                      const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                      const Color(0xFF2E7D32).withValues(alpha: 0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfitable
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfitable
                                ? _localizations.netProfit
                                : _localizations.loss,
                            style: const TextStyle(
                              color: Colors.white,
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
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Literata',
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.profitPercentage.toStringAsFixed(1)}% ${_localizations.profitMargin}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isProfitable
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_down_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarginCard(DashboardSummary data, bool isLoading) {
    final color = data.profit >= 0
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
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
                        color: color,
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
                          color: color,
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
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(DashboardSummary data, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localizations.stockAndPayments,
                style: const TextStyle(
                  color: Color(0xFF1B4D3E),
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.lowStockCount} ${_localizations.lowStock}',
                        style: const TextStyle(
                          color: Colors.orange,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.stockValue,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                          style: const TextStyle(
                            color: Color(0xFF1B4D3E),
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
                    color: data.totalPendingAmount > 0
                        ? const Color(0xFFEF5350).withValues(alpha: 0.05)
                        : const Color(0xFF667eea).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizations.pendingAmount,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                            color: data.totalPendingAmount > 0
                                ? const Color(0xFFEF5350)
                                : const Color(0xFF667eea),
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
    );
  }

  Widget _buildPaymentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localizations.paymentStatus,
                style: const TextStyle(
                  color: Color(0xFF1B4D3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _localizations.comingSoon,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _localizations.paymentTrackingMessage,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                0,
                Icons.dashboard_rounded,
                _localizations.dashboard,
              ),
              _buildNavItem(1, Icons.people_rounded, _localizations.customers),
              _buildNavItem(
                2,
                Icons.receipt_long_rounded,
                _localizations.billing,
                isPrimary: true,
              ),
              _buildNavItem(
                3,
                Icons.event_available_rounded,
                _localizations.availability,
              ),
              _buildNavItem(
                4,
                Icons.shopping_cart_rounded,
                _localizations.purchase,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool isPrimary = false,
  }) {
    final isSelected = _selectedIndex == index;

    // All tabs now get the same elevated, highlighted design when selected
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToPage(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1B4D3E), Color(0xFF2E7D5B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isPrimary
                      ? const Color(0xFF1B4D3E).withValues(alpha: 0.08)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isPrimary ? const Color(0xFF1B4D3E) : Colors.grey[600]),
                size: isSelected ? 22 : 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isPrimary
                            ? const Color(0xFF1B4D3E)
                            : Colors.grey[600]),
                  fontSize: isSelected ? 9 : 8,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    _resetSessionTimer();
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gradientColors[0].withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1B4D3E),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                // Count badge on right
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[0].withValues(alpha: 0.15),
                        gradientColors[1].withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: gradientColors[0],
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow icon
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
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
        gradientColors = [const Color(0xFF4A90E2), const Color(0xFF7B68EE)];
        break;
      case 'products':
        icon = Icons.star_rounded;
        gradientColors = [const Color(0xFFFFB74D), const Color(0xFFFF9800)];
        break;
      case 'pending':
        icon = Icons.pending_actions_rounded;
        gradientColors = [const Color(0xFFEF5350), const Color(0xFFE53935)];
        break;
      case 'dues':
        icon = Icons.receipt_long_rounded;
        gradientColors = [const Color(0xFF9575CD), const Color(0xFF7E57C2)];
        break;
      case 'lowstock':
        icon = Icons.shopping_cart_rounded;
        gradientColors = [const Color(0xFF26A69A), const Color(0xFF00897B)];
        break;
      default:
        icon = Icons.info_outline;
        gradientColors = [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
                              const Color(0xFF1B4D3E).withValues(alpha: 0.65),
                              const Color(0xFF0D2B20).withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
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
                                    Colors.white.withValues(alpha: 0.08),
                                    Colors.white.withValues(alpha: 0.03),
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
                                      color: Colors.white,
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
                                            color: Colors.white,
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
                                            color: Colors.white.withValues(
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
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
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
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.2),
                                    Colors.transparent,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _localizations.noDataAvailableDashboard,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
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
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
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
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
              color: Colors.white,
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
                    color: Colors.white,
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
                        ? Colors.red[300]
                        : Colors.white.withValues(alpha: 0.6),
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
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatAmount(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
              color: Colors.white,
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
                color: Colors.white,
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
                color: Colors.white,
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
              color: Colors.white,
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
                    color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.6),
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
                color: Colors.white,
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                  color: Colors.white,
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
                    color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quantity == quantity.truncate() ? quantity.toInt() : quantity.toStringAsFixed(1)} sold',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
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
                color: Colors.white,
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
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
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
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOutOfStock ? Icons.error_outline : Icons.inventory_2_outlined,
              color: Colors.white,
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
                    color: Colors.white,
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
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      isOutOfStock ? Colors.red[300]! : colors[0],
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
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOutOfStock ? 'Out' : '$currentStock',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
            ? Colors.cyan.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? Colors.cyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
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
                    ? [Colors.cyan.shade400, Colors.cyan.shade600]
                    : colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isToday ? Icons.celebration_rounded : Icons.event_rounded,
              color: Colors.white,
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
                    color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.7),
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
                        ? [Colors.cyan.shade400, Colors.cyan.shade600]
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
                    color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.6),
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
