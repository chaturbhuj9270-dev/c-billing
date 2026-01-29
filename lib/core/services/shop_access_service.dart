import 'package:cloud_firestore/cloud_firestore.dart';

/// Exception thrown when user tries to access data from a different shop
class ShopAccessDeniedException implements Exception {
  final String message;
  ShopAccessDeniedException(this.message);
  
  @override
  String toString() => 'ShopAccessDeniedException: $message';
}

/// Exception thrown when a required shop context is missing
class MissingShopContextException implements Exception {
  final String message;
  MissingShopContextException(this.message);
  
  @override
  String toString() => 'MissingShopContextException: $message';
}

/// Service to enforce multi-tenancy and prevent cross-shop data access.
/// 
/// This service acts as a security middleware that validates all data operations
/// to ensure users can only access their own shop's data.
class ShopAccessService {
  final FirebaseFirestore _firestore;

  ShopAccessService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Validates that a user has access to a specific shop.
  /// 
  /// Returns true if the userShopId matches the requestedShopId.
  /// Throws [ShopAccessDeniedException] if user tries to access different shop.
  /// Throws [MissingShopContextException] if either shopId is empty.
  bool validateShopAccess({
    required String userShopId,
    required String requestedShopId,
  }) {
    if (userShopId.isEmpty || requestedShopId.isEmpty) {
      throw MissingShopContextException(
        'Shop context missing. userShopId: $userShopId, requestedShopId: $requestedShopId',
      );
    }

    if (userShopId != requestedShopId) {
      throw ShopAccessDeniedException(
        'User shop ($userShopId) does not match requested shop ($requestedShopId). Access denied.',
      );
    }

    return true;
  }

  /// Validates that a shop exists and is active.
  /// 
  /// Throws an exception if shop is not found or is inactive.
  Future<bool> validateShopExists(String shopId) async {
    if (shopId.isEmpty) {
      throw MissingShopContextException('Shop ID cannot be empty');
    }

    try {
      final doc = await _firestore.collection('shops').doc(shopId).get();
      
      if (!doc.exists) {
        throw ShopAccessDeniedException('Shop with ID $shopId not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final isActive = data['isActive'] ?? false;
      
      if (!isActive) {
        throw ShopAccessDeniedException('Shop with ID $shopId is inactive');
      }

      return true;
    } catch (e) {
      if (e is ShopAccessDeniedException || e is MissingShopContextException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error validating shop: $e');
    }
  }

  /// Validates that a user belongs to a specific shop and is active.
  /// 
  /// Checks both that the user exists, belongs to the correct shop,
  /// and is in an active state.
  Future<bool> validateUserShopAccess({
    required String userId,
    required String shopId,
  }) async {
    if (userId.isEmpty || shopId.isEmpty) {
      throw MissingShopContextException('UserId or ShopId cannot be empty');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw ShopAccessDeniedException('User with ID $userId not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final userShopId = data['shopId'] ?? '';

      if (userShopId != shopId) {
        throw ShopAccessDeniedException(
          'User $userId does not belong to shop $shopId',
        );
      }

      final isActive = data['isActive'] ?? false;
      if (!isActive) {
        throw ShopAccessDeniedException('User $userId is inactive');
      }

      return true;
    } catch (e) {
      if (e is ShopAccessDeniedException || e is MissingShopContextException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error validating user shop access: $e');
    }
  }

  /// Checks if a user is the main user (owner/admin) of a shop.
  /// 
  /// Main users have full access to all shop data and can manage sub users.
  Future<bool> isMainUser({
    required String userId,
    required String shopId,
  }) async {
    try {
      // First validate user has access to shop
      await validateUserShopAccess(userId: userId, shopId: shopId);

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final userType = data['userType'] ?? '';
      
      return userType == 'mainUser';
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        return false;
      }
      throw ShopAccessDeniedException('Error checking main user status: $e');
    }
  }

  /// Checks if a user is a sub user of a shop.
  /// 
  /// Sub users have limited access based on assigned roles/permissions.
  Future<bool> isSubUser({
    required String userId,
    required String shopId,
  }) async {
    try {
      // First validate user has access to shop
      await validateUserShopAccess(userId: userId, shopId: shopId);

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final userType = data['userType'] ?? '';
      
      return userType == 'subUser';
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        return false;
      }
      throw ShopAccessDeniedException('Error checking sub user status: $e');
    }
  }

  /// Validates that a role belongs to a shop.
  /// 
  /// Throws [ShopAccessDeniedException] if role doesn't exist or belongs to different shop.
  Future<bool> validateRoleShopAccess({
    required String roleId,
    required String shopId,
  }) async {
    if (roleId.isEmpty || shopId.isEmpty) {
      throw MissingShopContextException('RoleId or ShopId cannot be empty');
    }

    try {
      final doc = await _firestore
          .collection('roles')
          .doc(roleId)
          .get();

      if (!doc.exists) {
        throw ShopAccessDeniedException('Role with ID $roleId not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final roleShopId = data['shopId'] ?? '';

      if (roleShopId != shopId) {
        throw ShopAccessDeniedException(
          'Role $roleId does not belong to shop $shopId',
        );
      }

      return true;
    } catch (e) {
      if (e is ShopAccessDeniedException || e is MissingShopContextException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error validating role shop access: $e');
    }
  }

  /// Validates that a permission belongs to a shop.
  /// 
  /// Throws [ShopAccessDeniedException] if permission doesn't exist or belongs to different shop.
  Future<bool> validatePermissionShopAccess({
    required String permissionId,
    required String shopId,
  }) async {
    if (permissionId.isEmpty || shopId.isEmpty) {
      throw MissingShopContextException('PermissionId or ShopId cannot be empty');
    }

    try {
      final doc = await _firestore
          .collection('permissions')
          .doc(permissionId)
          .get();

      if (!doc.exists) {
        throw ShopAccessDeniedException('Permission with ID $permissionId not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final permissionShopId = data['shopId'] ?? '';

      if (permissionShopId != shopId) {
        throw ShopAccessDeniedException(
          'Permission $permissionId does not belong to shop $shopId',
        );
      }

      return true;
    } catch (e) {
      if (e is ShopAccessDeniedException || e is MissingShopContextException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error validating permission shop access: $e');
    }
  }

  /// Batch validates that multiple users belong to a shop.
  /// 
  /// Useful for operations that involve multiple users (e.g., bulk assignments).
  Future<bool> validateMultipleUsersShopAccess({
    required List<String> userIds,
    required String shopId,
  }) async {
    if (shopId.isEmpty || userIds.isEmpty) {
      throw MissingShopContextException('ShopId or UserIds cannot be empty');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('shopId', isEqualTo: shopId)
          .where('id', whereIn: userIds)
          .get();

      if (snapshot.docs.length != userIds.length) {
        throw ShopAccessDeniedException(
          'Not all users belong to shop $shopId',
        );
      }

      return true;
    } catch (e) {
      if (e is ShopAccessDeniedException || e is MissingShopContextException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error validating multiple users: $e');
    }
  }

  /// Gets the shop ID for a user.
  /// 
  /// Returns null if user doesn't exist.
  /// Useful for determining a user's shop context after authentication.
  Future<String?> getUserShopId(String userId) async {
    if (userId.isEmpty) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return data['shopId'];
    } catch (e) {
      return null;
    }
  }
}
