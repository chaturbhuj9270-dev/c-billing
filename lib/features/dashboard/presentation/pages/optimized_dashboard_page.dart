import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../company/presentation/pages/company_page.dart';
import '../../../inventory_management/presentation/pages/purchase_page.dart';
import '../../../inventory_management/presentation/pages/product_management_page.dart';
import '../../../billing/presentation/pages/billing_page.dart';
import '../../../billing/presentation/pages/bills_list_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';
import '../cubit/optimized_dashboard_cubit.dart';
import '../cubit/optimized_dashboard_state.dart';
import '../widgets/shimmer_widgets.dart';
import 'flyout_menu.dart';

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
  int _selectedIndex = 0;
  late SessionManager _sessionManager;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _resetSessionTimer() {
    _sessionManager.resetSession();
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Customers';
      case 2:
        return 'Availability';
      case 3:
        return 'Create Bill';
      case 4:
        return 'Purchases';
      default:
        return 'C-Billing';
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Business Overview';
      case 1:
        return 'Manage Customers';
      case 2:
        return 'Stock Availability';
      case 3:
        return 'Generate Invoice';
      case 4:
        return 'Track Purchases';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    _resetSessionTimer();

    return Scaffold(
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
                // Dashboard tab
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
                // Customers tab
                const CustomerPage(isEmbedded: true),
                // Available tab (coming soon placeholder)
                _buildComingSoonPage('Availability'),
                // Billing tab
                const BillingPage(isEmbedded: true),
                // Purchase tab
                const PurchasePage(isEmbedded: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: GestureDetector(
            onTap: _openFlyoutMenu,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPageTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        _getPageSubtitle(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    final isFromCache = state.isFromCache;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStatsSection(data, isRefreshing),
          const SizedBox(height: 20),
          _buildFilterSection(state),
          if (isFromCache && isRefreshing) ...[
            const SizedBox(height: 8),
            _buildCacheIndicator(),
          ],
          const SizedBox(height: 28),
          _buildSectionHeader(
            title: 'Sales & Profit Analysis',
            subtitle: _getFilterLabel(state.params),
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 20),
          _buildMetricsRow(data, isRefreshing),
          const SizedBox(height: 16),
          _buildProfitCard(data, isRefreshing),
          const SizedBox(height: 28),
          _buildSectionHeader(
            title: 'Inventory & Payments',
            subtitle: 'Live status',
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 20),
          _buildInventoryCard(data, isRefreshing),
          const SizedBox(height: 16),
          _buildPaymentsCard(),
          const SizedBox(height: 24),
          if (state is DashboardErrorState) _buildErrorBanner(state),
        ],
      ),
    );
  }

  Widget _buildCacheIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.amber[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Updating data...',
            style: TextStyle(
              color: Colors.amber[800],
              fontSize: 12,
              fontFamily: 'Literata',
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
              'Unable to refresh data. Showing cached data.',
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
              child: const Text('Retry'),
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
        return 'Year ${DateTime.now().year}';
      case DashboardFilter.custom:
        if (params.startDate != null && params.endDate != null) {
          return '${DateFormat('dd MMM').format(params.startDate!)} - ${DateFormat('dd MMM').format(params.endDate!)}';
        }
        return 'Custom Range';
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
            label: 'Invoices',
            color: const Color(0xFF667eea),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillsListPage()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.people_outline,
            value: '${data.clientsCount}',
            label: 'Customers',
            color: const Color(0xFF4CAF50),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerPage()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.inventory_2_outlined,
            value: '${data.productsCount}',
            label: 'Products',
            color: const Color(0xFFf093fb),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductManagementPage()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.local_shipping_outlined,
            value: '${data.suppliersCount}',
            label: 'Suppliers',
            color: const Color(0xFFFF6B6B),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupplierPage()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.shopping_cart_outlined,
            value: '${data.purchasesCount}',
            label: 'Purchases',
            color: const Color(0xFF00BCD4),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PurchasePage()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickStatItem(
            icon: Icons.business_outlined,
            value: '${data.companiesCount}',
            label: 'Companies',
            color: const Color(0xFF9C27B0),
            isLoading: isLoading,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyPage()),
            ),
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
            const Text(
              'Filter by Period',
              style: TextStyle(
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
                'Today',
                Icons.today_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisWeek,
                'This Week',
                Icons.date_range_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisMonth,
                'This Month',
                Icons.calendar_month_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisYear,
                'This Year',
                Icons.calendar_today_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.custom,
                'Custom',
                Icons.edit_calendar_rounded,
                state,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.all,
                'All Time',
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
    return Row(
      children: [
        Expanded(
          child: _buildGradientMetricCard(
            title: 'Total Sales',
            amount: _formatAmount(data.totalSales),
            subtitle:
                'Bills: ${data.totalBillsCount} • Items: ${data.totalItemsSold}',
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
            title: 'Total Purchase',
            amount: _formatAmount(data.totalPurchases),
            subtitle:
                'Orders: ${data.purchaseOrders} • Qty: ${data.purchaseQty}',
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
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(icon, color: Colors.white, size: 16),
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
                            isProfitable ? 'Profit' : 'Loss',
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
                      '${data.profitPercentage.toStringAsFixed(1)}% margin',
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
              const Text(
                'Stock Overview',
                style: TextStyle(
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
                        'Stock Value',
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
                    color: const Color(0xFF667eea).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Products',
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
                          '${data.productsCount}',
                          key: ValueKey(data.productsCount),
                          style: const TextStyle(
                            color: Color(0xFF667eea),
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
              const Text(
                'Payment Status',
                style: TextStyle(
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
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
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
            'Payment tracking and receivables management will be available in the next update.',
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
              _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
              _buildNavItem(1, Icons.people_rounded, 'Customers'),
              _buildNavItem(2, Icons.event_available_rounded, 'Available'),
              _buildNavItem(3, Icons.receipt_long_rounded, 'Billing'),
              _buildNavItem(4, Icons.shopping_cart_rounded, 'Purchase'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
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

  Widget _buildComingSoonPage(String pageName) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          pageName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Literata',
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              '$pageName Coming Soon',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'This feature is under development and will be available soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Literata',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
