/// Represents shop details used for bill printing and display
class Shop {
  final String id;
  final String shopName;
  final String? ownerName;
  final String address;
  final String? pincode;
  final String phone;
  final String? email;
  final String? gstNumber;
  final String? logoUrl;
  final DateTime? updatedAt;

  const Shop({
    required this.id,
    required this.shopName,
    this.ownerName,
    required this.address,
    this.pincode,
    required this.phone,
    this.email,
    this.gstNumber,
    this.logoUrl,
    this.updatedAt,
  });

  /// Factory constructor to create from JSON (for Firebase)
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: (json['id'] ?? 'main') as String,
      shopName: (json['shopName'] ?? 'My Shop') as String,
      ownerName: json['ownerName'] as String?,
      address: (json['address'] ?? '') as String,
      pincode: json['pincode'] as String?,
      phone: (json['phone'] ?? '') as String,
      email: json['email'] as String?,
      gstNumber: json['gst'] as String?,
      logoUrl: json['logoUrl'] as String?,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.tryParse(json['updatedAt'].toString()))
          : null,
    );
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopName': shopName,
      'ownerName': ownerName,
      'address': address,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'gst': gstNumber,
      'logoUrl': logoUrl,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  Shop copyWith({
    String? id,
    String? shopName,
    String? ownerName,
    String? address,
    String? pincode,
    String? phone,
    String? email,
    String? gstNumber,
    String? logoUrl,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if shop has valid print details
  bool get hasValidPrintDetails =>
      shopName.isNotEmpty && address.isNotEmpty && phone.isNotEmpty;

  /// Get formatted address with pincode
  String get fullAddress {
    if (pincode != null && pincode!.isNotEmpty) {
      return '$address - $pincode';
    }
    return address;
  }

  /// Default empty shop for fallback
  static const Shop empty = Shop(
    id: 'main',
    shopName: 'My Shop',
    address: '',
    phone: '',
  );

  @override
  String toString() {
    return 'Shop(id: $id, shopName: $shopName, address: $address, phone: $phone)';
  }
}
