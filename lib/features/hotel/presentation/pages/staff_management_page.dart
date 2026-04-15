import 'package:flutter/material.dart';

import '../../data/auth/hotel_auth_service.dart';
import '../../data/auth/hotel_sub_user.dart';
import '../../data/auth/hotel_roles.dart';
import 'staff_credential_form_page.dart';
import 'staff_detail_page.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage>
    with SingleTickerProviderStateMixin {
  final _authService = HotelAuthService.instance;
  final _searchController = TextEditingController();
  HotelUserRole? _filterRole;
  String _searchQuery = '';

  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    Future.delayed(
      const Duration(milliseconds: 400),
      () => _fabAnimController.forward(),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<HotelSubUser> _applyFilters(List<HotelSubUser> users) {
    var filtered = users;
    if (_filterRole != null) {
      filtered = filtered.where((u) => u.role == _filterRole).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (u) =>
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                u.staffId.toLowerCase().contains(q) ||
                u.role.label.toLowerCase().contains(q),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: StreamBuilder<List<HotelSubUser>>(
        stream: _authService.watchSubUsers(),
        builder: (context, snapshot) {
          final allUsers = snapshot.data ?? [];
          final filtered = _applyFilters(allUsers);

          final activeCount = allUsers.where((u) => u.isActive).length;

          return CustomScrollView(
            slivers: [
              // ─── HEADER ───
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B4D3E), Color(0xFF0F3B2F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top row: back + title + actions
                          Row(
                            children: [
                              if (Navigator.canPop(context))
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              if (Navigator.canPop(context))
                                const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Staff Management',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Literata',
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      '$activeCount active · ${allUsers.length} total members',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 11,
                                        fontFamily: 'Literata',
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── STATS HEADER ───
              SliverToBoxAdapter(child: _buildStatsRow(allUsers)),

              // ─── SEARCH & FILTER ───
              SliverToBoxAdapter(child: _buildSearchFilter(theme)),

              // ─── CONTENT ───
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (allUsers.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(theme))
              else if (filtered.isEmpty)
                SliverFillRemaining(child: _buildNoResultsState(theme))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildStaffCard(theme, filtered[index], index),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: FloatingActionButton.extended(
          onPressed: _navigateToCreate,
          backgroundColor: const Color(0xFF1B4D3E),
          elevation: 6,
          icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
          label: const Text(
            'Add Staff',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATS ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsRow(List<HotelSubUser> users) {
    final active = users.where((u) => u.isActive).length;
    final inactive = users.length - active;
    final departments = users.map((u) => u.department).toSet().length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.people,
            label: 'Total',
            value: '${users.length}',
            color: const Color(0xFF1B4D3E),
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.check_circle,
            label: 'Active',
            value: '$active',
            color: const Color(0xFF43A047),
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.person_off,
            label: 'Inactive',
            value: '$inactive',
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.business,
            label: 'Depts',
            value: '$departments',
            color: const Color(0xFF8E24AA),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SEARCH & FILTER BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchFilter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or staff ID...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4D3E)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Role filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterRole == null,
                  onTap: () => setState(() => _filterRole = null),
                ),
                const SizedBox(width: 6),
                ...HotelUserRole.values
                    .where((r) => r != HotelUserRole.admin)
                    .map(
                      (role) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: role.label,
                          isSelected: _filterRole == role,
                          color: _roleColor(role),
                          onTap: () => setState(
                            () =>
                                _filterRole = _filterRole == role ? null : role,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STAFF CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStaffCard(ThemeData theme, HotelSubUser user, int index) {
    final roleColor = _roleColor(user.role);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToDetail(user),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: !user.isActive
                ? Border.all(color: Colors.red.shade200, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              fontFamily: 'Literata',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Sync status icon (green=synced, orange=pending)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            user.firebaseUid.isNotEmpty
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_upload_rounded,
                            size: 16,
                            color: user.firebaseUid.isNotEmpty
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        if (!user.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email.isNotEmpty ? user.email : user.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user.role.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Department badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.department.icon,
                                size: 10,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                user.department.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user.staffId.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            user.staffId,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMPTY STATES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: const Color(0xFF1B4D3E).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Staff Members Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first staff member with\nsecure credentials and permissions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add First Staff'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No matches found',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or filter',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION
  // ═══════════════════════════════════════════════════════════════
  Future<void> _navigateToCreate() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const StaffCredentialFormPage()),
    );
  }

  Future<void> _navigateToDetail(HotelSubUser user) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StaffDetailPage(user: user)),
    );
  }

  Color _roleColor(HotelUserRole role) {
    switch (role) {
      case HotelUserRole.admin:
        return const Color(0xFF1B4D3E);
      case HotelUserRole.waiter:
        return const Color(0xFF43A047);
      case HotelUserRole.cook:
        return const Color(0xFFEF6C00);
      case HotelUserRole.captain:
        return const Color(0xFF8E24AA);
      case HotelUserRole.receptionist:
        return const Color(0xFF00897B);
      case HotelUserRole.manager:
        return const Color(0xFF2E7D5B);
      case HotelUserRole.housekeeping:
        return const Color(0xFF5D4037);
      case HotelUserRole.custom:
        return const Color(0xFF757575);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1B4D3E);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c : Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
