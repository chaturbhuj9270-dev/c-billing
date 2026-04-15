import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/menu_item_entity.dart';

class MenuOfflineController extends ChangeNotifier {
  static MenuOfflineController? _instance;
  final Isar _isar;

  MenuOfflineController._(this._isar);

  static MenuOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = MenuOfflineController._(isar);
    }
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  Future<MenuItemEntity> addMenuItem({
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
  }) async {
    final item = MenuItemEntity.create(
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
      syncStatus: MenuSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.menuItemEntitys.put(item);
    });

    debugPrint('[MenuOffline] Item added: ${item.id}, name: ${item.name}');
    notifyListeners();
    return item;
  }

  // ==================== READ ====================

  Future<List<MenuItemEntity>> getAllMenuItems() async {
    return await _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.deleted)
        .sortByCategory()
        .thenBySortOrder()
        .findAll();
  }

  Stream<List<MenuItemEntity>> watchAllMenuItems() {
    return _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.deleted)
        .sortByCategory()
        .thenBySortOrder()
        .watch(fireImmediately: true);
  }

  Future<MenuItemEntity?> getMenuItemById(Id id) async {
    return await _isar.menuItemEntitys.get(id);
  }

  Future<MenuItemEntity?> getMenuItemByServerId(String serverId) async {
    return await _isar.menuItemEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  Future<List<MenuItemEntity>> getMenuItemsByCategory(String category) async {
    return await _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.deleted)
        .categoryEqualTo(category, caseSensitive: false)
        .sortBySortOrder()
        .findAll();
  }

  Future<List<String>> getAllCategories() async {
    final items = await getAllMenuItems();
    final categories = items.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<List<MenuItemEntity>> searchMenuItems(String query) async {
    if (query.isEmpty) return getAllMenuItems();

    return await _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.deleted)
        .group(
          (q) => q
              .nameContains(query, caseSensitive: false)
              .or()
              .categoryContains(query, caseSensitive: false)
              .or()
              .descriptionContains(query, caseSensitive: false),
        )
        .sortByCategory()
        .thenBySortOrder()
        .findAll();
  }

  // ==================== UPDATE ====================

  Future<MenuItemEntity?> updateMenuItem({
    required Id id,
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
  }) async {
    final existing = await _isar.menuItemEntitys.get(id);
    if (existing == null) return null;

    MenuSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case MenuSyncStatus.newRecord:
        newSyncStatus = MenuSyncStatus.newRecord;
        break;
      case MenuSyncStatus.synced:
        newSyncStatus = MenuSyncStatus.updated;
        break;
      case MenuSyncStatus.updated:
        newSyncStatus = MenuSyncStatus.updated;
        break;
      case MenuSyncStatus.deleted:
        newSyncStatus = MenuSyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
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
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.menuItemEntitys.put(updated);
    });

    debugPrint(
      '[MenuOffline] Item updated: ${updated.id}, syncStatus: ${updated.syncStatus}',
    );
    notifyListeners();
    return updated;
  }

  Future<void> toggleAvailability(Id id) async {
    final existing = await _isar.menuItemEntitys.get(id);
    if (existing == null) return;

    await updateMenuItem(id: id, isAvailable: !existing.isAvailable);
  }

  // ==================== DELETE ====================

  Future<void> deleteMenuItem(Id id) async {
    final existing = await _isar.menuItemEntitys.get(id);
    if (existing == null) return;

    if (existing.syncStatus == MenuSyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.menuItemEntitys.delete(id);
      });
      debugPrint('[MenuOffline] Item hard deleted (never synced): $id');
    } else {
      final deleted = existing.copyWith(
        syncStatus: MenuSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() async {
        await _isar.menuItemEntitys.put(deleted);
      });
      debugPrint('[MenuOffline] Item marked for deletion: $id');
    }

    notifyListeners();
  }

  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.menuItemEntitys.delete(id);
    });
    debugPrint('[MenuOffline] Item permanently deleted: $id');
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  Future<List<MenuItemEntity>> getItemsNeedingSync() async {
    return await _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.synced)
        .findAll();
  }

  Future<int> getUnsyncedCount() async {
    return await _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.synced)
        .count();
  }

  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.menuItemEntitys.get(id);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: MenuSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.menuItemEntitys.put(synced);
    });

    debugPrint('[MenuOffline] Item synced: $id -> $serverId');
  }

  Future<void> importFromServer(List<Map<String, dynamic>> serverItems) async {
    debugPrint(
      '[MenuOffline] Importing ${serverItems.length} items from server',
    );
    int newCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;

    await _isar.writeTxn(() async {
      for (final data in serverItems) {
        final serverId = data['id'] as String?;
        final name = (data['name'] ?? '').toString();

        if (serverId == null) {
          skippedCount++;
          continue;
        }

        var existing = await _isar.menuItemEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing == null && name.isNotEmpty) {
          existing = await _isar.menuItemEntitys
              .filter()
              .nameEqualTo(name, caseSensitive: false)
              .findFirst();
          if (existing != null && existing.serverId == null) {
            existing.serverId = serverId;
            existing.syncStatus = MenuSyncStatus.synced;
            await _isar.menuItemEntitys.put(existing);
            continue;
          }
        }

        if (existing == null) {
          final item = MenuItemEntity.fromServer(data);
          await _isar.menuItemEntitys.put(item);
          newCount++;
        } else if (existing.syncStatus == MenuSyncStatus.synced) {
          final updated = MenuItemEntity.fromServer(data);
          updated.id = existing.id;
          await _isar.menuItemEntitys.put(updated);
          updatedCount++;
        } else {
          skippedCount++;
        }
      }
    });

    debugPrint(
      '[MenuOffline] Import done: $newCount new, $updatedCount updated, $skippedCount skipped',
    );
    notifyListeners();
  }

  Future<int> getTotalCount() async {
    return await _isar.menuItemEntitys
        .filter()
        .not()
        .syncStatusEqualTo(MenuSyncStatus.deleted)
        .count();
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.menuItemEntitys.clear();
    });
    notifyListeners();
  }
}
