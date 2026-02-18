import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../customer/presentation/pages/enhanced_customer_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../company/presentation/pages/company_page.dart';
import '../../../inventory_management/presentation/pages/enhanced_purchase_screen.dart';
import '../../../inventory_management/presentation/pages/product_management_page.dart';
import '../../../billing/presentation/pages/billing_page.dart';
import '../../../billing/presentation/pages/bills_list_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../common_widgets/welcome_card.dart';
import 'flyout_menu.dart';

enum DashboardFilter { today, thisWeek, thisMonth, thisYear, custom, all }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late SessionManager _sessionManager;

  // Filter
  DashboardFilter _selectedFilter = DashboardFilter.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Dashboard data
  bool _isLoading = true;
  int _invoicesCount = 0;
  int _clientsCount = 0;
  int _productsCount = 0;
  int _suppliersCount = 0;
  int _purchasesCount = 0;
  int _companiesCount = 0;
  int _inventoryCount = 0;
  double _totalSales = 0;
  int _totalBillsCount = 0;
  int _totalItemsSold = 0;
  double _totalPurchases = 0;
  int _purchaseOrders = 0;
  int _purchaseQty = 0;
  double _profit = 0;
  double _profitPercentage = 0;
  double _stockValue = 0;
  int _lowStockCount = 0;

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

    // Load dashboard data
    _loadDashboardData();

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
        // Auto-hide after 5 seconds
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

  // Get date range based on selected filter
  Map<String, DateTime?> _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case DashboardFilter.today:
        return {
          'start': today,
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case DashboardFilter.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return {'start': startOfWeek, 'end': endOfWeek};
      case DashboardFilter.thisMonth:
        return {
          'start': DateTime(now.year, now.month, 1),
          'end': DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        };
      case DashboardFilter.thisYear:
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, 12, 31, 23, 59, 59),
        };
      case DashboardFilter.custom:
        return {
          'start': _customStartDate,
          'end': _customEndDate != null
              ? DateTime(
                  _customEndDate!.year,
                  _customEndDate!.month,
                  _customEndDate!.day,
                  23,
                  59,
                  59,
                )
              : null,
        };
      case DashboardFilter.all:
        return {'start': null, 'end': null};
    }
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case DashboardFilter.today:
        return 'Today';
      case DashboardFilter.thisWeek:
        return 'This Week';
      case DashboardFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case DashboardFilter.thisYear:
        return 'Year ${DateTime.now().year}';
      case DashboardFilter.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return '${DateFormat('dd MMM').format(_customStartDate!)} - ${DateFormat('dd MMM').format(_customEndDate!)}';
        }
        return 'Custom Range';
      case DashboardFilter.all:
        return 'All Time';
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[DEBUG] No authenticated user - cannot load dashboard data');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userId = currentUser.uid;
      print('[DEBUG] Loading dashboard data for user: $userId');

      // Get user's data collection reference
      final userRef = _firestore.collection('users').doc(userId);

      // Get date range based on filter
      final dateRange = _getDateRange();
      final startDate = dateRange['start'];
      final endDate = dateRange['end'];

      // Load counts from Firestore in parallel (under users/{userId}/)
      final countFutures = await Future.wait([
        userRef.collection('bills').count().get(),
        userRef.collection('customers').count().get(),
        userRef.collection('products').count().get(),
        userRef.collection('suppliers').count().get(),
        userRef.collection('purchases').count().get(),
        userRef.collection('companies').count().get(),
      ]);

      print(
        '[DEBUG] Counts: bills=${countFutures[0].count}, customers=${countFutures[1].count}, products=${countFutures[2].count}',
      );

      // Get all bills for the selected period
      Query billsQuery = userRef.collection('bills');
      if (startDate != null) {
        billsQuery = billsQuery.where(
          'billDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        billsQuery = billsQuery.where(
          'billDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }
      final billsSnapshot = await billsQuery.get();

      print('[DEBUG] Bills for period: ${billsSnapshot.docs.length}');

      // Calculate sales data from bills
      double totalSalesAmount = 0;
      int totalItemsSold = 0;
      for (var doc in billsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          totalSalesAmount += (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final items = data['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            totalItemsSold += (item['quantity'] as num?)?.toInt() ?? 0;
          }
        }
      }

      print(
        '[DEBUG] Total sales: $totalSalesAmount, Items sold: $totalItemsSold',
      );

      // Get purchases for the selected period
      Query purchasesQuery = userRef.collection('purchases');
      if (startDate != null) {
        purchasesQuery = purchasesQuery.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        purchasesQuery = purchasesQuery.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }
      final purchasesSnapshot = await purchasesQuery.get();

      // Calculate purchase data
      double totalPurchaseAmount = 0;
      int totalPurchaseQty = 0;
      for (var doc in purchasesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          totalPurchaseAmount += (data['totalAmount'] as num?)?.toDouble() ?? 0;
          totalPurchaseQty += (data['quantity'] as num?)?.toInt() ?? 0;
        }
      }

      print(
        '[DEBUG] Total purchases: $totalPurchaseAmount, Purchase qty: $totalPurchaseQty',
      );

      // Get products for stock value calculation
      final productsSnapshot = await userRef.collection('products').get();
      double stockValue = 0;
      int lowStockCount = 0;
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
        final purchasePrice = (data['purchasePrice'] as num?)?.toDouble() ?? 0;
        stockValue += currentStock * purchasePrice;
        if (currentStock < 10 && currentStock > 0) {
          lowStockCount++;
        }
      }

      print('[DEBUG] Stock value: $stockValue, Low stock: $lowStockCount');

      // Calculate profit
      final profit = totalSalesAmount - totalPurchaseAmount;

      if (mounted) {
        setState(() {
          _invoicesCount = countFutures[0].count ?? 0;
          _clientsCount = countFutures[1].count ?? 0;
          _productsCount = countFutures[2].count ?? 0;
          _suppliersCount = countFutures[3].count ?? 0;
          _purchasesCount = countFutures[4].count ?? 0;
          _companiesCount = countFutures[5].count ?? 0;
          _inventoryCount = _productsCount;

          // Sales data
          _totalSales = totalSalesAmount;
          _totalBillsCount = billsSnapshot.docs.length;
          _totalItemsSold = totalItemsSold;

          // Purchase data
          _totalPurchases = totalPurchaseAmount;
          _purchaseOrders = purchasesSnapshot.docs.length;
          _purchaseQty = totalPurchaseQty;

          // Profit data
          _profit = profit;
          _profitPercentage = _totalSales > 0
              ? (_profit / _totalSales) * 100
              : 0;

          // Stock data
          _stockValue = stockValue;
          _lowStockCount = lowStockCount;

          _isLoading = false;
        });
      }

      print('[DEBUG] Dashboard data loaded successfully!');
    } catch (e) {
      print('[ERROR] Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _logout() {
    // Use centralized logout service to ensure all local data is cleared
    LogoutService.instance.logout(context);
  }

  void _resetSessionTimer() {
    _sessionManager.resetSession();
    print('[DEBUG] Session reset from dashboard activity');
  }

  void _navigateToPage(int index) {
    _resetSessionTimer(); // Reset timer on navigation
    // Content switching is handled by _buildBody() based on _selectedIndex
    // No navigation needed - just update the state
  }

  /// Build the appropriate body content based on selected tab index
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const EnhancedCustomerPage(isEmbedded: true);
      case 2:
        return const ProductManagementPage();
      case 3:
        return const BillingPage(isEmbedded: true);
      case 4:
        return const EnhancedPurchaseScreen(isEmbedded: true);
      default:
        return _buildDashboardContent();
    }
  }

  /// Build the dashboard content (original dashboard body)
  Widget _buildDashboardContent() {
    return Stack(
      children: [
        NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Pinned Gradient Header
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
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF1B4D3E),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Section (Horizontal Scrollable)
                    _buildQuickStatsSection(),
                    const SizedBox(height: 20),

                    // Filter Section
                    _buildFilterSection(),
                    const SizedBox(height: 28),

                    // Sales & Profit Analysis Section
                    _buildAnimatedCard(
                      index: 0,
                      child: _buildSectionHeader(
                        title: 'Sales & Profit Analysis',
                        subtitle: _getFilterLabel(),
                        icon: Icons.analytics_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metric Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedCard(
                            index: 1,
                            child: _buildGradientMetricCard(
                              title: 'Total Sales',
                              amount: _formatAmount(_totalSales),
                              subtitle:
                                  'Bills: $_totalBillsCount • Items: $_totalItemsSold',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF667eea),
                                  Color(0xFF764ba2),
                                ],
                              ),
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnimatedCard(
                            index: 2,
                            child: _buildGradientMetricCard(
                              title: 'Total Purchase',
                              amount: _formatAmount(_totalPurchases),
                              subtitle:
                                  'Orders: $_purchaseOrders • Qty: $_purchaseQty',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF757575),
                                  Color(0xFF424242),
                                ],
                              ),
                              icon: Icons.shopping_bag_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Profit Card (Full Width)
                    _buildAnimatedCard(index: 3, child: _buildProfitCard()),
                    const SizedBox(height: 28),

                    // Inventory Section Header
                    _buildAnimatedCard(
                      index: 4,
                      child: _buildSectionHeader(
                        title: 'Inventory & Payments',
                        subtitle: 'Live status',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inventory Card
                    _buildAnimatedCard(
                      index: 5,
                      child: _buildInventoryCard(),
                    ),
                    const SizedBox(height: 16),

                    // Payments Card
                    _buildAnimatedCard(index: 5, child: _buildPaymentsCard()),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Welcome snackbar overlay
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
    );
  }

  @override
  Widget build(BuildContext context) {
    _resetSessionTimer();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
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
              // Top bar
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

  Widget _buildGradientMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required Gradient gradient,
    required IconData icon,
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
              end: (gradient).end,
              colors: [
                (gradient).colors[0].withValues(alpha: 0.7),
                (gradient).colors[1].withValues(alpha: 0.7),
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
              Text(
                amount,
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

  Widget _buildProfitCard() {
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
                                _profitPercentage >= 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_profitPercentage >= 0 ? '+' : ''}${_profitPercentage.toStringAsFixed(0)}%',
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
                      _formatAmount(_profit),
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
                      'Net Profit This Month',
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
                child: Icon(
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

  Widget _buildInventoryCard() {
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
                      color: Color(0xFF1B4D3E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_productsCount Products',
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
                      value: '$_lowStockCount',
                      subtitle: 'items',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGlassMiniMetric(
                      title: 'Stock Value',
                      value: _formatAmount(_stockValue),
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

  Widget _buildMiniMetric({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.08), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$title $subtitle',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'Literata',
            ),
          ),
        ],
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
                  color: Color(0xFF1B4D3E).withValues(alpha: 0.6),
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
                        color: Color(0xFF1B4D3E).withValues(alpha: 0.6),
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
                  color: Color(0xFF1B4D3E).withValues(alpha: 0.15),
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

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: const Color(0xFF1B4D3E),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Filter by Period',
              style: TextStyle(
                color: const Color(0xFF1B4D3E),
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
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisWeek,
                'This Week',
                Icons.date_range_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisMonth,
                'This Month',
                Icons.calendar_month_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.thisYear,
                'This Year',
                Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.custom,
                'Custom',
                Icons.edit_calendar_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                DashboardFilter.all,
                'All Time',
                Icons.all_inclusive_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(DashboardFilter filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () async {
        if (filter == DashboardFilter.custom) {
          await _showCustomDateRangePicker();
        } else {
          setState(() {
            _selectedFilter = filter;
            _isLoading = true;
          });
          await _loadDashboardData();
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
    final initialDateRange = DateTimeRange(
      start: _customStartDate ?? now.subtract(const Duration(days: 30)),
      end: _customEndDate ?? now,
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

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = DashboardFilter.custom;
        _isLoading = true;
      });
      await _loadDashboardData();
    }
  }

  Widget _buildQuickStatsSection() {
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
                value: _isLoading ? '...' : '$_invoicesCount',
                label: 'Invoices',
                color: const Color(0xFF667eea),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.people_rounded,
                value: _isLoading ? '...' : '$_clientsCount',
                label: 'Clients',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.inventory_2_rounded,
                value: _isLoading ? '...' : '$_productsCount',
                label: 'Products',
                color: const Color(0xFFf093fb),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.local_shipping_rounded,
                value: _isLoading ? '...' : '$_suppliersCount',
                label: 'Suppliers',
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.shopping_cart_rounded,
                value: _isLoading ? '...' : '$_purchasesCount',
                label: 'Purchases',
                color: const Color(0xFF00BCD4),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.apartment_rounded,
                value: _isLoading ? '...' : '$_companiesCount',
                label: 'Companies',
                color: const Color(0xFF7B68EE),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.warehouse_rounded,
                value: _isLoading ? '...' : '$_inventoryCount',
                label: 'Inventory',
                color: const Color(0xFF4DB8A8),
              ),
              const SizedBox(width: 16),
              _buildQuickStatCard(
                icon: Icons.bar_chart_rounded,
                value: _isLoading ? '...' : '$_lowStockCount',
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
        // Navigate to related page based on label
        switch (label) {
          case 'Invoices':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BillsListPage()));
            break;
          case 'Clients':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EnhancedCustomerPage()));
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
            ).push(MaterialPageRoute(builder: (_) => const EnhancedPurchaseScreen()));
            break;
          case 'Companies':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CompanyPage()));
            break;
          case 'Inventory':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductManagementPage()),
            );
            break;
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
