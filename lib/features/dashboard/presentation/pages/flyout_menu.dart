import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';
import '../../../../core/services/user_management_service.dart';
import '../../../../core/services/role_permission_service.dart';
import '../../../../core/services/shop_access_service.dart';
import 'profile_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../shop/presentation/pages/shop_details_page.dart';
import '../../../shop/presentation/pages/shop_admin_panel.dart';

class FlyoutMenu extends StatefulWidget {
  const FlyoutMenu({super.key});

  @override
  State<FlyoutMenu> createState() => _FlyoutMenuState();
}

class _FlyoutMenuState extends State<FlyoutMenu> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  late SessionManager _sessionManager;
  late CredentialsManager _credentialsManager;
  late User? _currentUser;
  String _userName = 'User';
  String _userEmail = '';
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
    _credentialsManager = CredentialsManager();
    _currentUser = _auth.currentUser;
    _userName = _currentUser?.displayName ?? 'User';
    _userEmail = _currentUser?.email ?? '';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  void _navigateToShopAdmin() {
    Navigator.pop(context);
    
    // Fetch user's shop ID from Firestore
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .get()
        .then((userDoc) {
      if (!mounted) return; // Check if widget is still mounted
      
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final shopId = userDoc.data()?['shopId'] as String?;
      if (shopId == null || shopId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop not found for this user')),
        );
        return;
      }

      try {
        // Navigate to Shop Admin Panel with BLoC
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              try {
                return BlocProvider(
                  create: (context) => ShopManagementBloc(
                    userManagementService: UserManagementService(),
                    rolePermissionService: RolePermissionService(),
                    shopAccessService: ShopAccessService(),
                    currentUserId: _currentUser!.uid,
                  ),
                  child: ShopAdminPanelPage(
                    shopId: shopId,
                    currentUserId: _currentUser!.uid,
                  ),
                );
              } catch (e) {
                print('[ERROR] Error creating BLoC: $e');
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Text('Error loading admin panel: ${e.toString()}'),
                  ),
                );
              }
            },
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigation error: ${e.toString()}')),
          );
        }
      }
    }).catchError((e) {
      if (mounted) {
        print('[ERROR] Error loading shop: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shop: ${e.toString()}')),
        );
      }
    });
  }

  void _navigateToPage(String pageName) {
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
      case 'ShopDetails':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShopDetailsPage()),
        );
        break;
      case 'ShopAdmin':
        _navigateToShopAdmin();
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
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                // User Profile Section - Navigation bar style (white background with teal text)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF1B4D3E),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Profile Avatar with green accent
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE8F5E9),
                          ),
                          child: Center(
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Name - Teal color matching app theme
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Color(0xFF1B4D3E),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 4),
                      // User Email - Subtle gray
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Divider
                      Container(
                        height: 1,
                        color: const Color(0xFFEEEEEE),
                      ),
                    ],
                  ),
                ),
                // Menu Items - Page background style
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    children: [
                      _buildMenuItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        onTap: () => _navigateToPage('Home'),
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt_outlined,
                        label: 'Invoices',
                        onTap: () => _navigateToPage('Invoices'),
                      ),
                      _buildMenuItem(
                        icon: Icons.people_outline,
                        label: 'Clients',
                        onTap: () => _navigateToPage('Clients'),
                      ),
                      _buildMenuItem(
                        icon: Icons.business_outlined,
                        label: 'Suppliers',
                        onTap: () => _navigateToPage('Suppliers'),
                      ),
                      _buildMenuItem(
                        icon: Icons.storefront_outlined,
                        label: 'Shop Details',
                        onTap: () => _navigateToPage('ShopDetails'),
                      ),
                      _buildMenuItem(
                        icon: Icons.admin_panel_settings,
                        label: 'Shop Admin',
                        onTap: () => _navigateToPage('ShopAdmin'),
                      ),
                      _buildMenuItem(
                        icon: Icons.bar_chart_outlined,
                        label: 'Reports',
                        onTap: () => _navigateToPage('Reports'),
                      ),
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        onTap: () => _navigateToPage('Profile'),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => _navigateToPage('Settings'),
                      ),
                    ],
                  ),
                ),
                // Logout Button
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF5350),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Color(0xFFEF5350),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFEF5350),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFEEEEEE),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1B4D3E),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Literata',
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBDBDBD),
              size: 24,
            ),
          ],
        ),
      ),
    );
}
}