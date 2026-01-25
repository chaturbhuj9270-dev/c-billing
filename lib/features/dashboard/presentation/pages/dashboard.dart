import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/credentials_manager.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;
  late SessionManager _sessionManager;
  late CredentialsManager _credentialsManager;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();
    _credentialsManager = CredentialsManager();
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

  void _resetSessionTimer() {
    _sessionManager.resetSession();
    print('[DEBUG] Session reset from dashboard activity');
  }

  void _navigateToPage(int index) {
    _resetSessionTimer(); // Reset timer on navigation
    switch (index) {
      case 0:
        // Dashboard - already on it
        break;
      case 1:
        // Navigate to Customers
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomerPage()),
        );
        break;
      case 2:
        // Availability - not implemented yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability page coming soon')),
        );
        break;
      case 3:
        // Bills - not implemented yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bills page coming soon')),
        );
        break;
      case 4:
        // Purchases - not implemented yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases page coming soon')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _resetSessionTimer(); // Reset timer on every rebuild (user interaction)

    return Scaffold(
      backgroundColor: const Color(0xFFE6EDE7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            // Logo image
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            // App name
            const Text(
              'C-Billing',
              style: TextStyle(
                color: Color(0xFF1B4D3E),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: _logout,
              ),
            ],
            icon: const Icon(Icons.menu, color: Color(0xFF1B4D3E)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Sales & Profit Analysis header
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Sales & Profit Analysis',
                      style: TextStyle(
                        color: Color(0xFF1B4D3E),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Date and filter controls
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFebf3f7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF81D4FA),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'January 2026',
                        style: TextStyle(
                          color: Color(0xFF0277BD),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune, color: Color(0xFF0D47A1)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.calendar_today, color: Color(0xFF0D47A1)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Sales Card
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Sales',
                      amount: '₹20.4 K',
                      subtitle: 'Bills: 7 • Items: 20',
                      backgroundColor: const Color(0xFFebf3f7),
                      iconColor: const Color(0xFF1565C0),
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Purchase',
                      amount: '₹1.4 L',
                      subtitle: 'Orders: 3 • Qty: 445',
                      backgroundColor: const Color(0xFFfaf1e6),
                      iconColor: const Color(0xFFE65100),
                      icon: Icons.shopping_bag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profit Card
              _buildMetricCard(
                title: 'Profit',
                amount: '₹5.7 K',
                subtitle: '',
                backgroundColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF1B5E20),
                icon: Icons.trending_up,
                isFullWidth: true,
              ),
              const SizedBox(height: 24),

              // Inventory & Payments Section
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF81C784),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory & Payments',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Literata',
                          ),
                        ),
                        Text(
                          'Live status',
                          style: TextStyle(
                            color: const Color(0xFF1B5E20).withOpacity(0.7),
                            fontSize: 12,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Availability Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC8E6C9),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Availability',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Literata',
                              ),
                            ),
                            Text(
                              'Current Stock Overview',
                              style: TextStyle(
                                color: const Color(0xFF1B5E20).withOpacity(0.6),
                                fontSize: 12,
                                fontFamily: 'Literata',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfaf1e6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '3 Available\nProducts',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInventoryMetric(
                            title: 'Total Quantity',
                            value: '426',
                            subtitle: 'items in stock',
                            backgroundColor: const Color(0xFFE8F5E9),
                            icon: Icons.shopping_cart,
                            iconColor: const Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryMetric(
                            title: 'Total Amount',
                            value: '₹1.3 L',
                            subtitle: 'stock value',
                            backgroundColor: const Color(0xFFebf3f7),
                            icon: Icons.currency_rupee,
                            iconColor: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upcoming Payments
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFebf3f7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBBDEFB),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming Payments',
                          style: TextStyle(
                            color: Color(0xFF0D47A1),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Literata',
                          ),
                        ),
                        Text(
                          'Manage your finances',
                          style: TextStyle(
                            color: const Color(0xFF0D47A1).withOpacity(0.6),
                            fontSize: 12,
                            fontFamily: 'Literata',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '1 Due',
                        style: TextStyle(
                          color: Color.fromARGB(255, 109, 161, 13),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _navigateToPage(index);
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1B4D3E),
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('3'),
              child: Icon(Icons.inventory_2),
            ),
            label: 'Availability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Purchases',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: iconColor.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Literata',
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: iconColor,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: iconColor.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Literata',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryMetric({
    required String title,
    required String value,
    required String subtitle,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Literata',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: iconColor.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }
}
