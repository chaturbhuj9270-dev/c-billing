/// Represents a customer with transaction and pending balance tracking
/// 
/// This entity supports:
/// - Basic customer information (name, contact, address)
/// - Running pending balance for credit sales
/// - Total purchase and payment history tracking
class Customer {
  /// Unique identifier for the customer
  final String id;

  /// Customer's first name
  final String firstName;

  /// Customer's middle name (optional)
  final String? middleName;

  /// Customer's last name
  final String lastName;

  /// Customer's mobile/phone number (unique identifier for lookups)
  final String contact;

  /// Customer's address (optional)
  final String? address;

  /// Current pending amount owed by customer
  /// Increases when bill is generated, decreases when payment is received
  final double currentPendingAmount;

  /// Total amount of all bills ever generated for this customer
  final double totalPurchaseAmount;

  /// Total amount of all payments ever received from this customer
  final double totalPaidAmount;

  /// Customer creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Whether the customer is active
  final bool isActive;

  const Customer({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.contact,
    this.address,
    this.currentPendingAmount = 0.0,
    this.totalPurchaseAmount = 0.0,
    this.totalPaidAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Get full name of customer
  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName'.trim();
    }
    return '$firstName $lastName'.trim();
  }

  /// Check if customer has pending balance
  bool get hasPendingBalance => currentPendingAmount > 0;

  /// Factory constructor to create from Firebase JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: (json['id'] ?? '') as String,
      firstName: (json['firstName'] ?? '') as String,
      middleName: json['middleName'] as String?,
      lastName: (json['lastName'] ?? '') as String,
      contact: (json['contact'] ?? '') as String,
      address: json['address'] as String?,
      currentPendingAmount:
          ((json['currentPendingAmount'] ?? 0) as num).toDouble(),
      totalPurchaseAmount:
          ((json['totalPurchaseAmount'] ?? 0) as num).toDouble(),
      totalPaidAmount: ((json['totalPaidAmount'] ?? 0) as num).toDouble(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.parse(json['updatedAt'].toString()))
          : DateTime.now(),
      isActive: (json['isActive'] ?? true) as bool,
    );
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'contact': contact,
      'address': address,
      'currentPendingAmount': currentPendingAmount,
      'totalPurchaseAmount': totalPurchaseAmount,
      'totalPaidAmount': totalPaidAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  Customer copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? contact,
    String? address,
    double? currentPendingAmount,
    double? totalPurchaseAmount,
    double? totalPaidAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      currentPendingAmount: currentPendingAmount ?? this.currentPendingAmount,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create an empty customer (for form initialization)
  factory Customer.empty() {
    return Customer(
      id: '',
      firstName: '',
      lastName: '',
      contact: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $fullName, contact: $contact, pending: $currentPendingAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
