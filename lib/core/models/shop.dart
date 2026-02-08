import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Shop/Business in the multi-tenant system.
/// Each shop has exactly one Main User (Owner/Admin).
class Shop {
  final String id;
  final String name;
  final String mainUserId; // Owner/Admin of the shop
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String pincode;
  final String gstNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Shop({
    required this.id,
    required this.name,
    required this.mainUserId,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.pincode,
    required this.gstNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Convert Shop to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'mainUserId': mainUserId,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'address': address,
      'pincode': pincode,
      'gstNumber': gstNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  /// Create Shop from Firestore document
  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shop(
      id: doc.id,
      name: data['name'] ?? '',
      mainUserId: data['mainUserId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      pincode: data['pincode'] ?? '',
      gstNumber: data['gstNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Create a copy of Shop with some fields modified
  Shop copyWith({
    String? id,
    String? name,
    String? mainUserId,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? pincode,
    String? gstNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      mainUserId: mainUserId ?? this.mainUserId,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      gstNumber: gstNumber ?? this.gstNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
