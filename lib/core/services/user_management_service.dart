import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_user.dart';
import 'shop_access_service.dart';

/// Service for managing shop users (main and sub users).
/// 
/// Enforces that only Main Users can create/manage Sub Users.
/// All operations are scoped to a specific shop.
class UserManagementService {
  final FirebaseFirestore _firestore;
  final ShopAccessService _shopAccessService;

  UserManagementService({
    FirebaseFirestore? firestore,
    ShopAccessService? shopAccessService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _shopAccessService = shopAccessService ?? ShopAccessService();

  /// Creates a new sub user in a shop.
  /// 
  /// Can only be called by the Main User of the shop.
  /// Returns the created ShopUser.
  /// Throws [ShopAccessDeniedException] if:
  /// - Requester is not the Main User
  /// - Shop doesn't exist
  /// - User already exists
  Future<ShopUser> createSubUser({
    required String mainUserId, // The user creating this sub user
    required String shopId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required List<String> roleIds,
    required String subUserId, // Firebase Auth UID of new user
  }) async {
    try {
      // Validate requester is main user of shop
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        throw ShopAccessDeniedException(
          'Only Main User can create sub users',
        );
      }

      // Validate shop exists
      await _shopAccessService.validateShopExists(shopId);

      // Check if user already exists
      final existingUser = await _firestore
          .collection('users')
          .doc(subUserId)
          .get();

      if (existingUser.exists) {
        throw ShopAccessDeniedException(
          'User with ID $subUserId already exists',
        );
      }

      final now = DateTime.now();
      final newUser = ShopUser(
        id: subUserId,
        shopId: shopId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        userType: UserType.subUser,
        roleIds: roleIds,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(subUserId)
          .set(newUser.toFirestore());

      return newUser;
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error creating sub user: $e');
    }
  }

  /// Updates a sub user.
  /// 
  /// Can only be called by the Main User of the shop.
  Future<ShopUser> updateSubUser({
    required String mainUserId, // The user making the update
    required String subUserId,
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
      // Validate requester is main user of shop
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        throw ShopAccessDeniedException(
          'Only Main User can update sub users',
        );
      }

      // Validate sub user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: subUserId,
        shopId: shopId,
      );

      // Get current user
      final userDoc = await _firestore
          .collection('users')
          .doc(subUserId)
          .get();

      if (!userDoc.exists) {
        throw ShopAccessDeniedException('Sub user $subUserId not found');
      }

      final currentUser = ShopUser.fromFirestore(userDoc);

      // Prevent changing main user
      if (currentUser.isMainUser) {
        throw ShopAccessDeniedException(
          'Cannot update Main User through this method',
        );
      }

      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
        roleIds: roleIds,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(subUserId)
          .update(updatedUser.toFirestore());

      return updatedUser;
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error updating sub user: $e');
    }
  }

  /// Deletes a sub user (soft delete by setting isActive to false).
  /// 
  /// Can only be called by the Main User of the shop.
  Future<void> deleteSubUser({
    required String mainUserId,
    required String subUserId,
    required String shopId,
  }) async {
    try {
      // Validate requester is main user of shop
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        throw ShopAccessDeniedException(
          'Only Main User can delete sub users',
        );
      }

      // Validate sub user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: subUserId,
        shopId: shopId,
      );

      // Get current user and verify it's a sub user
      final userDoc = await _firestore
          .collection('users')
          .doc(subUserId)
          .get();

      if (!userDoc.exists) {
        throw ShopAccessDeniedException('Sub user $subUserId not found');
      }

      final user = ShopUser.fromFirestore(userDoc);

      if (user.isMainUser) {
        throw ShopAccessDeniedException(
          'Cannot delete Main User',
        );
      }

      await _firestore
          .collection('users')
          .doc(subUserId)
          .update({
            'isActive': false,
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error deleting sub user: $e');
    }
  }

  /// Gets a user with shop validation.
  /// 
  /// Returns ShopUser or null if not found.
  Future<ShopUser?> getUser({
    required String userId,
    required String shopId,
  }) async {
    try {
      // Validate user belongs to shop
      await _shopAccessService.validateUserShopAccess(
        userId: userId,
        shopId: shopId,
      );

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ShopUser.fromFirestore(doc);
    } catch (e) {
      throw ShopAccessDeniedException('Error fetching user: $e');
    }
  }

  /// Gets all active users in a shop.
  /// 
  /// Returns a list of all active ShopUsers (both main and sub).
  Future<List<ShopUser>> getShopUsers(String shopId) async {
    try {
      // Validate shop exists
      await _shopAccessService.validateShopExists(shopId);

      final snapshot = await _firestore
          .collection('users')
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ShopUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error fetching shop users: $e');
    }
  }

  /// Gets all active sub users in a shop (excludes main user).
  Future<List<ShopUser>> getShopSubUsers(String shopId) async {
    try {
      // Validate shop exists
      await _shopAccessService.validateShopExists(shopId);

      final snapshot = await _firestore
          .collection('users')
          .where('shopId', isEqualTo: shopId)
          .where('userType', isEqualTo: 'subUser')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ShopUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error fetching sub users: $e');
    }
  }

  /// Gets the main user of a shop.
  /// 
  /// Returns the ShopUser with userType == MAIN_USER.
  Future<ShopUser?> getMainUser(String shopId) async {
    try {
      // Validate shop exists
      await _shopAccessService.validateShopExists(shopId);

      final snapshot = await _firestore
          .collection('users')
          .where('shopId', isEqualTo: shopId)
          .where('userType', isEqualTo: 'mainUser')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ShopUser.fromFirestore(snapshot.docs.first);
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error fetching main user: $e');
    }
  }

  /// Activates a user (sets isActive to true).
  Future<void> activateUser({
    required String mainUserId,
    required String userId,
    required String shopId,
  }) async {
    try {
      // Validate requester is main user
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        throw ShopAccessDeniedException(
          'Only Main User can activate users',
        );
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'isActive': true,
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error activating user: $e');
    }
  }

  /// Deactivates a user (sets isActive to false).
  /// 
  /// Cannot deactivate the main user.
  Future<void> deactivateUser({
    required String mainUserId,
    required String userId,
    required String shopId,
  }) async {
    try {
      // Validate requester is main user
      final isMainUser = await _shopAccessService.isMainUser(
        userId: mainUserId,
        shopId: shopId,
      );

      if (!isMainUser) {
        throw ShopAccessDeniedException(
          'Only Main User can deactivate users',
        );
      }

      // Get user and verify it's not main user
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw ShopAccessDeniedException('User $userId not found');
      }

      final user = ShopUser.fromFirestore(userDoc);

      if (user.isMainUser) {
        throw ShopAccessDeniedException(
          'Cannot deactivate Main User',
        );
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'isActive': false,
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      if (e is ShopAccessDeniedException) {
        rethrow;
      }
      throw ShopAccessDeniedException('Error deactivating user: $e');
    }
  }

  /// Checks if a user is a sub user of a specific shop and is active.
  Future<bool> isActiveSubUserInShop({
    required String userId,
    required String shopId,
  }) async {
    try {
      final isSubUser = await _shopAccessService.isSubUser(
        userId: userId,
        shopId: shopId,
      );

      if (!isSubUser) {
        return false;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      return data['isActive'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
