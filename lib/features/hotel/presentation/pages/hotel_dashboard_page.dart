import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth/hotel_auth_service.dart';
import '../../data/auth/hotel_roles.dart';
import '../pages/staff_management_page.dart';
import '../pages/hotel_flyout_menu.dart';

class HotelDashboardPage extends StatefulWidget {
  const HotelDashboardPage({super.key});

  @override
  State<HotelDashboardPage> createState() => _HotelDashboardPageState();
}

class _HotelDashboardPageState extends State<HotelDashboardPage>
    with TickerProviderStateMixin {
  final _auth = HotelAuthService.instance;
  int _selectedIndex = 0;

  /// Bottom nav items filtered by user permissions.
  List<_BottomNavEntry> get _navItems {
    final all = [
      _BottomNavEntry(0, Icons.dashboard_rounded, 'Dashboard', null),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.tableManagement))
        _BottomNavEntry(
          1,
          Icons.table_restaurant_rounded,
          'Tables',
          HotelModule.tableManagement,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.orderManagement))
        _BottomNavEntry(
          2,
          Icons.receipt_long_rounded,
          'Orders',
          HotelModule.orderManagement,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.kitchenDisplay))
        _BottomNavEntry(
          3,
          Icons.soup_kitchen_rounded,
          'Kitchen',
          HotelModule.kitchenDisplay,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.billing))
        _BottomNavEntry(
          4,
          Icons.point_of_sale_rounded,
          'Billing',
          HotelModule.billing,
        ),
    ];
    return all;
  }

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    // Backfill staffMapping for existing staff (runs once, admin only)
    if (_auth.isAdmin) {
      _auth.backfillStaffMappings();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _auth.isAdmin;
    final subUser = _auth.currentSubUser;
    final userName = isAdmin ? 'Admin' : (subUser?.name ?? 'Staff');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(userName),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  // ─── TAB CONTENT ──────────────────────────────────────────────

  Widget _buildTabContent() {
    final items = _navItems;
    if (_selectedIndex >= items.length) return _buildDashboardTab();
    final entry = items[_selectedIndex];
    switch (entry.id) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildPlaceholderTab('Tables', Icons.table_restaurant_rounded);
      case 2:
        return _buildPlaceholderTab('Orders', Icons.receipt_long_rounded);
      case 3:
        return _buildPlaceholderTab('Kitchen', Icons.soup_kitchen_rounded);
      case 4:
        return _buildPlaceholderTab('Billing', Icons.point_of_sale_rounded);
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    final isAdmin = _auth.isAdmin;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin || _auth.hasAccess(HotelModule.dashboard))
            _buildLiveStatsSection(),
          const SizedBox(height: 28),
          _buildSectionHeader(
            'Quick Actions',
            Icons.flash_on_rounded,
            'Frequently used modules',
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 28),
          _buildSectionHeader(
            'All Modules',
            Icons.grid_view_rounded,
            'Manage your hotel operations',
          ),
          const SizedBox(height: 16),
          _buildModulesGrid(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF1B4D3E)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV BAR ───────────────────────────────────────────

  String _getPageTitle() {
    final items = _navItems;
    if (_selectedIndex >= items.length) return 'Hotel';
    return items[_selectedIndex].label;
  }

  String _getPageSubtitle() {
    final items = _navItems;
    if (_selectedIndex >= items.length) return '';
    switch (items[_selectedIndex].id) {
      case 0:
        return 'Hotel overview';
      case 1:
        return 'Table management';
      case 2:
        return 'Order management';
      case 3:
        return 'Kitchen display';
      case 4:
        return 'Generate bills';
      default:
        return '';
    }
  }

  Widget _buildBottomNavBar() {
    final items = _navItems;
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
              for (int i = 0; i < items.length; i++)
                _buildNavItem(
                  i,
                  items[i].icon,
                  items[i].label,
                  isPrimary: items[i].id == 2,
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

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
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

  // ─── HEADER ───────────────────────────────────────────────────

  Widget _buildHeader(String userName) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = _auth.isAdmin;
    final role = isAdmin ? null : _auth.currentSubUser?.role;

    return SlideTransition(
      position: _headerSlide,
      child: Container(
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
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + actions
                Row(
                  children: [
                    // Hotel logo — tap to open flyout
                    GestureDetector(
                      onTap: _openFlyoutMenu,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/hotel_logo.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Text(
                              'H',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
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
                    if (isAdmin)
                      _buildHeaderButton(
                        Icons.people_outline_rounded,
                        'Staff',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffManagementPage(),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
                // Role badge + email
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D5B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ),
                    if (role != null) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'Literata',
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildHeaderButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ─── LIVE STATS ───────────────────────────────────────────────

  Widget _buildLiveStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Responsive: show 2 cards per screen on small, 3 on medium, 4 on large
        int cardsPerScreen = 2;
        if (screenWidth > 900) {
          cardsPerScreen = 4;
        } else if (screenWidth > 600) {
          cardsPerScreen = 3;
        }
        final cardWidth =
            (screenWidth - 40 - (cardsPerScreen - 1) * 12) / cardsPerScreen;
        final cardHeight = cardWidth * 0.72;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Live Status',
              Icons.monitor_heart_rounded,
              'Real-time overview',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: cardHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildGlassyStatCard(
                    'Active Tables',
                    '0',
                    Icons.table_restaurant_rounded,
                    const [Color(0xFF43A047), Color(0xFF2E7D32)],
                    cardWidth,
                    cardHeight,
                  ),
                  const SizedBox(width: 12),
                  _buildGlassyStatCard(
                    'Pending Orders',
                    '0',
                    Icons.receipt_long_rounded,
                    const [Color(0xFFEF6C00), Color(0xFFE65100)],
                    cardWidth,
                    cardHeight,
                  ),
                  const SizedBox(width: 12),
                  _buildGlassyStatCard(
                    'Kitchen Queue',
                    '0',
                    Icons.soup_kitchen_rounded,
                    const [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                    cardWidth,
                    cardHeight,
                  ),
                  const SizedBox(width: 12),
                  _buildGlassyStatCard(
                    'Today\'s Revenue',
                    '₹0',
                    Icons.trending_up_rounded,
                    const [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
                    cardWidth,
                    cardHeight,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassyStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> gradientColors,
    double cardWidth,
    double cardHeight,
  ) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // revert to previous shape
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.10),
            blurRadius: 2,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Frosted glass effect with even darker classy look
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.25, 0.65, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.54),
                      gradientColors.first.withOpacity(0.42),
                      gradientColors.last.withOpacity(0.42),
                      Colors.black.withOpacity(0.38),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 2.2,
                    color: Colors.white.withOpacity(0.13),
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            // Inner shadow (simulated with a dark gradient overlay)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.07),
                    Colors.transparent,
                    Colors.black.withOpacity(0.04),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Top-left shiny arc
            Positioned(
              top: -18,
              left: -18,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.0),
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
            ),
            // Bottom highlight
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withOpacity(0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle noise overlay (for realism)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    'assets/images/noise.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.32),
                            width: 0.7,
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 16),
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Literata',
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.13),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Literata',
                            letterSpacing: 0.3,
                            color: Colors.white,
                            // No shadows for flat look
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // ...existing code...
  }

  // ─── SECTION HEADER ───────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1B4D3E), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Literata',
                  color: Color(0xFF1B4D3E),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'Literata',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = <_QuickAction>[
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.tableManagement))
        _QuickAction(
          'Tables',
          Icons.table_restaurant_rounded,
          const Color(0xFF43A047),
          HotelModule.tableManagement,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.orderManagement))
        _QuickAction(
          'Orders',
          Icons.receipt_long_rounded,
          const Color(0xFFEF6C00),
          HotelModule.orderManagement,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.kitchenDisplay))
        _QuickAction(
          'Kitchen',
          Icons.soup_kitchen_rounded,
          const Color(0xFF8E24AA),
          HotelModule.kitchenDisplay,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.billing))
        _QuickAction(
          'Billing',
          Icons.point_of_sale_rounded,
          const Color(0xFF00897B),
          HotelModule.billing,
        ),
      if (_auth.isAdmin || _auth.hasAccess(HotelModule.menuManagement))
        _QuickAction(
          'Menu',
          Icons.restaurant_menu_rounded,
          const Color(0xFFD32F2F),
          HotelModule.menuManagement,
        ),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final a = actions[index];
          return _buildQuickActionChip(a);
        },
      ),
    );
  }

  Widget _buildQuickActionChip(_QuickAction action) {
    return GestureDetector(
      onTap: () => _onModuleTap(action.module),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: action.color.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(action.icon, color: action.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MODULE GRID ──────────────────────────────────────────────

  Widget _buildModulesGrid() {
    final modules = _getAccessibleModules();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.92,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _AnimatedModuleTile(
          module: module,
          color: _moduleColor(module),
          icon: _moduleIcon(module),
          delay: Duration(milliseconds: 80 * index),
          onTap: () => _onModuleTap(module),
        );
      },
    );
  }

  List<HotelModule> _getAccessibleModules() {
    if (_auth.isAdmin) return HotelModule.values;
    return HotelModule.values.where((m) => _auth.hasAccess(m)).toList();
  }

  // ─── MODULE HELPERS ───────────────────────────────────────────

  IconData _moduleIcon(HotelModule module) {
    switch (module) {
      case HotelModule.dashboard:
        return Icons.dashboard_rounded;
      case HotelModule.tableManagement:
        return Icons.table_restaurant_rounded;
      case HotelModule.orderManagement:
        return Icons.receipt_long_rounded;
      case HotelModule.menuManagement:
        return Icons.restaurant_menu_rounded;
      case HotelModule.kitchenDisplay:
        return Icons.soup_kitchen_rounded;
      case HotelModule.billing:
        return Icons.point_of_sale_rounded;
      case HotelModule.inventory:
        return Icons.inventory_2_rounded;
      case HotelModule.roomManagement:
        return Icons.hotel_rounded;
      case HotelModule.guestManagement:
        return Icons.people_rounded;
      case HotelModule.staffManagement:
        return Icons.badge_rounded;
      case HotelModule.reports:
        return Icons.analytics_rounded;
      case HotelModule.settings:
        return Icons.settings_rounded;
      case HotelModule.expenses:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color _moduleColor(HotelModule module) {
    switch (module) {
      case HotelModule.dashboard:
        return const Color(0xFF1B4D3E);
      case HotelModule.tableManagement:
        return const Color(0xFF43A047);
      case HotelModule.orderManagement:
        return const Color(0xFFEF6C00);
      case HotelModule.menuManagement:
        return const Color(0xFFD32F2F);
      case HotelModule.kitchenDisplay:
        return const Color(0xFF8E24AA);
      case HotelModule.billing:
        return const Color(0xFF00897B);
      case HotelModule.inventory:
        return const Color(0xFF5D4037);
      case HotelModule.roomManagement:
        return const Color(0xFF2E7D5B);
      case HotelModule.guestManagement:
        return const Color(0xFF00ACC1);
      case HotelModule.staffManagement:
        return const Color(0xFF546E7A);
      case HotelModule.reports:
        return const Color(0xFFC62828);
      case HotelModule.settings:
        return const Color(0xFF757575);
      case HotelModule.expenses:
        return const Color(0xFF6D4C41);
    }
  }

  void _onModuleTap(HotelModule module) {
    // Check permission for non-admin users
    if (!_auth.isAdmin && !_auth.hasAccess(module)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You don\'t have access to ${module.label}. Contact your admin.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (module == HotelModule.staffManagement && _auth.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StaffManagementPage()),
      );
      return;
    }

    // Navigate to matching bottom nav tab if it exists
    final items = _navItems;
    final navIndex = items.indexWhere((e) => e.module == module);
    if (navIndex != -1) {
      setState(() => _selectedIndex = navIndex);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${module.label} coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
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
      pageBuilder: (_, _, _) => const SizedBox.expand(child: HotelFlyoutMenu()),
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

  void _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            const Text(
              'Exit App',
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(fontFamily: 'Literata', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Literata',
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(
                fontFamily: 'Literata',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      SystemNavigator.pop();
    }
  }
}

// ─── ANIMATED MODULE TILE ─────────────────────────────────────────

class _AnimatedModuleTile extends StatefulWidget {
  final HotelModule module;
  final Color color;
  final IconData icon;
  final Duration delay;
  final VoidCallback onTap;

  const _AnimatedModuleTile({
    required this.module,
    required this.color,
    required this.icon,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_AnimatedModuleTile> createState() => _AnimatedModuleTileState();
}

class _AnimatedModuleTileState extends State<_AnimatedModuleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          splashColor: widget.color.withValues(alpha: 0.12),
          highlightColor: widget.color.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.color.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.color.withValues(alpha: 0.15),
                        widget.color.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.module.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      fontFamily: 'Literata',
                      color: Colors.grey.shade800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final HotelModule module;

  const _QuickAction(this.label, this.icon, this.color, this.module);
}

class _BottomNavEntry {
  final int id;
  final IconData icon;
  final String label;
  final HotelModule? module;

  const _BottomNavEntry(this.id, this.icon, this.label, this.module);
}
