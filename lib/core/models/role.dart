import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Permission that can be assigned to Sub Users.
/// Permissions define what actions a user can perform within their shop.
class Permission {
  final String id;
  final String shopId;
  final String code; // e.g., 'create_invoice', 'view_reports'
  final String name;
  final String description;
  final DateTime createdAt;

  Permission({
    required this.id,
    required this.shopId,
    required this.code,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'shopId': shopId,
      'code': code,
      'name': name,
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory Permission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Permission(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Represents a Role that can be assigned to Sub Users.
/// A Role is a collection of Permissions.
class Role {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final List<String> permissionIds; // IDs of permissions this role has
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Role({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.permissionIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'description': description,
      'permissionIds': permissionIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  factory Role.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Role(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      permissionIds: List<String>.from(data['permissionIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Role copyWith({
    String? id,
    String? shopId,
    String? name,
    String? description,
    List<String>? permissionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Role(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      permissionIds: permissionIds ?? this.permissionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
