import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'menu_item_entity.g.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

enum MenuSyncStatus { newRecord, updated, deleted, synced }

@collection
class MenuItemEntity {
  Id id = Isar.autoIncrement;

  @Index()
  String? serverId;

  @Index(type: IndexType.value, caseSensitive: false)
  String name;

  String description;

  @Index(caseSensitive: false)
  String category;

  double price;

  String? imageUrl;

  bool isVeg;

  bool isAvailable;

  int preparationTimeMinutes;

  String? tags;

  int sortOrder;

  @Index()
  @Enumerated(EnumType.ordinal)
  MenuSyncStatus syncStatus;

  @Index()
  DateTime updatedAt;

  DateTime createdAt;

  MenuItemEntity({
    this.serverId,
    required this.name,
    this.description = '',
    this.category = 'Uncategorized',
    required this.price,
    this.imageUrl,
    this.isVeg = true,
    this.isAvailable = true,
    this.preparationTimeMinutes = 15,
    this.tags,
    this.sortOrder = 0,
    this.syncStatus = MenuSyncStatus.newRecord,
    required this.updatedAt,
    required this.createdAt,
  });

  factory MenuItemEntity.create({
    String? serverId,
    required String name,
    String description = '',
    String category = 'Uncategorized',
    required double price,
    String? imageUrl,
    bool isVeg = true,
    bool isAvailable = true,
    int preparationTimeMinutes = 15,
    String? tags,
    int sortOrder = 0,
    MenuSyncStatus syncStatus = MenuSyncStatus.newRecord,
  }) {
    final now = DateTime.now();
    return MenuItemEntity(
      serverId: serverId,
      name: name,
      description: description,
      category: category,
      price: price,
      imageUrl: imageUrl,
      isVeg: isVeg,
      isAvailable: isAvailable,
      preparationTimeMinutes: preparationTimeMinutes,
      tags: tags,
      sortOrder: sortOrder,
      syncStatus: syncStatus,
      updatedAt: now,
      createdAt: now,
    );
  }

  factory MenuItemEntity.fromServer(Map<String, dynamic> data) {
    final now = DateTime.now();
    return MenuItemEntity(
      serverId: data['id'] as String?,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Uncategorized',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String?,
      isVeg: data['isVeg'] as bool? ?? true,
      isAvailable: data['isAvailable'] as bool? ?? true,
      preparationTimeMinutes:
          (data['preparationTimeMinutes'] as num?)?.toInt() ?? 15,
      tags: data['tags'] as String?,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      syncStatus: MenuSyncStatus.synced,
      updatedAt: _parseDateTime(data['updatedAt']) ?? now,
      createdAt: _parseDateTime(data['createdAt']) ?? now,
    );
  }

  Map<String, dynamic> toSyncPayload() {
    return {
      'id': serverId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      'isAvailable': isAvailable,
      'preparationTimeMinutes': preparationTimeMinutes,
      'tags': tags,
      'sortOrder': sortOrder,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMenuMap() {
    return {
      'id': serverId ?? 'local_$id',
      'localId': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      'isAvailable': isAvailable,
      'preparationTimeMinutes': preparationTimeMinutes,
      'tags': tags,
      'sortOrder': sortOrder,
      'syncStatus': syncStatus.name,
      'isSynced': syncStatus == MenuSyncStatus.synced,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  MenuItemEntity copyWith({
    Id? id,
    String? serverId,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    bool? isVeg,
    bool? isAvailable,
    int? preparationTimeMinutes,
    String? tags,
    int? sortOrder,
    MenuSyncStatus? syncStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final entity = MenuItemEntity(
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationTimeMinutes:
          preparationTimeMinutes ?? this.preparationTimeMinutes,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
    );
    entity.id = id ?? this.id;
    return entity;
  }

  bool get needsSync => syncStatus != MenuSyncStatus.synced;
  bool get isMarkedForDeletion => syncStatus == MenuSyncStatus.deleted;

  @override
  String toString() =>
      'MenuItemEntity(id: $id, name: $name, category: $category, ₹$price, sync: $syncStatus)';
}
