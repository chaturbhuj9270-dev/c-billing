import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/hotel_auth_service.dart';
import '../../../../core/auth/hotel_roles.dart';
import '../../../../core/auth/hotel_sub_user.dart';
import '../../../../core/ui/glassy_toast.dart';
import 'staff_credential_form_page.dart';

/// Full-screen staff detail page with profile, permissions, and admin actions.
class StaffDetailPage extends StatefulWidget {
  final HotelSubUser user;

  const StaffDetailPage({super.key, required this.user});

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  final _authService = HotelAuthService.instance;
  late HotelSubUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Color get _roleColor {
    switch (_user.role) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: CustomScrollView(
        slivers: [
          // ─── HERO HEADER ───
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _navigateToEdit,
                icon: const Icon(Icons.edit_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _roleColor,
                      _roleColor.withOpacity(0.7),
                      const Color(0xFF1B4D3E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _user.name.isNotEmpty
                                ? _user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _user.role.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _user.department.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!_user.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── BODY CONTENT ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── QUICK INFO CARDS ───
                  Row(
                    children: [
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Staff ID',
                        value: _user.staffId.isNotEmpty ? _user.staffId : 'N/A',
                      ),
                      const SizedBox(width: 12),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joined',
                        value: _formatDate(_user.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── CONTACT INFO ───
                  _SectionLabel(title: 'Contact Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _user.email,
                      onCopy: () => _copy(_user.email, 'Email'),
                    ),
                    if (_user.phone.isNotEmpty)
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: _user.phone,
                        onCopy: () => _copy(_user.phone, 'Phone'),
                      ),
                  ]),
                  const SizedBox(height: 24),

                  // ─── PERMISSIONS ───
                  _SectionLabel(
                    title: 'Module Permissions',
                    trailing:
                        '${_user.allowedModules.length} / ${HotelModule.values.length}',
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionsCard(theme),
                  const SizedBox(height: 24),

                  // ─── ADMIN ACTIONS ───
                  _SectionLabel(title: 'Admin Actions'),
                  const SizedBox(height: 12),
                  _buildActionsCard(theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            children.expand((w) => [w, const Divider(height: 16)]).toList()
              ..removeLast(),
      ),
    );
  }

  Widget _buildPermissionsCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _user.allowedModules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No permissions assigned',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HotelModule.values.map((module) {
                final hasAccess = _user.allowedModules.contains(module);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: hasAccess
                        ? const Color(0xFF1B4D3E).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasAccess
                          ? const Color(0xFF1B4D3E).withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasAccess ? Icons.check_circle : Icons.cancel_outlined,
                        size: 14,
                        color: hasAccess
                            ? const Color(0xFF1B4D3E)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        module.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasAccess
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: hasAccess
                              ? const Color(0xFF1B4D3E)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildActionsCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Staff Details',
            subtitle: 'Name, phone, role, department',
            onTap: _navigateToEdit,
          ),
          const Divider(height: 1, indent: 56),
          _ActionTile(
            icon: Icons.security_outlined,
            label: 'Update Permissions',
            subtitle: 'Modify module access',
            onTap: _showPermissionsDialog,
          ),
          const Divider(height: 1, indent: 56),
          _ActionTile(
            icon: _user.isActive ? Icons.person_off_outlined : Icons.person,
            label: _user.isActive ? 'Deactivate Account' : 'Activate Account',
            subtitle: _user.isActive
                ? 'Revoke access immediately'
                : 'Restore staff access',
            color: _user.isActive ? Colors.orange.shade700 : Colors.green,
            onTap: _toggleActive,
          ),
          const Divider(height: 1, indent: 56),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete Staff',
            subtitle: 'Permanently remove this account',
            color: Colors.red,
            onTap: _confirmDelete,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StaffCredentialFormPage(existing: _user),
      ),
    );
    if (result == true && mounted) {
      // Refresh user data
      final users = await _authService.getSubUsers();
      final updated = users.where((u) => u.id == _user.id).firstOrNull;
      if (updated != null) {
        setState(() => _user = updated);
      }
    }
  }

  Future<void> _showPermissionsDialog() async {
    var selectedModules = List<HotelModule>.from(_user.allowedModules);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFF1B4D3E), size: 22),
                const SizedBox(width: 10),
                const Text('Edit Permissions'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: HotelModule.values.map((module) {
                  final isSelected = selectedModules.contains(module);
                  return CheckboxListTile(
                    title: Text(module.label),
                    value: isSelected,
                    dense: true,
                    activeColor: const Color(0xFF1B4D3E),
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedModules.add(module);
                        } else {
                          selectedModules.remove(module);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      await _authService.updateSubUser(
        _user.copyWith(allowedModules: selectedModules),
      );
      setState(() => _user = _user.copyWith(allowedModules: selectedModules));
      if (mounted) {
        GlassyToast.show(context, 'Permissions updated');
      }
    }
  }

  Future<void> _toggleActive() async {
    final newStatus = !_user.isActive;
    final action = newStatus ? 'activate' : 'deactivate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${newStatus ? 'Activate' : 'Deactivate'} Staff'),
        content: Text(
          'Are you sure you want to $action ${_user.name}?'
          '${newStatus ? '' : ' They will lose all access immediately.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: newStatus ? const Color(0xFF1B4D3E) : Colors.red,
            ),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (newStatus) {
        await _authService.updateSubUser(_user.copyWith(isActive: true));
      } else {
        await _authService.deactivateSubUser(_user.id);
      }
      setState(() => _user = _user.copyWith(isActive: newStatus));
      if (mounted) {
        GlassyToast.show(
          context,
          '${_user.name} ${newStatus ? 'activated' : 'deactivated'}',
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade600),
            const SizedBox(width: 10),
            const Text('Delete Staff'),
          ],
        ),
        content: Text(
          'Permanently delete ${_user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.deleteSubUser(_user.id);
      if (mounted) {
        GlassyToast.show(context, '${_user.name} deleted');
        Navigator.pop(context, true);
      }
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    GlassyToast.show(context, '$label copied');
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B4D3E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Icon(Icons.copy, size: 16, color: Colors.grey.shade400),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionLabel({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1B4D3E);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: c),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
