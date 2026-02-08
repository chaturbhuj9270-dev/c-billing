import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_access_service.dart';
import 'user_management_service.dart';
import 'role_permission_service.dart';

/// Example API/Service endpoints for multi-tenant shop system.
/// 
/// This demonstrates best practices for:
/// - Creating/managing sub users
/// - Assigning roles and permissions
/// - Fetching shop-scoped data
/// - Enforcing shop access validation
class MultiTenantApiService {
  final FirebaseFirestore _firestore;
  final ShopAccessService _shopAccessService;
  final UserManagementService _userManagementService;
  final RolePermissionService _rolePermissionService;

  MultiTenantApiService({
    FirebaseFirestore? firestore,
    ShopAccessService? shopAccessService,
    UserManagementService? userManagementService,
    RolePermissionService? rolePermissionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _shopAccessService = shopAccessService ?? ShopAccessService(),
        _userManagementService =
            userManagementService ?? UserManagementService(),
        _rolePermissionService =
            rolePermissionService ?? RolePermissionService();

  // ==========================================
  // USER MANAGEMENT ENDPOINTS
  // ==========================================

  /// [POST] /api/users/sub-user
  /// Create a new sub user in a shop.
  /// 
  /// Request body:
  /// {
  ///   "mainUserId": "current_user_uid",
  ///   "shopId": "shop_123",
  ///   "subUserId": "new_user_uid",
  ///   "firstName": "John",
  ///   "middleName": "M",
  ///   "lastName": "Doe",
  ///   "email": "john@example.com",
  ///   "phone": "9876543210",
  ///   "address": "123 Main St",
  ///   "roleIds": ["role_1", "role_2"]
  /// }
  /// 
  /// Response: 201 Created
  /// {
  ///   "success": true,
  ///   "data": { ShopUser object },
  ///   "message": "Sub user created successfully"
  /// }
  /// 
  /// Error: 403 Forbidden (not main user)
  /// Error: 404 Not Found (shop doesn't exist)
  Future<Map<String, dynamic>> createSubUser({
    required String mainUserId,
    required String shopId,
    required String subUserId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required List<String> roleIds,
  }) async {
    try {
      final newUser = await _userManagementService.createSubUser(
        mainUserId: mainUserId,
        shopId: shopId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        roleIds: roleIds,
        subUserId: subUserId,
      );

      return {
        'success': true,
        'statusCode': 201,
        'data': newUser,
        'message': 'Sub user created successfully',
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
        'message': 'Access denied',
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
        'message': 'Failed to create sub user',
      };
    }
  }

  /// [GET] /api/users/{shopId}
  /// Get all users in a shop.
  /// 
  /// Query parameters:
  /// - includeInactive: boolean (default false)
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "data": [ ShopUser objects ],
  ///   "count": 5
  /// }
  /// 
  /// Error: 403 Forbidden (user doesn't belong to shop)
  Future<Map<String, dynamic>> getShopUsers({
    required String currentUserId,
    required String shopId,
    bool includeInactive = false,
  }) async {
    try {
      // Validate current user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: currentUserId,
        shopId: shopId,
      );

      final users = await _userManagementService.getShopUsers(shopId);

      // Filter out inactive users if requested
      final filteredUsers =
          includeInactive ? users : users.where((u) => u.isActive).toList();

      return {
        'success': true,
        'statusCode': 200,
        'data': filteredUsers.map((u) => u.toFirestore()).toList(),
        'count': filteredUsers.length,
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  /// [GET] /api/users/{shopId}/sub-users
  /// Get all sub users in a shop (excludes main user).
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "data": [ ShopUser objects ],
  ///   "count": 4
  /// }
  Future<Map<String, dynamic>> getShopSubUsers({
    required String currentUserId,
    required String shopId,
  }) async {
    try {
      // Validate current user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: currentUserId,
        shopId: shopId,
      );

      final subUsers = await _userManagementService.getShopSubUsers(shopId);

      return {
        'success': true,
        'statusCode': 200,
        'data': subUsers.map((u) => u.toFirestore()).toList(),
        'count': subUsers.length,
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  /// [PUT] /api/users/{userId}
  /// Update a sub user.
  /// 
  /// Request body:
  /// {
  ///   "mainUserId": "current_user_uid",
  ///   "shopId": "shop_123",
  ///   "firstName": "Jane", // optional
  ///   "email": "jane@example.com", // optional
  ///   "roleIds": ["role_1", "role_3"] // optional
  /// }
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "data": { updated ShopUser object }
  /// }
  /// 
  /// Error: 403 Forbidden (not main user)
  Future<Map<String, dynamic>> updateSubUser({
    required String mainUserId,
    required String userId,
    required String shopId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    List<String>? roleIds,
  }) async {
    try {
      final updatedUser = await _userManagementService.updateSubUser(
        mainUserId: mainUserId,
        subUserId: userId,
        shopId: shopId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        roleIds: roleIds,
      );

      return {
        'success': true,
        'statusCode': 200,
        'data': updatedUser.toFirestore(),
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  // ==========================================
  // ROLE MANAGEMENT ENDPOINTS
  // ==========================================

  /// [POST] /api/roles
  /// Create a new role in a shop.
  /// 
  /// Request body:
  /// {
  ///   "mainUserId": "current_user_uid",
  ///   "shopId": "shop_123",
  ///   "name": "Sales Manager",
  ///   "description": "Can manage sales and invoices",
  ///   "permissionIds": ["perm_1", "perm_2", "perm_3"]
  /// }
  /// 
  /// Response: 201 Created
  /// {
  ///   "success": true,
  ///   "data": { Role object },
  ///   "message": "Role created successfully"
  /// }
  Future<Map<String, dynamic>> createRole({
    required String mainUserId,
    required String shopId,
    required String name,
    required String description,
    required List<String> permissionIds,
  }) async {
    try {
      // Validate main user
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        return {
          'success': false,
          'statusCode': 403,
          'error': 'Only main user can create roles',
        };
      }

      final newRole = await _rolePermissionService.createRole(
        shopId: shopId,
        name: name,
        description: description,
        permissionIds: permissionIds,
      );

      return {
        'success': true,
        'statusCode': 201,
        'data': newRole.toFirestore(),
        'message': 'Role created successfully',
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  /// [GET] /api/roles/{shopId}
  /// Get all roles in a shop.
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "data": [ Role objects ],
  ///   "count": 3
  /// }
  Future<Map<String, dynamic>> getShopRoles({
    required String currentUserId,
    required String shopId,
  }) async {
    try {
      // Validate user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: currentUserId,
        shopId: shopId,
      );

      final roles = await _rolePermissionService.getShopRoles(shopId);

      return {
        'success': true,
        'statusCode': 200,
        'data': roles.map((r) => r.toFirestore()).toList(),
        'count': roles.length,
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  /// [POST] /api/users/{userId}/roles/{roleId}
  /// Assign a role to a user.
  /// 
  /// Request body:
  /// {
  ///   "mainUserId": "current_user_uid",
  ///   "shopId": "shop_123"
  /// }
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "message": "Role assigned successfully"
  /// }
  /// 
  /// Error: 403 Forbidden (not main user)
  Future<Map<String, dynamic>> assignRoleToUser({
    required String mainUserId,
    required String userId,
    required String roleId,
    required String shopId,
  }) async {
    try {
      // Validate main user
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        return {
          'success': false,
          'statusCode': 403,
          'error': 'Only main user can assign roles',
        };
      }

      await _rolePermissionService.assignRoleToUser(
        userId: userId,
        roleId: roleId,
        shopId: shopId,
      );

      return {
        'success': true,
        'statusCode': 200,
        'message': 'Role assigned successfully',
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  /// [GET] /api/users/{userId}/roles
  /// Get all roles assigned to a user.
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "data": [ Role objects ],
  ///   "count": 2
  /// }
  Future<Map<String, dynamic>> getUserRoles({
    required String currentUserId,
    required String userId,
    required String shopId,
  }) async {
    try {
      // Validate user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: userId,
        shopId: shopId,
      );

      final roles = await _rolePermissionService.getUserRoles(
        userId: userId,
        shopId: shopId,
      );

      return {
        'success': true,
        'statusCode': 200,
        'data': roles.map((r) => r.toFirestore()).toList(),
        'count': roles.length,
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  /// [GET] /api/users/{userId}/permissions
  /// Get all permissions for a user (from all their roles).
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "data": [ permission codes ],
  ///   "count": 5
  /// }
  Future<Map<String, dynamic>> getUserPermissions({
    required String currentUserId,
    required String userId,
    required String shopId,
  }) async {
    try {
      // Validate user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: userId,
        shopId: shopId,
      );

      final permissionIds = await _rolePermissionService.getUserPermissions(
        userId: userId,
        shopId: shopId,
      );

      // Optionally fetch full permission objects
      final snapshot = await _firestore
          .collection('permissions')
          .where('id', whereIn: permissionIds.isEmpty ? ['_'] : permissionIds)
          .get();

      return {
        'success': true,
        'statusCode': 200,
        'data': snapshot.docs.map((doc) => doc.data()).toList(),
        'count': snapshot.docs.length,
      };
    } on ShopAccessDeniedException catch (e) {
      return {
        'success': false,
        'statusCode': 403,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  // ==========================================
  // PERMISSION CHECK ENDPOINTS
  // ==========================================

  /// [POST] /api/permissions/check
  /// Check if a user has a specific permission.
  /// 
  /// Request body:
  /// {
  ///   "userId": "user_123",
  ///   "shopId": "shop_123",
  ///   "permissionCode": "create_invoice"
  /// }
  /// 
  /// Response: 200 OK
  /// {
  ///   "success": true,
  ///   "hasPermission": true
  /// }
  Future<Map<String, dynamic>> checkUserPermission({
    required String userId,
    required String shopId,
    required String permissionCode,
  }) async {
    try {
      final hasPermission = await _rolePermissionService.userHasPermission(
        userId: userId,
        permissionCode: permissionCode,
        shopId: shopId,
      );

      return {
        'success': true,
        'statusCode': 200,
        'hasPermission': hasPermission,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'error': e.toString(),
        'hasPermission': false,
      };
    }
  }
}
