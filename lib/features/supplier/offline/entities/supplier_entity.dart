import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'supplier_entity.g.dart';

/// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Sync status for delta sync logic
/// Only suppliers with status != SYNCED will be pushed to server
enum SupplierSyncStatus {
  /// Newly created locally, not yet on server
  newRecord,

  /// Modified locally after sync
  updated,

  /// Marked for deletion, pending server delete
  deleted,

  /// Fully synced with server
  synced,
}

/// Isar Collection for Supplier with offline-first support
/// Optimized with proper indexes for high-performance queries
@collection
class SupplierEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// First name (indexed for fast search)
  @Index(type: IndexType.value, caseSensitive: false)
  String firstName;

  /// Middle name
  String middleName;

  /// Last name
  String lastName;

  /// Supplier code (indexed for fast lookup)
  @Index(caseSensitive: false)
  String supplierCode;

  /// Contact number (indexed for fast lookup)
  @Index()
  String contact;

  /// Address
  String address;

  /// Whether supplier is active
  bool isActive;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  SupplierSyncStatus syncStatus;

  /// Last update timestamp for conflict resolution
  @Index()
  DateTime updatedAt;

  /// Created timestamp
  DateTime createdAt;

  SupplierEntity({
    this.serverId,
    required this.firstName,
    this.middleName = '',
    this.lastName = '',
    this.supplierCode = '',
    required this.contact,
    this.address = '',
    this.isActive = true,
    this.syncStatus = SupplierSyncStatus.newRecord,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Get full name
  String get fullName {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }

  /// Factory constructor for creating new supplier with defaults
  factory SupplierEntity.create({
    String? serverId,
    required String firstName,
    String middleName = '',
    String lastName = '',
    String supplierCode = '',
    required String contact,
    String address = '',
    bool isActive = true,
    SupplierSyncStatus syncStatus = SupplierSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return SupplierEntity(
      serverId: serverId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      supplierCode: supplierCode,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: syncStatus,
      updatedAt: now,
      createdAt: now,
    );
  }

  /// Create from server response (Firestore document)
  factory SupplierEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return SupplierEntity(
      serverId: data['id'] as String?,
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      supplierCode: data['supplierCode'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      address: data['address'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      syncStatus: SupplierSyncStatus.synced,
      updatedAt: _parseDateTime(data['updatedAt']) ?? now,
      createdAt: _parseDateTime(data['createdAt']) ?? now,
    );
  }

  /// Convert to Map for API sync
  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'supplierCode': supplierCode,
      'contact': contact,
      'address': address,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Map for UI (compatible with existing supplier page)
  Map<String, dynamic> toSupplierMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'supplierCode': supplierCode,
      'contact': contact,
      'address': address,
      'isActive': isActive,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == SupplierSyncStatus.synced,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  /// Copy with modifications
  SupplierEntity copyWith({
    Id? id,
    String? serverId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? supplierCode,
    String? contact,
    String? address,
    bool? isActive,
    SupplierSyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final entity = SupplierEntity(
      serverId: serverId ?? this.serverId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      supplierCode: supplierCode ?? this.supplierCode,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
    );
    entity.id = id ?? this.id;
    return entity;
  }

  /// Check if supplier needs sync
  bool get needsSync => syncStatus != SupplierSyncStatus.synced;

  /// Check if supplier is marked for deletion
  bool get isMarkedForDeletion => syncStatus == SupplierSyncStatus.deleted;

  @override
  String toString() {
    return 'SupplierEntity(id: $id, serverId: $serverId, code: $supplierCode, name: $fullName, syncStatus: $syncStatus)';
  }
}
