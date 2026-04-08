import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/hotel_auth_service.dart';
import '../../../../core/auth/hotel_roles.dart';
import '../../../authentication/presentation/pages/login.dart';
import '../pages/staff_management_page.dart';

class HotelDashboardPage extends StatefulWidget {
  const HotelDashboardPage({super.key});

  @override
  State<HotelDashboardPage> createState() => _HotelDashboardPageState();
}

class _HotelDashboardPageState extends State<HotelDashboardPage> {
  final _auth = HotelAuthService.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = _auth.isAdmin;
    final subUser = _auth.currentSubUser;
    final greeting = isAdmin
        ? 'Welcome, Admin'
        : 'Welcome, ${subUser?.name ?? 'Staff'}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme, greeting, user),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin || _auth.hasAccess(HotelModule.dashboard))
                    _buildQuickStatsRow(theme),
                  const SizedBox(height: 24),
                  Text(
                    'Modules',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModulesGrid(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, String greeting, User? user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F), Color(0xFF134E3A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  if (!_auth.isAdmin && _auth.currentSubUser != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _auth.currentSubUser!.role.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_auth.isAdmin)
          IconButton(
            icon: const Icon(Icons.people_outline, color: Colors.white),
            tooltip: 'Staff Management',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffManagementPage()),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow(ThemeData theme) {
    return Row(
      children: [
        _buildStatCard(
          theme,
          'Active Tables',
          '0',
          Icons.table_restaurant,
          const Color(0xFF43A047),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          theme,
          'Pending Orders',
          '0',
          Icons.receipt_long,
          const Color(0xFFEF6C00),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          theme,
          "Today's Revenue",
          '₹0',
          Icons.currency_rupee,
          const Color(0xFF1B4D3E),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid(ThemeData theme) {
    final modules = _getAccessibleModules();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleTile(theme, module);
      },
    );
  }

  List<HotelModule> _getAccessibleModules() {
    if (_auth.isAdmin) return HotelModule.values;
    return HotelModule.values.where((m) => _auth.hasAccess(m)).toList();
  }

  Widget _buildModuleTile(ThemeData theme, HotelModule module) {
    final color = _moduleColor(module);
    final icon = _moduleIcon(module);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onModuleTap(module),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  module.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    // For now show a placeholder; feature pages will be added as built
    if (module == HotelModule.staffManagement && _auth.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StaffManagementPage()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${module.label} coming soon'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _logout() {
    _auth.clearSession();
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPageV2()),
      (route) => false,
    );
  }
}
