import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clients page coming soon')),
        );
        break;
      case 'Reports':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports page coming soon')),
        );
        break;
      case 'Profile':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile page coming soon')),
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
                // User Profile Section with gradient background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B4D3E),
                        Color(0xFF2A6B56),
                      ],
                    ),
                  ),
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
                              color: Colors.white,
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
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
                      // User Name
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Literata',
                        ),
                      ),
                      const SizedBox(height: 4),
                      // User Email
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Color(0xFFB3E5FC),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ],
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