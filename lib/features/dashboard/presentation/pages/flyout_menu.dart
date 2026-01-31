import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';
import 'profile_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../product/presentation/pages/product_page.dart';
import '../../../company/presentation/pages/company_page.dart';

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
      case 'Companies':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CompanyPage()),
        );
        break;
      case 'Products':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductPage()),
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
                // User Profile Section - Dark green header with curved bottom, full width
                ClipPath(
                  clipper: _CurvedHeaderClipper(),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B4D3E),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Avatar with white border
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1B5E20),
                          ),
                          child: Center(
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Name - White
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 6),
                      // User Email - Green
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  ),
                ),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    children: [
                      _buildMenuItem(
                        icon: Icons.home,
                        label: 'Home',
                        onTap: () => _navigateToPage('Home'),
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt,
                        label: 'Invoices',
                        onTap: () => _navigateToPage('Invoices'),
                      ),
                      _buildMenuItem(
                        icon: Icons.people,
                        label: 'Clients',
                        onTap: () => _navigateToPage('Clients'),
                      ),
                      _buildMenuItem(
                        icon: Icons.business,
                        label: 'Suppliers',
                        onTap: () => _navigateToPage('Suppliers'),
                      ),
                      _buildMenuItem(
                        icon: Icons.apartment,
                        label: 'Companies',
                        onTap: () => _navigateToPage('Companies'),
                      ),
                      _buildMenuItem(
                        icon: Icons.shopping_bag,
                        label: 'Products',
                        onTap: () => _navigateToPage('Products'),
                      ),
                      _buildMenuItem(
                        icon: Icons.bar_chart,
                        label: 'Reports',
                        onTap: () => _navigateToPage('Reports'),
                      ),
                      _buildMenuItem(
                        icon: Icons.person,
                        label: 'Profile',
                        onTap: () => _navigateToPage('Profile'),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.exit_to_app,
                          color: Color(0xFFD32F2F),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
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
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1B5E20),
              size: 24,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    
    // Create a smooth curved bottom
    path.quadraticBezierTo(
      size.width / 3,
      size.height+30,
      size.width,
      size.height - 20 ,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}