import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/table_entity.dart';

class TableOfflineController extends ChangeNotifier {
  static TableOfflineController? _instance;
  final Isar _isar;

  TableOfflineController._(this._isar);

  static TableOfflineController get instance {
    _instance ??= TableOfflineController._(IsarService.instance.isar);
    return _instance!;
  }

  // ── CREATE ──────────────────────────────────────────────────────

  Future<TableEntity> addTable({
    required String tableNumber,
    String section = 'Main',
    int capacity = 4,
  }) async {
    final table = TableEntity.create(
      tableNumber: tableNumber,
      section: section,
      capacity: capacity,
      status: TableStatus.empty,
    );
    await _isar.writeTxn(() async {
      await _isar.tableEntitys.put(table);
    });
    notifyListeners();
    return table;
  }

  // ── READ ────────────────────────────────────────────────────────

  Future<List<TableEntity>> getAllTables() async {
    return _isar.tableEntitys
        .filter()
        .not()
        .syncStatusEqualTo(TableSyncStatus.deleted)
        .sortBySection()
        .thenByTableNumber()
        .findAll();
  }

  Stream<List<TableEntity>> watchAllTables() {
    return _isar.tableEntitys
        .filter()
        .not()
        .syncStatusEqualTo(TableSyncStatus.deleted)
        .sortBySection()
        .thenByTableNumber()
        .watch(fireImmediately: true);
  }

  Future<List<TableEntity>> getTablesByStatus(TableStatus status) async {
    return _isar.tableEntitys
        .filter()
        .statusEqualTo(status)
        .not()
        .syncStatusEqualTo(TableSyncStatus.deleted)
        .findAll();
  }

  Future<TableEntity?> getTableById(Id id) async {
    return _isar.tableEntitys.get(id);
  }

  Future<List<String>> getAllSections() async {
    final tables = await getAllTables();
    return tables.map((t) => t.section).toSet().toList()..sort();
  }

  // ── STATUS TRANSITIONS ──────────────────────────────────────────

  Future<TableEntity?> setStatus(
    Id id,
    TableStatus newStatus, {
    String? guestName,
    String? guestPhone,
    String? notes,
    int? occupiedSeats,
  }) async {
    final table = await _isar.tableEntitys.get(id);
    if (table == null) return null;

    final now = DateTime.now();
    DateTime? newOccupiedAt = table.occupiedAt;
    DateTime? newClearedAt = table.clearedAt;

    if (newStatus == TableStatus.active && table.status != TableStatus.active) {
      newOccupiedAt = now;
    }
    if (newStatus == TableStatus.empty) {
      newClearedAt = now;
      newOccupiedAt = null;
    }

    final TableSyncStatus newSyncStatus;
    switch (table.syncStatus) {
      case TableSyncStatus.newRecord:
        newSyncStatus = TableSyncStatus.newRecord;
        break;
      case TableSyncStatus.synced:
        newSyncStatus = TableSyncStatus.updated;
        break;
      default:
        newSyncStatus = table.syncStatus;
    }

    final updated = table.copyWith(
      status: newStatus,
      guestName: guestName ?? table.guestName,
      guestPhone: guestPhone ?? table.guestPhone,
      notes: notes ?? table.notes,
      occupiedSeats: occupiedSeats ?? table.occupiedSeats,
      occupiedAt: newOccupiedAt,
      clearedAt: newClearedAt,
      syncStatus: newSyncStatus,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.tableEntitys.put(updated);
    });
    notifyListeners();
    return updated;
  }

  Future<TableEntity?> updateTable({
    required Id id,
    String? tableNumber,
    String? section,
    int? capacity,
    String? guestName,
    String? guestPhone,
    String? notes,
    String? currentOrderId,
  }) async {
    final table = await _isar.tableEntitys.get(id);
    if (table == null) return null;

    final TableSyncStatus newSyncStatus;
    switch (table.syncStatus) {
      case TableSyncStatus.newRecord:
        newSyncStatus = TableSyncStatus.newRecord;
        break;
      case TableSyncStatus.synced:
        newSyncStatus = TableSyncStatus.updated;
        break;
      default:
        newSyncStatus = table.syncStatus;
    }

    final updated = table.copyWith(
      tableNumber: tableNumber,
      section: section,
      capacity: capacity,
      guestName: guestName,
      guestPhone: guestPhone,
      notes: notes,
      currentOrderId: currentOrderId,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.tableEntitys.put(updated);
    });
    notifyListeners();
    return updated;
  }

  Future<void> deleteTable(Id id) async {
    final table = await _isar.tableEntitys.get(id);
    if (table == null) return;

    if (table.syncStatus == TableSyncStatus.newRecord) {
      // Never synced — hard delete
      await _isar.writeTxn(() async {
        await _isar.tableEntitys.delete(id);
      });
    } else {
      // Mark for server deletion
      final updated = table.copyWith(
        syncStatus: TableSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() async {
        await _isar.tableEntitys.put(updated);
      });
    }
    notifyListeners();
  }

  /// Resets guest info and sets status to [TableStatus.empty].
  /// Called after a bill is generated.
  Future<void> clearTable(Id id) async {
    final table = await _isar.tableEntitys.get(id);
    if (table == null) return;

    final TableSyncStatus newSyncStatus;
    switch (table.syncStatus) {
      case TableSyncStatus.newRecord:
        newSyncStatus = TableSyncStatus.newRecord;
        break;
      case TableSyncStatus.synced:
        newSyncStatus = TableSyncStatus.updated;
        break;
      default:
        newSyncStatus = table.syncStatus;
    }

    final cleared =
        table.copyWith(
            status: TableStatus.empty,
            occupiedSeats: 0,
            syncStatus: newSyncStatus,
            clearedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
          ..guestName = null
          ..guestPhone = null
          ..notes = null
          ..currentOrderId = null
          ..occupiedAt = null;

    await _isar.writeTxn(() async {
      await _isar.tableEntitys.put(cleared);
    });
    notifyListeners();
  }

  // ── SYNC HELPERS ────────────────────────────────────────────────

  Future<List<TableEntity>> getPendingSync() async {
    return _isar.tableEntitys
        .filter()
        .not()
        .syncStatusEqualTo(TableSyncStatus.synced)
        .findAll();
  }

  Future<void> importFromServer(List<Map<String, dynamic>> serverItems) async {
    final all = await _isar.tableEntitys.where().findAll();
    final localByServerId = {
      for (final t in all)
        if (t.serverId != null) t.serverId!: t,
    };

    await _isar.writeTxn(() async {
      for (final data in serverItems) {
        final sid = data['id'] as String?;
        if (sid == null) continue;

        final local = localByServerId[sid];
        if (local == null) {
          // New from server
          await _isar.tableEntitys.put(TableEntity.fromServer(data));
        } else if (local.syncStatus == TableSyncStatus.synced) {
          // Server wins for synced records
          final merged = TableEntity.fromServer(data)..id = local.id;
          await _isar.tableEntitys.put(merged);
        }
        // Local pending changes win otherwise
      }
    });
    notifyListeners();
  }
}
