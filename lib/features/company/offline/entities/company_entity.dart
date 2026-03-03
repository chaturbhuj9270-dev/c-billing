import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'company_entity.g.dart';

/// Helper to parse DateTime from Firestore Timestamp or ISO8601 string
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Sync status for delta sync logic
/// Only companies with status != SYNCED will be pushed to server
enum CompanySyncStatus {
  /// Newly created locally, not yet on server
  newRecord,

  /// Modified locally after sync
  updated,

  /// Marked for deletion, pending server delete
  deleted,

  /// Fully synced with server
  synced,
}

/// Isar Collection for Company with offline-first support
/// Optimized with proper indexes for high-performance queries
@collection
class CompanyEntity {
  /// Auto-generated Isar ID
  Id id = Isar.autoIncrement;

  /// Server-side ID (null for locally created, not yet synced records)
  @Index()
  String? serverId;

  /// Company name (indexed for fast search)
  @Index(type: IndexType.value, caseSensitive: false)
  String companyName;

  /// Company code (indexed for fast lookup)
  @Index(caseSensitive: false)
  String companyCode;

  /// Contact number (indexed for fast lookup)
  @Index()
  String contact;

  /// Address
  String address;

  /// Whether company is active
  bool isActive;

  /// Sync status for delta sync
  @Index()
  @Enumerated(EnumType.ordinal)
  CompanySyncStatus syncStatus;

  /// Last update timestamp for conflict resolution
  @Index()
  DateTime updatedAt;

  /// Created timestamp
  DateTime createdAt;

  CompanyEntity({
    this.serverId,
    required this.companyName,
    this.companyCode = '',
    this.contact = '',
    this.address = '',
    this.isActive = true,
    this.syncStatus = CompanySyncStatus.newRecord,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Factory constructor for creating new company with defaults
  factory CompanyEntity.create({
    String? serverId,
    required String companyName,
    String companyCode = '',
    String contact = '',
    String address = '',
    bool isActive = true,
    CompanySyncStatus syncStatus = CompanySyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return CompanyEntity(
      serverId: serverId,
      companyName: companyName,
      companyCode: companyCode,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: syncStatus,
      updatedAt: now,
      createdAt: now,
    );
  }

  /// Create from server response (Firestore document)
  factory CompanyEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return CompanyEntity(
      serverId: data['id'] as String?,
      companyName: data['companyName'] as String? ?? '',
      companyCode: data['companyCode'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      address: data['address'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      syncStatus: CompanySyncStatus.synced,
      updatedAt: _parseDateTime(data['updatedAt']) ?? now,
      createdAt: _parseDateTime(data['createdAt']) ?? now,
    );
  }

  /// Convert to Map for API sync
  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'companyName': companyName,
      'companyCode': companyCode,
      'contact': contact,
      'address': address,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Map for UI (compatible with existing company page)
  Map<String, dynamic> toCompanyMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'companyName': companyName,
      'companyCode': companyCode,
      'contact': contact,
      'address': address,
      'isActive': isActive,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == CompanySyncStatus.synced,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  /// Copy with modifications
  CompanyEntity copyWith({
    Id? id,
    String? serverId,
    String? companyName,
    String? companyCode,
    String? contact,
    String? address,
    bool? isActive,
    CompanySyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final entity = CompanyEntity(
      serverId: serverId ?? this.serverId,
      companyName: companyName ?? this.companyName,
      companyCode: companyCode ?? this.companyCode,
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

  /// Check if company needs sync
  bool get needsSync => syncStatus != CompanySyncStatus.synced;

  /// Check if company is marked for deletion
  bool get isMarkedForDeletion => syncStatus == CompanySyncStatus.deleted;

  @override
  String toString() {
    return 'CompanyEntity(id: $id, serverId: $serverId, code: $companyCode, name: $companyName, syncStatus: $syncStatus)';
  }
}
