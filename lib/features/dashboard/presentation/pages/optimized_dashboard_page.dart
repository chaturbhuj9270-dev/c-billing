import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../company/presentation/pages/company_page.dart';
import '../../../inventory_management/presentation/pages/purchase_page.dart';
import '../../../inventory_management/presentation/pages/purchase_settings_page.dart';
import '../../../inventory_management/presentation/pages/product_management_page.dart';
import '../../../billing/presentation/pages/billing_page.dart';
import '../../../billing/presentation/pages/bill_settings_page.dart';
import '../../../billing/presentation/pages/bills_list_page.dart';
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
import '../../../purchase_return/presentation/pages/purchase_return_screen.dart';
import '../../../reports/presentation/pages/report_page.dart';
import '../../../../common_widgets/action_menu.dart';

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
  final DashboardOfflineRepository _repository = DashboardOfflineRepository.instance;
  List<Map<String, dynamic>> _upcomingPayments = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _lastDues = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  bool _isLoadingExpandableData = false;
  
  // Dashboard refresh subscription
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
    _localizations = AppLocalizations.of(LanguageService.instance.currentLanguage);

    // Listen for language changes
    LanguageService.instance.addListener(_onLanguageChanged);
    
    // Listen for dashboard refresh events (when data changes in other pages)
    _refreshSubscription = DashboardRefreshService.instance.onRefreshNeeded.listen((_) {
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
      // Refresh the dashboard cubit
      context.read<OptimizedDashboardCubit>().refresh();
      // Also reload expandable section data
      _loadExpandableSectionData();
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _localizations = AppLocalizations.of(LanguageService.instance.currentLanguage);
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
      ]);
      
      if (mounted) {
        setState(() {
          _upcomingPayments = results[0];
          _topProducts = results[1];
          _pendingPayments = results[2];
          _lastDues = results[3];
          _lowStockItems = results[4];
          _isLoadingExpandableData = false;
        });
      }
    } catch (e) {
      print('[OptimizedDashboardPage] Error loading expandable data: $e');
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: Column(
          children: [
            // Common header for all tabs
            _buildCommonHeader(),
            // Tab content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  // Dashboard tab (index 0)
                  BlocBuilder<OptimizedDashboardCubit, OptimizedDashboardState>(
                    builder: (context, state) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: () =>
                              context.read<OptimizedDashboardCubit>().refresh(),
                          color: const Color(0xFF1B4D3E),
                          child: _buildContent(state),
                        ),
                      );
                    },
                  ),
                  // Customers tab (index 1)
                  const CustomerPage(isEmbedded: true),
                  // Billing tab (primary - center - index 2)
                  const BillingPage(isEmbedded: true),
                  // Available tab (index 3)
                  const AvailabilityPage(isEmbedded: true),
                  // Purchase tab (index 4)
                  const PurchasePage(isEmbedded: true),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
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
                color: const Color(0xFF1B4D3E).withOpacity(0.1),
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
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
                              builder: (context) => const PurchaseSettingsPage(),
                            ),
                          );
                          if (mounted) setState(() {});
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
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
                color: const Color(0xFFFF6F00).withOpacity(0.1),
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

  Widget _buildLanguageOption(String language, String flag, String nativeName, String currentLanguage) {
    final isSelected = language == currentLanguage;
    return InkWell(
      onTap: () async {
        Navigator.of(context).pop();
        await LanguageService.instance.setLanguage(language);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_localizations.languageChangedTo} $language'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF6F00).withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF6F00)
                : Colors.grey.withOpacity(0.2),
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontFamily: 'Literata',
                      color: isSelected ? const Color(0xFFFF6F00) : Colors.black87,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStatsSection(data, isRefreshing),
          const SizedBox(height: 20),
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
          _buildProfitCard(data, isRefreshing),
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
          _buildGlassyStatRow(
            title: _localizations.upcomingPayments,
            count: _upcomingPayments.length,
            icon: Icons.schedule_rounded,
            gradientColors: const [Color(0xFF4A90E2), Color(0xFF7B68EE)],
            onTap: () => _showQuickInsightDetail(_localizations.upcomingPayments, _upcomingPayments, 'upcoming'),
          ),
          const SizedBox(height: 10),
          _buildGlassyStatRow(
            title: _localizations.topProducts,
            count: _topProducts.length,
            icon: Icons.star_rounded,
            gradientColors: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
            onTap: () => _showQuickInsightDetail(_localizations.topProducts, _topProducts, 'products'),
          ),
          const SizedBox(height: 10),
          _buildGlassyStatRow(
            title: _localizations.pendingPayments,
            count: _pendingPayments.length,
            icon: Icons.pending_actions_rounded,
            gradientColors: const [Color(0xFFEF5350), Color(0xFFE53935)],
            onTap: () => _showQuickInsightDetail(_localizations.pendingPayments, _pendingPayments, 'pending'),
          ),
          const SizedBox(height: 10),
          _buildGlassyStatRow(
            title: _localizations.lastDues,
            count: _lastDues.length,
            icon: Icons.receipt_long_rounded,
            gradientColors: const [Color(0xFF9575CD), Color(0xFF7E57C2)],
            onTap: () => _showQuickInsightDetail(_localizations.lastDues, _lastDues, 'dues'),
          ),
          const SizedBox(height: 10),
          _buildGlassyStatRow(
            title: _localizations.lowStockItems,
            count: _lowStockItems.length,
            icon: Icons.shopping_cart_rounded,
            gradientColors: const [Color(0xFF26A69A), Color(0xFF00897B)],
            onTap: () => _showQuickInsightDetail(_localizations.lowStockItems, _lowStockItems, 'lowstock'),
          ),
          const SizedBox(height: 24),
          if (state is DashboardErrorState) _buildErrorBanner(state),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(DashboardErrorState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
        return 'Today';
      case DashboardFilter.thisWeek:
        return 'This Week';
      case DashboardFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case DashboardFilter.thisYear:
        return '${_localizations.year} ${DateTime.now().year}';
      case DashboardFilter.custom:
        if (params.startDate != null && params.endDate != null) {
          return '${DateFormat('dd MMM').format(params.startDate!)} - ${DateFormat('dd MMM').format(params.endDate!)}';
        }
        return '${_localizations.custom} Range';
      case DashboardFilter.all:
        return 'All Time';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)} K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  void _openFlyoutMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: 'Flyout Menu',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.expand(child: FlyoutMenu()),
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

  Widget _buildQuickStatsSection(DashboardSummary data, bool isLoading) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildQuickStatItem(
            icon: Icons.receipt_long_outlined,
            value: '${data.invoicesCount}',
            label: _localizations.invoices,
            color: const Color(0xFF667eea),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillsListPage()),
            ).then((_) => _onDataChanged()),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.inventory_2_outlined,
            value: '${data.productsCount}',
            label: _localizations.products,
            color: const Color(0xFFf093fb),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductManagementPage()),
            ).then((_) => _onDataChanged()),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.local_shipping_outlined,
            value: '${data.suppliersCount}',
            label: _localizations.suppliers,
            color: const Color(0xFFFF6B6B),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupplierPage()),
            ).then((_) => _onDataChanged()),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.business_outlined,
            value: '${data.companiesCount}',
            label: _localizations.companies,
            color: const Color(0xFF9C27B0),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyPage()),
            ).then((_) => _onDataChanged()),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.keyboard_return_rounded,
            value: '${data.totalReturnedItems}',
            label: 'P. Return',
            color: const Color(0xFFE65100),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PurchaseReturnScreen()),
            ).then((_) => _onDataChanged()),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.assessment_outlined,
            value: '—',
            label: 'Reports',
            color: const Color(0xFF0277BD),
            isLoading: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ReportPage()),
            ).then((_) => _onDataChanged()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: TextStyle(
                      color: const Color(0xFF1B4D3E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.7),
                    fontSize: 9,
                    fontFamily: 'Literata',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                : const Color(0xFF1B4D3E).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4D3E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                color: const Color(0xFF1B4D3E).withOpacity(0.3),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGradientMetricCard(
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientMetricCard(
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Returns & Net Sales row
        Row(
          children: [
            Expanded(
              child: _buildGradientMetricCard(
                title: _localizations.returns,
                amount: _formatAmount(data.totalReturns),
                subtitle: '${data.totalReturnedItems} items returned',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                ),
                icon: Icons.assignment_return_rounded,
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientMetricCard(
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
              ),
            ),
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
                            isProfitable ? _localizations.netProfit : _localizations.loss,
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

  Widget _buildInventoryCard(DashboardSummary data, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: Colors.orange.withOpacity(0.1),
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
                        '${data.lowStockCount} low stock',
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
                    color: const Color(0xFF1B4D3E).withOpacity(0.05),
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
                        ? const Color(0xFFEF5350).withOpacity(0.05)
                        : const Color(0xFF667eea).withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.08),
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
              _buildNavItem(0, Icons.dashboard_rounded, _localizations.dashboard),
              _buildNavItem(1, Icons.people_rounded, _localizations.customers),
              _buildNavItem(2, Icons.receipt_long_rounded, _localizations.billing, isPrimary: true),
              _buildNavItem(3, Icons.event_available_rounded, _localizations.availability),
              _buildNavItem(4, Icons.shopping_cart_rounded, _localizations.purchase),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isPrimary = false}) {
    final isSelected = _selectedIndex == index;
    
    // Primary Bill tab gets an elevated, always-highlighted design
    if (isPrimary) {
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
              color: isSelected ? null : const Color(0xFF1B4D3E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withOpacity(0.3),
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
                  color: isSelected ? Colors.white : const Color(0xFF1B4D3E),
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1B4D3E),
                    fontSize: 9,
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
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToPage(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1B4D3E).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1B4D3E)
                      : Colors.grey[400],
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gradientColors[0].withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                        color: gradientColors[0].withOpacity(0.25),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[0].withOpacity(0.15),
                        gradientColors[1].withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: gradientColors[0].withOpacity(0.3),
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

  void _showQuickInsightDetail(String title, List<Map<String, dynamic>> data, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4D3E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${data.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B4D3E),
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: data.isEmpty
                    ? _buildEmptyState(_localizations.noDataAvailableDashboard)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return _buildInsightListItem(item, type, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightListItem(Map<String, dynamic> item, String type, int index) {
    switch (type) {
      case 'upcoming':
      case 'pending':
      case 'dues':
        return _buildPaymentListItem(
          customerName: item['customerName'] ?? item['name'] ?? 'Unknown',
          amount: ((item['pendingAmount'] ?? item['currentPendingAmount'] ?? item['pendingBalance'] ?? 0) as num).toDouble(),
          dueDate: _parseDate(item['dueDate'] ?? item['billDate']),
          isPending: type != 'dues',
        );
      case 'products':
        return _buildProductRankItem(
          rank: index + 1,
          name: item['name'] ?? 'Unknown',
          quantity: (item['quantity'] ?? 0) as int,
          revenue: ((item['revenue'] ?? 0) as num).toDouble(),
        );
      case 'lowstock':
        return _buildLowStockItem(
          name: item['name'] ?? 'Unknown',
          currentStock: (item['stock'] ?? 0) as int,
          minStock: 10,
        );
      default:
        return const SizedBox.shrink();
    }
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

  Widget _buildPaymentListItem({
    required String customerName,
    required double amount,
    DateTime? dueDate,
    required bool isPending,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPending ? Icons.schedule : Icons.check_circle_outline,
              color: isPending ? Colors.orange : Colors.green,
              size: 18,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                ),
                if (dueDate != null)
                  Text(
                    'Due: ${_formatDate(dueDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'Literata',
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPending ? Colors.orange[700] : Colors.green[700],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRankItem({
    required int rank,
    required String name,
    required int quantity,
    required double revenue,
  }) {
    final medalColors = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];
    final showMedal = rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showMedal)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: medalColors[rank - 1].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: medalColors[rank - 1],
                size: 16,
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontFamily: 'Literata',
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$quantity units sold',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(revenue)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4D3E),
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockItem({
    required String name,
    required int currentStock,
    required int minStock,
  }) {
    final isOutOfStock = currentStock == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOutOfStock
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOutOfStock ? Icons.error_outline : Icons.warning_amber_rounded,
              color: isOutOfStock ? Colors.red : Colors.orange,
              size: 18,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOutOfStock ? _localizations.outOfStockAlert : '${_localizations.onlyLeftInStock} $currentStock',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOutOfStock ? Colors.red : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to order/restock
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _localizations.order,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4D3E),
                fontFamily: 'Literata',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
