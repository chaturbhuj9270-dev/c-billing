import 'package:flutter/material.dart';

import '../../../../core/auth/hotel_auth_service.dart';
import '../../../../core/auth/hotel_sub_user.dart';
import '../../../../core/auth/hotel_roles.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _authService = HotelAuthService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: StreamBuilder<List<HotelSubUser>>(
        stream: _authService.watchSubUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: users.length,
            itemBuilder: (context, index) =>
                _buildStaffCard(theme, users[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No staff members yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first staff member',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(ThemeData theme, HotelSubUser user) {
    final roleColor = _roleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email.isNotEmpty ? user.email : user.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.label,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (val) => _onMenuAction(val, user),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'permissions',
                      child: ListTile(
                        leading: Icon(Icons.security),
                        title: Text('Permissions'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: user.isActive ? 'deactivate' : 'activate',
                      child: ListTile(
                        leading: Icon(
                          user.isActive ? Icons.person_off : Icons.person,
                          color: user.isActive ? Colors.red : Colors.green,
                        ),
                        title: Text(user.isActive ? 'Deactivate' : 'Activate'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (user.allowedModules.isNotEmpty &&
                user.role != HotelUserRole.admin) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: user.allowedModules.map((m) {
                  return Chip(
                    label: Text(m.label, style: const TextStyle(fontSize: 10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  );
                }).toList(),
              ),
            ],
            if (!user.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'INACTIVE',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
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

  void _onMenuAction(String action, HotelSubUser user) {
    switch (action) {
      case 'edit':
        _showAddEditDialog(context, existing: user);
        break;
      case 'permissions':
        _showPermissionsDialog(context, user);
        break;
      case 'deactivate':
        _confirmDeactivate(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
    }
  }

  Future<void> _confirmDeactivate(HotelSubUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Staff'),
        content: Text('Deactivate ${user.name}? They will lose access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.deactivateSubUser(user.id);
    }
  }

  Future<void> _activateUser(HotelSubUser user) async {
    await _authService.updateSubUser(user.copyWith(isActive: true));
  }

  // ==================== ADD/EDIT DIALOG ====================

  Future<void> _showAddEditDialog(
    BuildContext context, {
    HotelSubUser? existing,
  }) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final passwordCtrl = TextEditingController();
    var selectedRole = existing?.role ?? HotelUserRole.waiter;
    bool obscurePassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Staff' : 'Add Staff'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: const Icon(Icons.email),
                      helperText: isEdit ? 'Cannot change email' : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    readOnly: isEdit,
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                        helperText: 'Min 6 characters',
                      ),
                      obscureText: obscurePassword,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<HotelUserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: HotelUserRole.values
                        .where((r) => r != HotelUserRole.admin)
                        .map(
                          (r) =>
                              DropdownMenuItem(value: r, child: Text(r.label)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and Email are required')),
        );
      }
      return;
    }

    if (!isEdit && password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters'),
          ),
        );
      }
      return;
    }

    try {
      if (isEdit) {
        await _authService.updateSubUser(
          existing.copyWith(
            name: name,
            phone: phoneCtrl.text.trim(),
            role: selectedRole,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff updated successfully')),
          );
        }
      } else {
        final defaultModules = _defaultModulesForRole(selectedRole);
        await _authService.createSubUserWithCredentials(
          name: name,
          email: email,
          password: password,
          phone: phoneCtrl.text.trim(),
          role: selectedRole,
          allowedModules: defaultModules,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Staff "$name" created with email: $email')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<HotelModule> _defaultModulesForRole(HotelUserRole role) {
    switch (role) {
      case HotelUserRole.admin:
        return HotelModule.values;
      case HotelUserRole.waiter:
        return [
          HotelModule.dashboard,
          HotelModule.tableManagement,
          HotelModule.orderManagement,
        ];
      case HotelUserRole.cook:
        return [HotelModule.kitchenDisplay, HotelModule.orderManagement];
      case HotelUserRole.captain:
        return [
          HotelModule.dashboard,
          HotelModule.tableManagement,
          HotelModule.orderManagement,
          HotelModule.menuManagement,
          HotelModule.billing,
        ];
      case HotelUserRole.receptionist:
        return [
          HotelModule.dashboard,
          HotelModule.roomManagement,
          HotelModule.guestManagement,
          HotelModule.billing,
        ];
      case HotelUserRole.manager:
        return [
          HotelModule.dashboard,
          HotelModule.tableManagement,
          HotelModule.orderManagement,
          HotelModule.billing,
          HotelModule.reports,
          HotelModule.staffManagement,
          HotelModule.expenses,
        ];
      case HotelUserRole.housekeeping:
        return [HotelModule.roomManagement];
      case HotelUserRole.custom:
        return [HotelModule.dashboard];
    }
  }

  // ==================== PERMISSIONS DIALOG ====================

  Future<void> _showPermissionsDialog(
    BuildContext context,
    HotelSubUser user,
  ) async {
    var selectedModules = List<HotelModule>.from(user.allowedModules);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Permissions: ${user.name}'),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      await _authService.updateSubUser(
        user.copyWith(allowedModules: selectedModules),
      );
    }
  }
}
