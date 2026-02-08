import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a User in the multi-tenant system.
/// A user can be either:
/// - Main User (Owner/Admin): Full access to shop data, can manage sub users
/// - Sub User: Limited access based on assigned role/permissions
class ShopUser {
  final String id; // Firebase Auth UID
  final String shopId; // The shop this user belongs to
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final UserType userType; // MAIN_USER or SUB_USER
  final List<String> roleIds; // Roles assigned to this user
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ShopUser({
    required this.id,
    required this.shopId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.userType,
    required this.roleIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Full name of the user
  String get fullName => '$firstName $middleName $lastName'.trim();

  /// Check if user is the main user (owner/admin)
  bool get isMainUser => userType == UserType.mainUser;

  /// Check if user is a sub user
  bool get isSubUser => userType == UserType.subUser;

  /// Convert ShopUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'shopId': shopId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'userType': userType.toString().split('.').last,
      'roleIds': roleIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  /// Create ShopUser from Firestore document
  factory ShopUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userTypeStr = data['userType'] ?? 'subUser';
    final userType = userTypeStr == 'mainUser'
        ? UserType.mainUser
        : UserType.subUser;

    return ShopUser(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      userType: userType,
      roleIds: List<String>.from(data['roleIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Create a copy of ShopUser with some fields modified
  ShopUser copyWith({
    String? id,
    String? shopId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    UserType? userType,
    List<String>? roleIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ShopUser(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      roleIds: roleIds ?? this.roleIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ShopUser{id: $id, shopId: $shopId, name: $fullName, type: ${userType.toString()}}';
  }
}

/// Enum for user types in the multi-tenant system
enum UserType {
  mainUser, // Owner/Admin - full access
  subUser, // Limited access based on roles/permissions
}
