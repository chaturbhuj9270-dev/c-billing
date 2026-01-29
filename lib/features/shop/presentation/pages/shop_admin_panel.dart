import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/shop_user.dart';
import '../../../../core/models/role.dart';
import '../../../../core/services/user_management_service.dart';
import '../../../../core/services/role_permission_service.dart';
import '../../../../core/services/shop_access_service.dart';

// ==========================================
// BLoC for Admin/Main User Shop Management
// ==========================================

abstract class ShopManagementEvent {}

class LoadShopUsersEvent extends ShopManagementEvent {
  final String shopId;
  LoadShopUsersEvent(this.shopId);
}

class LoadShopRolesEvent extends ShopManagementEvent {
  final String shopId;
  LoadShopRolesEvent(this.shopId);
}

class CreateSubUserEvent extends ShopManagementEvent {
  final ShopUser user;
  CreateSubUserEvent(this.user);
}

class AssignRoleToUserEvent extends ShopManagementEvent {
  final String userId;
  final String roleId;
  AssignRoleToUserEvent(this.userId, this.roleId);
}

abstract class ShopManagementState {}

class ShopManagementInitial extends ShopManagementState {}

class ShopManagementLoading extends ShopManagementState {}

class ShopUsersLoaded extends ShopManagementState {
  final List<ShopUser> users;
  ShopUsersLoaded(this.users);
}

class ShopRolesLoaded extends ShopManagementState {
  final List<Role> roles;
  ShopRolesLoaded(this.roles);
}

class ShopManagementSuccess extends ShopManagementState {
  final String message;
  ShopManagementSuccess(this.message);
}

class ShopManagementError extends ShopManagementState {
  final String error;
  ShopManagementError(this.error);
}

class ShopManagementBloc extends Bloc<ShopManagementEvent, ShopManagementState> {
  final UserManagementService userManagementService;
  final RolePermissionService rolePermissionService;
  final ShopAccessService shopAccessService;
  final String currentUserId;

  ShopManagementBloc({
    required this.userManagementService,
    required this.rolePermissionService,
    required this.shopAccessService,
    required this.currentUserId,
  }) : super(ShopManagementInitial()) {
    on<LoadShopUsersEvent>(_onLoadShopUsers);
    on<LoadShopRolesEvent>(_onLoadShopRoles);
    on<CreateSubUserEvent>(_onCreateSubUser);
    on<AssignRoleToUserEvent>(_onAssignRoleToUser);
  }

  Future<void> _onLoadShopUsers(
    LoadShopUsersEvent event,
    Emitter<ShopManagementState> emit,
  ) async {
    try {
      emit(ShopManagementLoading());
      final users = await userManagementService.getShopUsers(event.shopId);
      emit(ShopUsersLoaded(users));
    } catch (e) {
      emit(ShopManagementError(e.toString()));
    }
  }

  Future<void> _onLoadShopRoles(
    LoadShopRolesEvent event,
    Emitter<ShopManagementState> emit,
  ) async {
    try {
      emit(ShopManagementLoading());
      final roles = await rolePermissionService.getShopRoles(event.shopId);
      emit(ShopRolesLoaded(roles));
    } catch (e) {
      emit(ShopManagementError(e.toString()));
    }
  }

  Future<void> _onCreateSubUser(
    CreateSubUserEvent event,
    Emitter<ShopManagementState> emit,
  ) async {
    try {
      emit(ShopManagementLoading());
      await userManagementService.createSubUser(
        mainUserId: currentUserId,
        shopId: event.user.shopId,
        firstName: event.user.firstName,
        middleName: event.user.middleName,
        lastName: event.user.lastName,
        email: event.user.email,
        phone: event.user.phone,
        address: event.user.address,
        roleIds: event.user.roleIds,
        subUserId: event.user.id,
      );
      emit(ShopManagementSuccess('Sub user created successfully'));
    } catch (e) {
      emit(ShopManagementError(e.toString()));
    }
  }

  Future<void> _onAssignRoleToUser(
    AssignRoleToUserEvent event,
    Emitter<ShopManagementState> emit,
  ) async {
    try {
      emit(ShopManagementLoading());
      // Get user's shop ID first
      final shopId = await shopAccessService.getUserShopId(event.userId);
      if (shopId != null) {
        await rolePermissionService.assignRoleToUser(
          userId: event.userId,
          roleId: event.roleId,
          shopId: shopId,
        );
        emit(ShopManagementSuccess('Role assigned successfully'));
      } else {
        emit(ShopManagementError('User shop not found'));
      }
    } catch (e) {
      emit(ShopManagementError(e.toString()));
    }
  }
}

// ==========================================
// Shop Admin/Management Panel Page
// ==========================================

class ShopAdminPanelPage extends StatefulWidget {
  final String shopId;
  final String currentUserId;

  const ShopAdminPanelPage({
    required this.shopId,
    required this.currentUserId,
    super.key,
  });

  @override
  State<ShopAdminPanelPage> createState() => _ShopAdminPanelPageState();
}

class _ShopAdminPanelPageState extends State<ShopAdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load initial data
    context.read<ShopManagementBloc>().add(LoadShopUsersEvent(widget.shopId));
    context.read<ShopManagementBloc>().add(LoadShopRolesEvent(widget.shopId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Administration'),
        backgroundColor: const Color(0xFF1B4D3E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.security),
              text: 'Roles',
            ),
          ],
        ),
      ),
      body: BlocListener<ShopManagementBloc, ShopManagementState>(
        listener: (context, state) {
          if (state is ShopManagementSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Reload data
            context
                .read<ShopManagementBloc>()
                .add(LoadShopUsersEvent(widget.shopId));
          } else if (state is ShopManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // Users Tab
            _buildUsersTab(context),
            // Roles Tab
            _buildRolesTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    return BlocBuilder<ShopManagementBloc, ShopManagementState>(
      buildWhen: (previous, current) => current is ShopUsersLoaded,
      builder: (context, state) {
        if (state is ShopManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ShopUsersLoaded) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAddSubUserDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Sub User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                ...state.users.map((user) => _buildUserCard(context, user)).toList(),
              ],
            ),
          );
        }

        if (state is ShopManagementError) {
          return Center(
            child: Text('Error: ${state.error}'),
          );
        }

        return const Center(child: Text('No users found'));
      },
    );
  }

  Widget _buildUserCard(BuildContext context, ShopUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: Wrap(
          spacing: 8,
          children: [
            if (user.isSubUser)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditSubUserDialog(context, user);
                },
              ),
            if (user.isSubUser)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _showDeleteUserConfirmation(context, user);
                },
              ),
          ],
        ),
        leading: Chip(
          label: Text(user.isMainUser ? 'Main User' : 'Sub User'),
          backgroundColor: user.isMainUser ? Colors.blue : Colors.grey,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRolesTab(BuildContext context) {
    return BlocBuilder<ShopManagementBloc, ShopManagementState>(
      buildWhen: (previous, current) => current is ShopRolesLoaded,
      builder: (context, state) {
        if (state is ShopManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ShopRolesLoaded) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCreateRoleDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Role'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                ...state.roles.map((role) => _buildRoleCard(context, role)).toList(),
              ],
            ),
          );
        }

        if (state is ShopManagementError) {
          return Center(
            child: Text('Error: ${state.error}'),
          );
        }

        return const Center(child: Text('No roles found'));
      },
    );
  }

  Widget _buildRoleCard(BuildContext context, Role role) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(role.name),
        subtitle: Text(role.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissions: ${role.permissionIds.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: role.permissionIds
                      .map((permId) => Chip(label: Text(permId)))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSubUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddSubUserDialog(),
    );
  }

  void _showEditSubUserDialog(BuildContext context, ShopUser user) {
    showDialog(
      context: context,
      builder: (context) => EditSubUserDialog(user: user),
    );
  }

  void _showDeleteUserConfirmation(BuildContext context, ShopUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle delete
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateRoleDialog(),
    );
  }
}

// ==========================================
// Dialog Widgets for Management Operations
// ==========================================

class AddSubUserDialog extends StatefulWidget {
  const AddSubUserDialog({super.key});

  @override
  State<AddSubUserDialog> createState() => _AddSubUserDialogState();
}

class _AddSubUserDialogState extends State<AddSubUserDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sub User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4D3E),
          ),
          onPressed: () {
            // Handle create sub user
            Navigator.pop(context);
          },
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class EditSubUserDialog extends StatefulWidget {
  final ShopUser user;

  const EditSubUserDialog({required this.user, super.key});

  @override
  State<EditSubUserDialog> createState() => _EditSubUserDialogState();
}

class _EditSubUserDialogState extends State<EditSubUserDialog> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Sub User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4D3E),
          ),
          onPressed: () {
            // Handle update
            Navigator.pop(context);
          },
          child: const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}

class CreateRoleDialog extends StatefulWidget {
  const CreateRoleDialog({super.key});

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Role'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4D3E),
          ),
          onPressed: () {
            // Handle create role
            Navigator.pop(context);
          },
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
