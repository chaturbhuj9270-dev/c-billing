import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../company/presentation/pages/company_page.dart';
import '../../../inventory_management/presentation/pages/enhanced_purchase_screen.dart';
import '../../../inventory_management/presentation/pages/product_management_page.dart';
import '../../../billing/presentation/pages/billing_page.dart';
import '../../../billing/presentation/pages/bills_list_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../common_widgets/welcome_card.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/repositories/dashboard_offline_repository.dart';
import 'flyout_menu.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit()..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late SessionManager _sessionManager;

  // Main animation controller
  late AnimationController _mainAnimController;
  late Animation<double> _fadeAnimation;

  // Staggered animations for cards
  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _scaleAnimations;

  // Welcome snackbar animation
  AnimationController? _welcomeController;
  Animation<Offset>? _welcomeSlideAnimation;
  Animation<double>? _welcomeFadeAnimation;
  bool _showWelcome = true;

  // Expandable section states
  bool _isUpcomingPaymentsExpanded = false;
  bool _isTopProductsExpanded = false;
  bool _isPendingPaymentsExpanded = false;
  bool _isLastDuesExpanded = false;
  bool _isLowStockExpanded = false;

  // Real data for expandable sections - using offline repository for instant loading
  final DashboardOfflineRepository _repository = DashboardOfflineRepository.instance;
  List<Map<String, dynamic>> _upcomingPayments = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _lastDues = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  bool _isLoadingExpandableData = false;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();

    // Main fade animation
    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.easeOut,
    );

    // Staggered card animations
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimations = List.generate(6, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start,
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _scaleAnimations = List.generate(6, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start,
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    // Welcome snackbar animation
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _welcomeSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _welcomeController!,
            curve: Curves.easeOutCubic,
          ),
        );
    _welcomeFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _welcomeController!, curve: Curves.easeOut),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _mainAnimController.forward();
        _staggerController.forward();
      }
    });

    // Show welcome snackbar after a delay, then hide after 5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _welcomeController?.forward();
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _welcomeController?.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showWelcome = false;
                });
              }
            });
          }
        });
      }
    });

    // Load expandable section data
    _loadExpandableSectionData();
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
      print('[DashboardPage] Error loading expandable data: $e');
      if (mounted) {
        setState(() => _isLoadingExpandableData = false);
      }
    }
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _staggerController.dispose();
    _welcomeController?.dispose();
    super.dispose();
  }

  String _getFilterLabel(DashboardState state) {
    switch (state.filter) {
      case DashboardFilter.today:
        return 'Today';
      case DashboardFilter.thisWeek:
        return 'This Week';
      case DashboardFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case DashboardFilter.thisYear:
        return 'Year ${DateTime.now().year}';
      case DashboardFilter.custom:
        if (state.customStartDate != null && state.customEndDate != null) {
          return '${DateFormat('dd MMM').format(state.customStartDate!)} - ${DateFormat('dd MMM').format(state.customEndDate!)}';
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

  void _resetSessionTimer() {
    _sessionManager.resetSession();
  }

  void _navigateToPage(int index) {
    _resetSessionTimer();
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CustomerPage())).then((_) {
          if (mounted) {
            context.read<DashboardCubit>().refresh();
            _loadExpandableSectionData();
          }
        });
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability page coming soon')),
        );
        break;
      case 3:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BillingPage())).then((_) {
          if (mounted) {
            context.read<DashboardCubit>().refresh();
            _loadExpandableSectionData();
          }
        });
        break;
      case 4:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const EnhancedPurchaseScreen())).then((_) {
          if (mounted) {
            context.read<DashboardCubit>().refresh();
            _loadExpandableSectionData();
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _resetSessionTimer();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 0,
                  collapsedHeight: 100,
                  pinned: true,
                  floating: false,
                  backgroundColor: const Color(0xFF1B4D3E),
                  automaticallyImplyLeading: false,
                  flexibleSpace: _buildGradientHeader(),
                ),
              ];
            },
            body: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                // Get data from state
                final data = _getDataFromState(state);
                final isLoading = state is DashboardLoading;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: () => context.read<DashboardCubit>().refresh(),
                    color: const Color(0xFF1B4D3E),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickStatsSection(data, isLoading),
                          const SizedBox(height: 20),
                          _buildFilterSection(state),
                          const SizedBox(height: 28),
                          _buildAnimatedCard(
                            index: 0,
                            child: _buildSectionHeader(
                              title: 'Sales & Profit Analysis',
                              subtitle: _getFilterLabel(state),
                              icon: Icons.analytics_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAnimatedCard(
                                  index: 1,
                                  child: _buildGradientMetricCard(
                                    title: 'Total Sales',
                                    amount: _formatAmount(data.totalSales),
                                    subtitle:
                                        'Bills: ${data.totalBillsCount} • Items: ${data.totalItemsSold}',
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    ),
                                    icon: Icons.trending_up_rounded,
                                    isLoading: isLoading,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAnimatedCard(
                                  index: 2,
                                  child: _buildGradientMetricCard(
                                    title: 'Total Purchase',
                                    amount: _formatAmount(data.totalPurchases),
                                    subtitle:
                                        'Orders: ${data.purchaseOrders} • Qty: ${data.purchaseQty}',
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF757575),
                                        Color(0xFF424242),
                                      ],
                                    ),
                                    icon: Icons.shopping_bag_rounded,
                                    isLoading: isLoading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedCard(
                            index: 3,
                            child: _buildProfitCard(data, isLoading),
                          ),
                          const SizedBox(height: 28),
                          _buildAnimatedCard(
                            index: 4,
                            child: _buildSectionHeader(
                              title: 'Inventory & Payments',
                              subtitle: 'Live status',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildAnimatedCard(
                            index: 5,
                            child: _buildInventoryCard(data, isLoading),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedCard(
                            index: 5,
                            child: _buildPaymentsCard(),
                          ),
                          const SizedBox(height: 28),
                          // Expandable Insights Section
                          _buildAnimatedCard(
                            index: 5,
                            child: _buildSectionHeader(
                              title: 'Quick Insights',
                              subtitle: 'Tap to expand',
                              icon: Icons.insights_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildExpandableCard(
                            title: 'Upcoming Payments',
                            subtitle: 'Due in next 7 days',
                            icon: Icons.schedule_rounded,
                            iconGradient: const [
                              Color(0xFF4A90E2),
                              Color(0xFF7B68EE),
                            ],
                            isExpanded: _isUpcomingPaymentsExpanded,
                            onTap: () => setState(
                              () => _isUpcomingPaymentsExpanded =
                                  !_isUpcomingPaymentsExpanded,
                            ),
                            expandedContent: _buildUpcomingPaymentsContent(),
                          ),
                          const SizedBox(height: 12),
                          _buildExpandableCard(
                            title: 'Top Performing Products',
                            subtitle: 'Best sellers this month',
                            icon: Icons.star_rounded,
                            iconGradient: const [
                              Color(0xFFFFB74D),
                              Color(0xFFFF9800),
                            ],
                            isExpanded: _isTopProductsExpanded,
                            onTap: () => setState(
                              () => _isTopProductsExpanded =
                                  !_isTopProductsExpanded,
                            ),
                            expandedContent: _buildTopProductsContent(data),
                          ),
                          const SizedBox(height: 12),
                          _buildExpandableCard(
                            title: 'Pending Payments',
                            subtitle: 'Awaiting collection',
                            icon: Icons.pending_actions_rounded,
                            iconGradient: const [
                              Color(0xFFEF5350),
                              Color(0xFFE53935),
                            ],
                            isExpanded: _isPendingPaymentsExpanded,
                            onTap: () => setState(
                              () => _isPendingPaymentsExpanded =
                                  !_isPendingPaymentsExpanded,
                            ),
                            expandedContent: _buildPendingPaymentsContent(),
                          ),
                          const SizedBox(height: 12),
                          _buildExpandableCard(
                            title: 'Last Dues',
                            subtitle: 'Recent outstanding amounts',
                            icon: Icons.receipt_long_rounded,
                            iconGradient: const [
                              Color(0xFF9575CD),
                              Color(0xFF7E57C2),
                            ],
                            isExpanded: _isLastDuesExpanded,
                            onTap: () => setState(
                              () => _isLastDuesExpanded = !_isLastDuesExpanded,
                            ),
                            expandedContent: _buildLastDuesContent(),
                          ),
                          const SizedBox(height: 12),
                          _buildExpandableCard(
                            title: 'Order Now - Low Stock',
                            subtitle:
                                '${data.lowStockCount} items need reorder',
                            icon: Icons.shopping_cart_rounded,
                            iconGradient: const [
                              Color(0xFF26A69A),
                              Color(0xFF00897B),
                            ],
                            isExpanded: _isLowStockExpanded,
                            onTap: () => setState(
                              () => _isLowStockExpanded = !_isLowStockExpanded,
                            ),
                            expandedContent: _buildLowStockContent(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showWelcome &&
              _welcomeSlideAnimation != null &&
              _welcomeFadeAnimation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SlideTransition(
                position: _welcomeSlideAnimation!,
                child: FadeTransition(
                  opacity: _welcomeFadeAnimation!,
                  child: const WelcomeCard(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  DashboardData _getDataFromState(DashboardState state) {
    if (state is DashboardLoaded) {
      return state.data;
    } else if (state is DashboardLoading && state.previousData != null) {
      return state.previousData!;
    } else if (state is DashboardError && state.previousData != null) {
      return state.previousData!;
    }
    return DashboardData.empty;
  }

  Widget _buildGradientHeader() {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _openFlyoutMenu,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'C-Billing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Business Dashboard',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFlyoutMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: 'Flyout Menu',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.expand(child: FlyoutMenu());
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
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

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    final slideIndex = index.clamp(0, _slideAnimations.length - 1);
    return SlideTransition(
      position: _slideAnimations[slideIndex],
      child: ScaleTransition(scale: _scaleAnimations[slideIndex], child: child),
    );
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

  Widget _buildFilterSection(DashboardState state) {
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
    DashboardState state,
  ) {
    final isSelected = state.filter == filter;
    return GestureDetector(
      onTap: () async {
        if (filter == DashboardFilter.custom) {
          await _showCustomDateRangePicker();
        } else {
          context.read<DashboardCubit>().changeFilter(filter);
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
    final state = context.read<DashboardCubit>().state;
    final initialDateRange = DateTimeRange(
      start: state.customStartDate ?? now.subtract(const Duration(days: 30)),
      end: state.customEndDate ?? now,
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B4D3E),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      context.read<DashboardCubit>().setCustomDateRange(
        picked.start,
        picked.end,
      );
    }
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
              Text(
                isLoading ? '...' : amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                  letterSpacing: -0.5,
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

  Widget _buildProfitCard(DashboardData data, bool isLoading) {
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
              colors: [
                const Color(0xFF4CAF50).withValues(alpha: 0.7),
                const Color(0xFF2E7D32).withValues(alpha: 0.7),
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                data.profitPercentage >= 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isLoading
                                    ? '...'
                                    : '${data.profitPercentage >= 0 ? '+' : ''}${data.profitPercentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
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
                    const SizedBox(height: 12),
                    Text(
                      isLoading ? '...' : _formatAmount(data.profit),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Literata',
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Net Profit',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(DashboardData data, bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
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
                  const Text(
                    'Stock Overview',
                    style: TextStyle(
                      color: Color(0xFF1B4D3E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Literata',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isLoading ? '...' : '${data.productsCount} Products',
                      style: const TextStyle(
                        color: Color(0xFF1B4D3E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassMiniMetric(
                      title: 'Low Stock',
                      value: isLoading ? '...' : '${data.lowStockCount}',
                      subtitle: 'items',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGlassMiniMetric(
                      title: 'Stock Value',
                      value: isLoading ? '...' : _formatAmount(data.stockValue),
                      subtitle: 'worth',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMiniMetric({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1B4D3E),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Literata',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$title $subtitle',
                style: TextStyle(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.6),
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

  Widget _buildPaymentsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Payments',
                      style: TextStyle(
                        color: Color(0xFF1B4D3E),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your finances',
                      style: TextStyle(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.6),
                        fontSize: 12,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1 Due',
                  style: TextStyle(
                    color: Color(0xFF1B4D3E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ],
          ),
        ),
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
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.people_rounded, 'Clients'),
              _buildNavItem(2, Icons.inventory_2_rounded, 'Stock', badge: '3'),
              _buildNavItem(3, Icons.receipt_long_rounded, 'Bills'),
              _buildNavItem(4, Icons.shopping_bag_rounded, 'Purchase'),
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
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _navigateToPage(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge != null && !isSelected
                ? Badge(
                    label: Text(badge, style: const TextStyle(fontSize: 10)),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[500],
                      size: 24,
                    ),
                  )
                : Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey[500],
                    size: 24,
                  ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(DashboardData data, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildQuickStatCard(
                icon: Icons.receipt_long_rounded,
                value: isLoading ? '...' : '${data.invoicesCount}',
                label: 'Invoices',
                color: const Color(0xFF667eea),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.people_rounded,
                value: isLoading ? '...' : '${data.clientsCount}',
                label: 'Clients',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.inventory_2_rounded,
                value: isLoading ? '...' : '${data.productsCount}',
                label: 'Products',
                color: const Color(0xFFf093fb),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.local_shipping_rounded,
                value: isLoading ? '...' : '${data.suppliersCount}',
                label: 'Suppliers',
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.shopping_cart_rounded,
                value: isLoading ? '...' : '${data.purchasesCount}',
                label: 'Purchases',
                color: const Color(0xFF00BCD4),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.apartment_rounded,
                value: isLoading ? '...' : '${data.companiesCount}',
                label: 'Companies',
                color: const Color(0xFF7B68EE),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.warehouse_rounded,
                value: isLoading ? '...' : '${data.inventoryCount}',
                label: 'Inventory',
                color: const Color(0xFF4DB8A8),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.bar_chart_rounded,
                value: isLoading ? '...' : '${data.lowStockCount}',
                label: 'Low Stock',
                color: const Color(0xFF4A90E2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Widget? targetPage;
        switch (label) {
          case 'Invoices':
            targetPage = const BillsListPage();
            break;
          case 'Clients':
            targetPage = const CustomerPage();
            break;
          case 'Products':
            targetPage = const ProductManagementPage();
            break;
          case 'Suppliers':
            targetPage = const SupplierPage();
            break;
          case 'Purchases':
            targetPage = const EnhancedPurchaseScreen();
            break;
          case 'Companies':
            targetPage = const CompanyPage();
            break;
          case 'Inventory':
          case 'Low Stock':
            targetPage = const ProductManagementPage();
            break;
        }
        if (targetPage != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => targetPage!),
          ).then((_) {
            if (mounted) {
              context.read<DashboardCubit>().refresh();
              _loadExpandableSectionData();
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Literata',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Expandable Card Widget
  Widget _buildExpandableCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget expandedContent,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded
                  ? iconGradient.first.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? iconGradient.first.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isExpanded ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header (always visible)
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: iconGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: iconGradient.first.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF1B4D3E),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: iconGradient.first.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: iconGradient.first,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded content
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: expandedContent,
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Upcoming Payments Content
  Widget _buildUpcomingPaymentsContent() {
    if (_isLoadingExpandableData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_upcomingPayments.isEmpty) {
      return _buildEmptyState(
        'No upcoming payments',
        Icons.check_circle_outline,
      );
    }

    return Column(
      children: [
        Container(height: 1, color: Colors.grey.withOpacity(0.1)),
        const SizedBox(height: 12),
        ..._upcomingPayments.map((payment) {
          final customerName =
              payment['customerName'] as String? ?? 'Unknown Customer';
          final pendingAmount =
              (payment['pendingAmount'] as num?)?.toDouble() ?? 0;
          final billDate = payment['billDate'] != null
              ? DateFormat(
                  'dd MMM',
                ).format(DateTime.parse(payment['billDate'] as String))
              : 'N/A';

          return _buildPaymentListItem(
            name: customerName,
            amount: pendingAmount,
            trailing: billDate,
            color: const Color(0xFF4A90E2),
          );
        }),
        const SizedBox(height: 8),
        _buildViewAllButton('View All Payments', Icons.payments_outlined),
      ],
    );
  }

  // Top Performing Products Content
  Widget _buildTopProductsContent(DashboardData data) {
    if (_isLoadingExpandableData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_topProducts.isEmpty) {
      return _buildEmptyState(
        'No sales data available',
        Icons.trending_up_outlined,
      );
    }

    return Column(
      children: [
        Container(height: 1, color: Colors.grey.withOpacity(0.1)),
        const SizedBox(height: 12),
        ..._topProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return _buildProductRankItem(
            rank: index + 1,
            name: product['productName'] as String? ?? 'Unknown Product',
            sold: (product['totalQuantity'] as num?)?.toInt() ?? 0,
            revenue: (product['totalRevenue'] as num?)?.toDouble() ?? 0,
          );
        }),
        const SizedBox(height: 8),
        _buildViewAllButton('View Sales Report', Icons.bar_chart_rounded),
      ],
    );
  }

  // Pending Payments Content
  Widget _buildPendingPaymentsContent() {
    if (_isLoadingExpandableData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_pendingPayments.isEmpty) {
      return _buildEmptyState(
        'No pending payments',
        Icons.check_circle_outline,
      );
    }

    return Column(
      children: [
        Container(height: 1, color: Colors.grey.withOpacity(0.1)),
        const SizedBox(height: 12),
        ..._pendingPayments.map((customer) {
          final name =
              '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                  .trim();
          final amount =
              (customer['currentPendingAmount'] as num?)?.toDouble() ?? 0;
          final updatedAt = customer['updatedAt'] != null
              ? DateTime.parse(customer['updatedAt'] as String)
              : DateTime.now();
          final daysOverdue = DateTime.now().difference(updatedAt).inDays;

          return _buildPaymentListItem(
            name: name.isEmpty ? 'Unknown Customer' : name,
            amount: amount,
            trailing: daysOverdue > 0 ? '$daysOverdue days overdue' : 'Recent',
            color: const Color(0xFFEF5350),
            isOverdue: daysOverdue > 7,
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CustomerPage())),
          child: _buildViewAllButton(
            'View All Customers',
            Icons.people_outline_rounded,
          ),
        ),
      ],
    );
  }

  // Last Dues Content
  Widget _buildLastDuesContent() {
    if (_isLoadingExpandableData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_lastDues.isEmpty) {
      return _buildEmptyState('No pending dues', Icons.check_circle_outline);
    }

    return Column(
      children: [
        Container(height: 1, color: Colors.grey.withOpacity(0.1)),
        const SizedBox(height: 12),
        ..._lastDues.map((bill) {
          final billId = bill['id'] as String? ?? '';
          final customerName =
              bill['customerName'] as String? ?? 'Walk-in Customer';
          final pendingAmount =
              (bill['pendingAmount'] as num?)?.toDouble() ?? 0;
          final billDate = bill['billDate'] != null
              ? DateFormat(
                  'dd MMM',
                ).format(DateTime.parse(bill['billDate'] as String))
              : 'N/A';

          return _buildPaymentListItem(
            name: customerName.isNotEmpty
                ? customerName
                : 'Bill #${billId.substring(0, 6)}',
            amount: pendingAmount,
            trailing: billDate,
            color: const Color(0xFF9575CD),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BillsListPage())),
          child: _buildViewAllButton(
            'View All Bills',
            Icons.receipt_long_rounded,
          ),
        ),
      ],
    );
  }

  // Low Stock / Order Now Content
  Widget _buildLowStockContent() {
    if (_isLoadingExpandableData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_lowStockItems.isEmpty) {
      return _buildEmptyState(
        'All products are well stocked',
        Icons.inventory_2_outlined,
      );
    }

    return Column(
      children: [
        Container(height: 1, color: Colors.grey.withOpacity(0.1)),
        const SizedBox(height: 12),
        ..._lowStockItems.map(
          (item) => _buildLowStockItem(
            name: item['name'] as String? ?? 'Unknown Product',
            currentStock: (item['currentStock'] as num?)?.toInt() ?? 0,
            reorderQty: 20, // Default reorder quantity
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductManagementPage()),
          ).then((_) {
            if (mounted) {
              context.read<DashboardCubit>().refresh();
              _loadExpandableSectionData();
            }
          }),
          child: _buildViewAllButton(
            'Go to Inventory',
            Icons.inventory_2_rounded,
          ),
        ),
      ],
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(height: 1, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Icon(icon, size: 40, color: Colors.grey[400]),
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

  // Helper: Payment List Item
  Widget _buildPaymentListItem({
    required String name,
    required double amount,
    required String trailing,
    required Color color,
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? color : Colors.grey[600],
                      fontFamily: 'Literata',
                      fontWeight: isOverdue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Product Rank Item
  Widget _buildProductRankItem({
    required int rank,
    required String name,
    required int sold,
    required double revenue,
  }) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final color = rank <= 3 ? colors[rank - 1] : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Literata',
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  Text(
                    '$sold units sold',
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
              '₹${(revenue / 1000).toStringAsFixed(1)}K',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
                color: Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Low Stock Item
  Widget _buildLowStockItem({
    required String name,
    required int currentStock,
    required int reorderQty,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: currentStock <= 5 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$currentStock left',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                // Navigate to purchase page or create order
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const EnhancedPurchaseScreen()));
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                side: const BorderSide(color: Color(0xFF26A69A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Order $reorderQty',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF26A69A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: View All Button
  Widget _buildViewAllButton(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D3E).withOpacity(0.05),
            const Color(0xFF1B4D3E).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B4D3E)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
        ],
      ),
    );
  }
}
