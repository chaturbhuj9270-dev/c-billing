import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/supplier_entity.dart';

/// Controller for handling offline-first Supplier CRUD operations
/// All UI reads should go through this controller (never directly from API)
/// 
/// Key features:
/// - Immediate local saves (no network blocking)
/// - Proper syncStatus management for delta sync
/// - High-performance indexed queries
/// - Reactive streams for UI updates
class SupplierOfflineController extends ChangeNotifier {
  static SupplierOfflineController? _instance;
  
  Isar get _isar => IsarService.instance.isar;

  SupplierOfflineController._();

  /// Get the singleton instance
  static SupplierOfflineController get instance {
    _instance ??= SupplierOfflineController._();
    return _instance!;
  }

  // ==================== CREATE ====================

  /// Add a new supplier locally (will be synced later)
  /// Sets syncStatus = NEW, does NOT call API
  Future<SupplierEntity> addSupplier({
    required String firstName,
    String middleName = '',
    String lastName = '',
    required String contact,
    String address = '',
    bool isActive = true,
  }) async {
    debugPrint('[SupplierOffline] Adding supplier: $firstName $lastName');
    
    final supplier = SupplierEntity.create(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: SupplierSyncStatus.newRecord, // Mark as NEW for sync
    );

    await _isar.writeTxn(() async {
      await _isar.supplierEntitys.put(supplier);
    });
    
    debugPrint('[SupplierOffline] Supplier saved with ID: ${supplier.id}');
    notifyListeners();
    return supplier;
  }

  // ==================== READ ====================

  /// Get all active (non-deleted) suppliers
  /// Uses indexed query for performance
  Future<List<SupplierEntity>> getAllSuppliers() async {
    return await _isar.supplierEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .sortByFirstName()
        .findAll();
  }

  /// Watch all active suppliers (reactive stream for UI)
  /// Fires immediately and on any changes
  Stream<List<SupplierEntity>> watchAllSuppliers() {
    return _isar.supplierEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .sortByFirstName()
        .watch(fireImmediately: true);
  }

  /// Get supplier by local Isar ID
  Future<SupplierEntity?> getSupplierById(Id id) async {
    return await _isar.supplierEntitys.get(id);
  }

  /// Get supplier by server ID
  Future<SupplierEntity?> getSupplierByServerId(String serverId) async {
    return await _isar.supplierEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get supplier by contact number (fast indexed lookup)
  Future<SupplierEntity?> getSupplierByContact(String contact) async {
    return await _isar.supplierEntitys
        .filter()
        .contactEqualTo(contact)
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .findFirst();
  }

  /// Search suppliers by name
  Future<List<SupplierEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAllSuppliers();
    
    return await _isar.supplierEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .group((q) => q
            .firstNameContains(query, caseSensitive: false)
            .or()
            .lastNameContains(query, caseSensitive: false)
            .or()
            .contactContains(query))
        .sortByFirstName()
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update an existing supplier
  /// If syncStatus was SYNCED, changes to UPDATED
  /// If syncStatus was NEW, keeps as NEW (not yet on server)
  Future<SupplierEntity?> updateSupplier({
    required Id id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? contact,
    String? address,
    bool? isActive,
  }) async {
    final existing = await _isar.supplierEntitys.get(id);
    if (existing == null) {
      debugPrint('[SupplierOffline] Supplier not found: $id');
      return null;
    }

    // Determine new syncStatus
    SupplierSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case SupplierSyncStatus.newRecord:
        newSyncStatus = SupplierSyncStatus.newRecord;
        break;
      case SupplierSyncStatus.synced:
        newSyncStatus = SupplierSyncStatus.updated;
        break;
      case SupplierSyncStatus.updated:
        newSyncStatus = SupplierSyncStatus.updated;
        break;
      case SupplierSyncStatus.deleted:
        newSyncStatus = SupplierSyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.supplierEntitys.put(updated);
    });

    debugPrint('[SupplierOffline] Supplier updated: ${updated.id}, syncStatus: ${updated.syncStatus}');
    notifyListeners();
    return updated;
  }

  // ==================== DELETE ====================

  /// Soft delete a supplier (marks for deletion, will be synced)
  /// Does NOT remove from Isar until server confirms deletion
  Future<void> deleteSupplier(Id id) async {
    final existing = await _isar.supplierEntitys.get(id);
    if (existing == null) return;

    // If never synced to server (NEW), we can hard delete immediately
    if (existing.syncStatus == SupplierSyncStatus.newRecord) {
      debugPrint('[SupplierOffline] Hard deleting NEW supplier: $id');
      await _isar.writeTxn(() async {
        await _isar.supplierEntitys.delete(id);
      });
    } else {
      // Soft delete - mark for server sync
      debugPrint('[SupplierOffline] Soft deleting supplier: $id');
      final updated = existing.copyWith(
        syncStatus: SupplierSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );

      await _isar.writeTxn(() async {
        await _isar.supplierEntitys.put(updated);
      });
    }

    notifyListeners();
  }

  /// Hard delete after confirmed server deletion
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.supplierEntitys.delete(id);
    });
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all suppliers that need to be synced (delta sync)
  /// Returns suppliers where syncStatus != SYNCED
  Future<List<SupplierEntity>> getSuppliersNeedingSync() async {
    return await _isar.supplierEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.synced)
        .findAll();
  }

  /// Get NEW suppliers (need to POST)
  Future<List<SupplierEntity>> getNewSuppliers() async {
    return await _isar.supplierEntitys
        .filter()
        .syncStatusEqualTo(SupplierSyncStatus.newRecord)
        .findAll();
  }

  /// Get UPDATED suppliers (need to PUT)
  Future<List<SupplierEntity>> getUpdatedSuppliers() async {
    return await _isar.supplierEntitys
        .filter()
        .syncStatusEqualTo(SupplierSyncStatus.updated)
        .findAll();
  }

  /// Get DELETED suppliers (need to DELETE on server)
  Future<List<SupplierEntity>> getDeletedSuppliers() async {
    return await _isar.supplierEntitys
        .filter()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .findAll();
  }

  /// Get count of unsynced suppliers
  Future<int> getUnsyncedCount() async {
    return await _isar.supplierEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.synced)
        .count();
  }

  /// Mark supplier as synced (called after successful server sync)
  Future<void> markAsSynced(Id id, {String? serverId}) async {
    final existing = await _isar.supplierEntitys.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId ?? existing.serverId,
      syncStatus: SupplierSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.supplierEntitys.put(updated);
    });
  }

  /// Import suppliers from server (for initial sync or refresh)
  /// Merges by serverId, only updates if server version is newer
  Future<int> importFromServer(List<Map<String, dynamic>> serverSuppliers) async {
    int imported = 0;
    
    await _isar.writeTxn(() async {
      for (final supplierData in serverSuppliers) {
        final serverId = supplierData['id'] as String?;
        if (serverId == null) continue;

        // Check if exists locally by serverId
        final existing = await _isar.supplierEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing != null) {
          // Only update if not locally modified AND server is newer
          if (existing.syncStatus == SupplierSyncStatus.synced) {
            final serverUpdatedAt = DateTime.tryParse(
              supplierData['updatedAt']?.toString() ?? '',
            );
            if (serverUpdatedAt != null && serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = SupplierEntity.fromServer(supplierData);
              updated.id = existing.id; // Keep local ID
              await _isar.supplierEntitys.put(updated);
              imported++;
            }
          }
          // If locally modified, don't overwrite - local changes take precedence
        } else {
          // Create new
          final newSupplier = SupplierEntity.fromServer(supplierData);
          await _isar.supplierEntitys.put(newSupplier);
          imported++;
        }
      }
    });

    if (imported > 0) {
      notifyListeners();
    }
    
    debugPrint('[SupplierOffline] Imported $imported suppliers from server');
    return imported;
  }

  /// Update supplier with server response (after successful create)
  Future<void> updateWithServerResponse(Id localId, Map<String, dynamic> serverResponse) async {
    final existing = await _isar.supplierEntitys.get(localId);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverResponse['id'] as String?,
      syncStatus: SupplierSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.supplierEntitys.put(updated);
    });
  }

  /// Get total supplier count
  Future<int> getTotalCount() async {
    return await _isar.supplierEntitys
        .filter()
        .not()
        .syncStatusEqualTo(SupplierSyncStatus.deleted)
        .count();
  }
}
