import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

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
  final String? shopLogoBase64;
  final String? signatureBase64;
  final String? qrCodeBase64;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;
  final String? termsAndConditions;
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
    this.shopLogoBase64,
    this.signatureBase64,
    this.qrCodeBase64,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.termsAndConditions,
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
      shopLogoBase64: json['shopLogoBase64'] as String?,
      signatureBase64: json['signatureBase64'] as String?,
      qrCodeBase64: json['qrCodeBase64'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
      updatedAt: _parseDateTime(json['updatedAt']),
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
      'shopLogoBase64': shopLogoBase64,
      'signatureBase64': signatureBase64,
      'qrCodeBase64': qrCodeBase64,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'termsAndConditions': termsAndConditions,
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
    String? shopLogoBase64,
    String? signatureBase64,
    String? qrCodeBase64,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? termsAndConditions,
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
      shopLogoBase64: shopLogoBase64 ?? this.shopLogoBase64,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      qrCodeBase64: qrCodeBase64 ?? this.qrCodeBase64,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
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
    shopName: 'C-BIlling',
    address: '',
    phone: '',
  );

  @override
  String toString() {
    return 'Shop(id: $id, shopName: $shopName, address: $address, phone: $phone)';
  }
}
