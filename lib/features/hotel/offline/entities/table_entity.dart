import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'table_entity.g.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Live status of a restaurant table.
enum TableStatus {
  empty, // Free, no guests
  active, // Occupied — order in progress
  waiting, // Reserved / guest waiting to be seated
  served, // Food served, bill pending
  reserved, // Booked in advance
}

enum TableSyncStatus { newRecord, updated, deleted, synced }

@collection
class TableEntity {
  Id id = Isar.autoIncrement;

  @Index()
  String? serverId;

  /// Human-readable number, e.g. "T-01" or "12"
  @Index(type: IndexType.value, caseSensitive: false)
  String tableNumber;

  /// Section / zone name, e.g. "Indoor", "Rooftop", "Bar"
  @Index(caseSensitive: false)
  String section;

  int capacity; // max seats

  int occupiedSeats;

  @Enumerated(EnumType.name)
  @Index()
  TableStatus status;

  /// Name / phone for reservation or waiting guest
  String? guestName;
  String? guestPhone;
  String? notes;

  /// When the table became active / occupied
  DateTime? occupiedAt;

  /// When the bill was cleared last
  DateTime? clearedAt;

  /// Linked order ID (if active)
  String? currentOrderId;

  @Enumerated(EnumType.name)
  @Index()
  TableSyncStatus syncStatus;

  @Index()
  DateTime updatedAt;

  DateTime createdAt;

  TableEntity({
    this.serverId,
    required this.tableNumber,
    this.section = 'Main',
    this.capacity = 4,
    this.occupiedSeats = 0,
    this.status = TableStatus.empty,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.occupiedAt,
    this.clearedAt,
    this.currentOrderId,
    this.syncStatus = TableSyncStatus.newRecord,
    required this.updatedAt,
    required this.createdAt,
  });

  factory TableEntity.create({
    String? serverId,
    required String tableNumber,
    String section = 'Main',
    int capacity = 4,
    int occupiedSeats = 0,
    TableStatus status = TableStatus.empty,
    String? guestName,
    String? guestPhone,
    String? notes,
    DateTime? occupiedAt,
    DateTime? clearedAt,
    String? currentOrderId,
    TableSyncStatus syncStatus = TableSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return TableEntity(
      serverId: serverId,
      tableNumber: tableNumber,
      section: section,
      capacity: capacity,
      occupiedSeats: occupiedSeats,
      status: status,
      guestName: guestName,
      guestPhone: guestPhone,
      notes: notes,
      occupiedAt: occupiedAt,
      clearedAt: clearedAt,
      currentOrderId: currentOrderId,
      syncStatus: syncStatus,
      updatedAt: now,
      createdAt: now,
    );
  }

  factory TableEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return TableEntity(
      serverId: data['id'] as String?,
      tableNumber: data['tableNumber'] as String? ?? '',
      section: data['section'] as String? ?? 'Main',
      capacity: (data['capacity'] as num?)?.toInt() ?? 4,
      occupiedSeats: (data['occupiedSeats'] as num?)?.toInt() ?? 0,
      status: TableStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String?),
        orElse: () => TableStatus.empty,
      ),
      guestName: data['guestName'] as String?,
      guestPhone: data['guestPhone'] as String?,
      notes: data['notes'] as String?,
      occupiedAt: _parseDateTime(data['occupiedAt']),
      clearedAt: _parseDateTime(data['clearedAt']),
      currentOrderId: data['currentOrderId'] as String?,
      syncStatus: TableSyncStatus.synced,
      updatedAt: _parseDateTime(data['updatedAt']) ?? now,
      createdAt: _parseDateTime(data['createdAt']) ?? now,
    );
  }

  Map<String, dynamic> toSyncPayload() => {
    'id': serverId,
    'tableNumber': tableNumber,
    'section': section,
    'capacity': capacity,
    'occupiedSeats': occupiedSeats,
    'status': status.name,
    'guestName': guestName,
    'guestPhone': guestPhone,
    'notes': notes,
    'occupiedAt': occupiedAt?.toIso8601String(),
    'clearedAt': clearedAt?.toIso8601String(),
    'currentOrderId': currentOrderId,
    'updatedAt': updatedAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  TableEntity copyWith({
    Id? id,
    String? serverId,
    String? tableNumber,
    String? section,
    int? capacity,
    int? occupiedSeats,
    TableStatus? status,
    String? guestName,
    String? guestPhone,
    String? notes,
    DateTime? occupiedAt,
    DateTime? clearedAt,
    String? currentOrderId,
    TableSyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final e = TableEntity(
      serverId: serverId ?? this.serverId,
      tableNumber: tableNumber ?? this.tableNumber,
      section: section ?? this.section,
      capacity: capacity ?? this.capacity,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
      status: status ?? this.status,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      notes: notes ?? this.notes,
      occupiedAt: occupiedAt ?? this.occupiedAt,
      clearedAt: clearedAt ?? this.clearedAt,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
    );
    e.id = id ?? this.id;
    return e;
  }

  bool get needsSync => syncStatus != TableSyncStatus.synced;

  /// Minutes the table has been occupied
  int get occupiedMinutes {
    if (occupiedAt == null) return 0;
    return DateTime.now().difference(occupiedAt!).inMinutes;
  }
}
