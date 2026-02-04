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
import '../../../../common_widgets/welcome_card.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../data/models/dashboard_data.dart';
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
        ).push(MaterialPageRoute(builder: (_) => const CustomerPage()));
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability page coming soon')),
        );
        break;
      case 3:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BillingPage()));
        break;
      case 4:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
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
        switch (label) {
          case 'Invoices':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BillsListPage()));
            break;
          case 'Clients':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CustomerPage()));
            break;
          case 'Products':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductManagementPage()),
            );
            break;
          case 'Suppliers':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SupplierPage()));
            break;
          case 'Purchases':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
            break;
          case 'Companies':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CompanyPage()));
            break;
          case 'Inventory':
          case 'Low Stock':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductManagementPage()),
            );
            break;
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
}
