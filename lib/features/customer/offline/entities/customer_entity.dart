import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'customer_entity.g.dart';

/// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Isar Collection for Customer with offline-first support
/// Designed for high-performance CRUD operations with proper indexing
@collection
class CustomerEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Customer name
  String name;

  /// Mobile number (indexed for fast lookup)
  @Index(unique: true, caseSensitive: false)
  String mobile;

  /// Address (optional)
  String? address;

  /// Email (optional)
  String? email;

  /// Current pending amount for this customer
  double currentPendingAmount;

  /// Total purchases made by this customer
  double totalPurchases;

  /// Sync status - false means pending sync with server
  @Index()
  bool isSynced;

  /// Soft delete flag - true means marked for deletion
  @Index()
  bool isDeleted;

  /// Last update timestamp for conflict resolution
  @Index()
  DateTime updatedAt;

  /// Created timestamp
  DateTime createdAt;

  CustomerEntity({
    this.serverId,
    required this.name,
    required this.mobile,
    this.address,
    this.email,
    this.currentPendingAmount = 0.0,
    this.totalPurchases = 0.0,
    this.isSynced = false,
    this.isDeleted = false,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Factory constructor for convenience with default timestamps
  factory CustomerEntity.create({
    String? serverId,
    required String name,
    required String mobile,
    String? address,
    String? email,
    double currentPendingAmount = 0.0,
    double totalPurchases = 0.0,
    bool isSynced = false,
    bool isDeleted = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return CustomerEntity(
      serverId: serverId,
      name: name,
      mobile: mobile,
      address: address,
      email: email,
      currentPendingAmount: currentPendingAmount,
      totalPurchases: totalPurchases,
      isSynced: isSynced,
      isDeleted: isDeleted,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create from server/domain Customer data
  /// Handles both flat format (name, mobile) and Firebase format (firstName, lastName, contact)
  factory CustomerEntity.fromCustomer(Map<String, dynamic> customer) {
    final now = DateTime.now();

    // Build name: prefer pre-built 'name' field, otherwise join firstName/middleName/lastName
    String name;
    if (customer['name'] != null && (customer['name'] as String).isNotEmpty) {
      name = customer['name'] as String;
    } else {
      final firstName = (customer['firstName'] ?? '').toString();
      final middleName = (customer['middleName'] ?? '').toString();
      final lastName = (customer['lastName'] ?? '').toString();
      name = [
        firstName,
        middleName,
        lastName,
      ].where((s) => s.isNotEmpty).join(' ');
    }

    // Mobile: prefer 'mobile', fallback to 'contact'
    final mobile = (customer['mobile'] ?? customer['contact'] ?? '').toString();

    // Pending amount
    final pendingAmount =
        (customer['currentPendingAmount'] as num?)?.toDouble() ??
        (customer['pendingBalance'] as num?)?.toDouble() ??
        0.0;

    // Total purchases
    final totalPurchases =
        (customer['totalPurchases'] as num?)?.toDouble() ??
        (customer['totalPurchaseAmount'] as num?)?.toDouble() ??
        0.0;

    return CustomerEntity(
      serverId: customer['id'] as String?,
      name: name,
      mobile: mobile,
      address: customer['address'] as String?,
      email: customer['email'] as String?,
      currentPendingAmount: pendingAmount,
      totalPurchases: totalPurchases,
      isSynced: true, // From server, so it's synced
      isDeleted: customer['isActive'] == false,
      updatedAt: _parseDateTime(customer['updatedAt']) ?? now,
      createdAt: _parseDateTime(customer['createdAt']) ?? now,
    );
  }

  /// Convert to Map for API sync
  /// Maps to Firebase field names (firstName, lastName, contact, etc.)
  Map<String, dynamic> toSyncPayload() {
    // Split name into firstName, middleName, lastName for Firebase compatibility
    final nameParts = name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final middleName = nameParts.length > 2
        ? nameParts.sublist(1, nameParts.length - 1).join(' ')
        : '';
    final lastName = nameParts.length > 1 ? nameParts.last : '';

    return {
      'id': serverId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'contact': mobile,
      'address': address,
      'email': email,
      'currentPendingAmount': currentPendingAmount,
      'totalPurchaseAmount': totalPurchases,
      'isActive': !isDeleted,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain Customer map
  Map<String, dynamic> toCustomerMap() {
    return {
      'id': serverId ?? id.toString(),
      'localId': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'email': email,
      'currentPendingAmount': currentPendingAmount,
      'totalPurchases': totalPurchases,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  /// Copy with modifications
  CustomerEntity copyWith({
    Id? id,
    String? serverId,
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? currentPendingAmount,
    double? totalPurchases,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final entity = CustomerEntity(
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      email: email ?? this.email,
      currentPendingAmount: currentPendingAmount ?? this.currentPendingAmount,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
    );
    entity.id = id ?? this.id;
    return entity;
  }

  @override
  String toString() {
    return 'CustomerEntity(id: $id, serverId: $serverId, name: $name, mobile: $mobile, isSynced: $isSynced, isDeleted: $isDeleted)';
  }
}
