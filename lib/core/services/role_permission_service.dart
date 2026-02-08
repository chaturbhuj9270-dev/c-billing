import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';
import 'shop_access_service.dart';

/// Service for managing roles, permissions, and user permissions.
/// 
/// Enforces shop-scoped access and validates all operations against the current shop.
class RolePermissionService {
  final FirebaseFirestore _firestore;
  final ShopAccessService _shopAccessService;

  RolePermissionService({
    FirebaseFirestore? firestore,
    ShopAccessService? shopAccessService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _shopAccessService = shopAccessService ?? ShopAccessService();

  /// Creates a new role within a shop.
  /// 
  /// Returns the created Role.
  /// Throws [ShopAccessDeniedException] if shop validation fails.
  Future<Role> createRole({
    required String shopId,
    required String name,
    required String description,
    required List<String> permissionIds,
  }) async {
    // Validate shop exists
    await _shopAccessService.validateShopExists(shopId);

    // Validate all permissions belong to the shop
    for (final permissionId in permissionIds) {
      await _shopAccessService.validatePermissionShopAccess(
        permissionId: permissionId,
        shopId: shopId,
      );
    }

    try {
      final docRef = _firestore.collection('roles').doc();
      final now = DateTime.now();

      final role = Role(
        id: docRef.id,
        shopId: shopId,
        name: name,
        description: description,
        permissionIds: permissionIds,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await docRef.set(role.toFirestore());
      return role;
    } catch (e) {
      throw ShopAccessDeniedException('Error creating role: $e');
    }
  }

  /// Updates an existing role.
  /// 
  /// Returns the updated Role.
  /// Throws [ShopAccessDeniedException] if shop validation fails.
  Future<Role> updateRole({
    required String roleId,
    required String shopId,
    String? name,
    String? description,
    List<String>? permissionIds,
  }) async {
    // Validate role belongs to shop
    await _shopAccessService.validateRoleShopAccess(
      roleId: roleId,
      shopId: shopId,
    );

    try {
      final docRef = _firestore.collection('roles').doc(roleId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw ShopAccessDeniedException('Role $roleId not found');
      }

      final currentRole = Role.fromFirestore(doc);

      // Validate all new permissions belong to the shop
      if (permissionIds != null) {
        for (final permissionId in permissionIds) {
          await _shopAccessService.validatePermissionShopAccess(
            permissionId: permissionId,
            shopId: shopId,
          );
        }
      }

      final updatedRole = currentRole.copyWith(
        name: name,
        description: description,
        permissionIds: permissionIds,
        updatedAt: DateTime.now(),
      );

      await docRef.update(updatedRole.toFirestore());
      return updatedRole;
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error updating role: $e');
    }
  }

  /// Deletes a role (soft delete by setting isActive to false).
  /// 
  /// Throws [ShopAccessDeniedException] if shop validation fails.
  Future<void> deleteRole({
    required String roleId,
    required String shopId,
  }) async {
    // Validate role belongs to shop
    await _shopAccessService.validateRoleShopAccess(
      roleId: roleId,
      shopId: shopId,
    );

    try {
      await _firestore
          .collection('roles')
          .doc(roleId)
          .update({'isActive': false, 'updatedAt': DateTime.now()});
    } catch (e) {
      throw ShopAccessDeniedException('Error deleting role: $e');
    }
  }

  /// Gets a role by ID with shop validation.
  /// 
  /// Returns the Role or null if not found.
  Future<Role?> getRole({
    required String roleId,
    required String shopId,
  }) async {
    // Validate role belongs to shop
    await _shopAccessService.validateRoleShopAccess(
      roleId: roleId,
      shopId: shopId,
    );

    try {
      final doc = await _firestore
          .collection('roles')
          .doc(roleId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Role.fromFirestore(doc);
    } catch (e) {
      throw ShopAccessDeniedException('Error fetching role: $e');
    }
  }

  /// Gets all active roles for a shop.
  Future<List<Role>> getShopRoles(String shopId) async {
    // Validate shop exists
    await _shopAccessService.validateShopExists(shopId);

    try {
      final snapshot = await _firestore
          .collection('roles')
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Role.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShopAccessDeniedException('Error fetching shop roles: $e');
    }
  }

  /// Gets roles for a specific user within a shop.
  /// 
  /// Returns a list of Role objects that the user has been assigned.
  Future<List<Role>> getUserRoles({
    required String userId,
    required String shopId,
  }) async {
    // Validate user belongs to shop
    await _shopAccessService.validateUserShopAccess(
      userId: userId,
      shopId: shopId,
    );

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final roleIds = List<String>.from(userData['roleIds'] ?? []);

      if (roleIds.isEmpty) {
        return [];
      }

      final snapshot = await _firestore
          .collection('roles')
          .where('shopId', isEqualTo: shopId)
          .where('id', whereIn: roleIds)
          .get();

      return snapshot.docs
          .map((doc) => Role.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ShopAccessDeniedException('Error fetching user roles: $e');
    }
  }

  /// Assigns a role to a user.
  /// 
  /// Validates that both user, role, and shop are properly linked.
  Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
    required String shopId,
  }) async {
    // Validate user belongs to shop
    await _shopAccessService.validateUserShopAccess(
      userId: userId,
      shopId: shopId,
    );

    // Validate role belongs to shop
    await _shopAccessService.validateRoleShopAccess(
      roleId: roleId,
      shopId: shopId,
    );

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw ShopAccessDeniedException('User $userId not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final roleIds = List<String>.from(userData['roleIds'] ?? []);

      if (!roleIds.contains(roleId)) {
        roleIds.add(roleId);
        await _firestore
            .collection('users')
            .doc(userId)
            .update({
              'roleIds': roleIds,
              'updatedAt': DateTime.now(),
            });
      }
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error assigning role: $e');
    }
  }

  /// Removes a role from a user.
  Future<void> removeRoleFromUser({
    required String userId,
    required String roleId,
    required String shopId,
  }) async {
    // Validate user belongs to shop
    await _shopAccessService.validateUserShopAccess(
      userId: userId,
      shopId: shopId,
    );

    // Validate role belongs to shop
    await _shopAccessService.validateRoleShopAccess(
      roleId: roleId,
      shopId: shopId,
    );

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw ShopAccessDeniedException('User $userId not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final roleIds = List<String>.from(userData['roleIds'] ?? []);

      roleIds.remove(roleId);
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'roleIds': roleIds,
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error removing role: $e');
    }
  }

  /// Checks if a user has a specific permission.
  /// 
  /// Traverses user → roles → permissions to check if user has permission.
  Future<bool> userHasPermission({
    required String userId,
    required String permissionCode,
    required String shopId,
  }) async {
    try {
      // Get user's roles
      final userRoles = await getUserRoles(
        userId: userId,
        shopId: shopId,
      );

      // Get all permission IDs from user's roles
      final permissionIds = <String>{};
      for (final role in userRoles) {
        permissionIds.addAll(role.permissionIds);
      }

      if (permissionIds.isEmpty) {
        return false;
      }

      // Check if any of the permissions match the code
      final snapshot = await _firestore
          .collection('permissions')
          .where('shopId', isEqualTo: shopId)
          .where('code', isEqualTo: permissionCode)
          .where('id', whereIn: permissionIds.toList())
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Gets all permissions for a user.
  /// 
  /// Returns a flattened list of all permissions from all roles assigned to the user.
  Future<List<String>> getUserPermissions({
    required String userId,
    required String shopId,
  }) async {
    try {
      // Get user's roles
      final userRoles = await getUserRoles(
        userId: userId,
        shopId: shopId,
      );

      // Collect all permission IDs
      final permissionIds = <String>{};
      for (final role in userRoles) {
        permissionIds.addAll(role.permissionIds);
      }

      return permissionIds.toList();
    } catch (e) {
      return [];
    }
  }
}
