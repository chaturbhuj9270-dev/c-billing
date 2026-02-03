import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';
import 'profile_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../company/presentation/pages/company_page.dart';
import '../../../inventory_management/presentation/pages/purchase_page.dart';
import '../../../inventory_management/presentation/pages/product_management_page.dart';

class FlyoutMenu extends StatefulWidget {
  const FlyoutMenu({super.key});

  @override
  State<FlyoutMenu> createState() => _FlyoutMenuState();
}

class _FlyoutMenuState extends State<FlyoutMenu> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  late SessionManager _sessionManager;
  late CredentialsManager _credentialsManager;
  late User? _currentUser;
  String _userName = 'User';

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _menuItemAnimations;
  late List<Animation<double>> _menuItemFadeAnimations;

  // Menu items with icons and colors
  final List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.home_rounded, label: 'Home', route: 'Home', color: const Color(0xFF1B4D3E)),
    _MenuItem(icon: Icons.receipt_long_rounded, label: 'Invoices', route: 'Invoices', color: const Color(0xFF667eea)),
    _MenuItem(icon: Icons.people_rounded, label: 'Clients', route: 'Clients', color: const Color(0xFF4CAF50)),
    _MenuItem(icon: Icons.local_shipping_rounded, label: 'Suppliers', route: 'Suppliers', color: const Color(0xFFFF6B6B)),
    _MenuItem(icon: Icons.apartment_rounded, label: 'Companies', route: 'Companies', color: const Color(0xFF7B68EE)),
    _MenuItem(icon: Icons.shopping_cart_rounded, label: 'Purchases', route: 'Purchases', color: const Color(0xFF00BCD4)),
    _MenuItem(icon: Icons.warehouse_rounded, label: 'Inventory', route: 'Inventory', color: const Color(0xFF4DB8A8)),
    _MenuItem(icon: Icons.bar_chart_rounded, label: 'Reports', route: 'Reports', color: const Color(0xFF4A90E2)),
    _MenuItem(icon: Icons.person_rounded, label: 'Profile', route: 'Profile', color: const Color(0xFF2E7D32)),
    _MenuItem(icon: Icons.settings_rounded, label: 'Settings', route: 'Settings', color: const Color(0xFF78909C)),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
    _credentialsManager = CredentialsManager();
    _currentUser = _auth.currentUser;
    _userName = _currentUser?.displayName ?? 'User';

    // Main slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Staggered menu item animations
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _menuItemAnimations = List.generate(_menuItems.length, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _menuItemFadeAnimations = List.generate(_menuItems.length, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _logout() {
    _sessionManager.endSession();
    _credentialsManager.clearCredentials().then((_) {
      print('[DEBUG] User logged out - credentials cleared');
      _auth.signOut().then((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      });
    }).catchError((e) {
      print('[ERROR] Error during logout: $e');
      _auth.signOut().then((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      });
    });
  }

  void _navigateToPage(String pageName, int index) {
    setState(() {
      _selectedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      Navigator.pop(context);
      switch (pageName) {
        case 'Home':
          break;
        case 'Invoices':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoices page coming soon')),
          );
          break;
        case 'Clients':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerPage()),
          );
          break;
        case 'Suppliers':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupplierPage()),
          );
          break;
        case 'Companies':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CompanyPage()),
          );
          break;
        case 'Purchases':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PurchasePage()),
          );
          break;
        case 'Inventory':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductManagementPage()),
          );
          break;
        case 'Reports':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reports page coming soon')),
          );
          break;
        case 'Profile':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
          break;
        case 'Settings':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings page coming soon')),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient Header with Profile
            _buildHeader(),

            // Menu Items
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    return SlideTransition(
                      position: _menuItemAnimations[index],
                      child: FadeTransition(
                        opacity: _menuItemFadeAnimations[index],
                        child: _buildMenuItem(
                          item: _menuItems[index],
                          index: index,
                          isSelected: _selectedIndex == index,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom Section with Logout
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBottomSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
          child: Row(
            children: [
              // Profile Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userName.isNotEmpty
                        ? _userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // User name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
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
    );
  }

  Widget _buildMenuItem({
    required _MenuItem item,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _navigateToPage(item.route, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: item.color.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            // Icon with gradient background when selected
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [item.color, item.color.withOpacity(0.7)],
                      )
                    : null,
                color: isSelected ? null : item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.color.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                item.icon,
                color: isSelected ? Colors.white : item.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? item.color : const Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Literata',
                ),
              ),
            ),
            // Arrow indicator for selected item
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: item.color,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Logout Button
            GestureDetector(
              onTap: _logout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD32F2F).withOpacity(0.1),
                      const Color(0xFFD32F2F).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD32F2F).withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD32F2F),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Version number only
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}