import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
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

  final AppDatabase _db;

  SupplierOfflineController._(this._db);

  /// Get the singleton instance
  static SupplierOfflineController get instance {
    _instance ??= SupplierOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  // ==================== CREATE ====================

  /// Check if a supplier code already exists (for uniqueness validation)
  /// Empty codes are allowed (not enforced as unique)
  Future<bool> isSupplierCodeTaken(String code, {int? excludeId}) async {
    if (code.trim().isEmpty) return false; // Empty codes are allowed

    final needle = code.toLowerCase();
    final existing = (await _db.loadSuppliers()).where(
      (supplier) =>
          supplier.syncStatus != SupplierSyncStatus.deleted &&
          supplier.supplierCode.toLowerCase() == needle,
    );
    if (excludeId != null) {
      return existing.any((e) => e.id != excludeId);
    }
    return existing.isNotEmpty;
  }

  /// Add a new supplier locally (will be synced later)
  /// Sets syncStatus = NEW, does NOT call API
  Future<SupplierEntity> addSupplier({
    required String firstName,
    String middleName = '',
    String lastName = '',
    required String supplierCode,
    required String contact,
    String address = '',
    bool isActive = true,
  }) async {
    debugPrint(
      '[SupplierOffline] Adding supplier: $firstName $lastName (code: $supplierCode)',
    );

    // Validate uniqueness of supplier code
    final codeTaken = await isSupplierCodeTaken(supplierCode);
    if (codeTaken) {
      throw Exception('Supplier code "$supplierCode" already exists');
    }

    final supplier = SupplierEntity.create(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      supplierCode: supplierCode,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: SupplierSyncStatus.newRecord, // Mark as NEW for sync
    );

    await _db.saveSupplier(supplier);

    debugPrint('[SupplierOffline] Supplier saved with ID: ${supplier.id}');
    notifyListeners();
    return supplier;
  }

  // ==================== READ ====================

  /// Get all active (non-deleted) suppliers
  /// Uses indexed query for performance
  Future<List<SupplierEntity>> getAllSuppliers() async {
    final suppliers = (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus != SupplierSyncStatus.deleted)
        .toList();
    suppliers.sort((a, b) => a.firstName.compareTo(b.firstName));
    return suppliers;
  }

  /// Watch all active suppliers (reactive stream for UI)
  /// Fires immediately and on any changes
  Stream<List<SupplierEntity>> watchAllSuppliers() {
    return _db.watchSuppliers().map((rows) {
      final suppliers = rows
          .where((supplier) => supplier.syncStatus != SupplierSyncStatus.deleted)
          .toList();
      suppliers.sort((a, b) => a.firstName.compareTo(b.firstName));
      return suppliers;
    });
  }

  /// Get supplier by local id
  Future<SupplierEntity?> getSupplierById(int id) async {
    for (final supplier in await _db.loadSuppliers()) {
      if (supplier.id == id) return supplier;
    }
    return null;
  }

  /// Get supplier by server ID
  Future<SupplierEntity?> getSupplierByServerId(String serverId) async {
    for (final supplier in await _db.loadSuppliers()) {
      if (supplier.serverId == serverId) return supplier;
    }
    return null;
  }

  /// Get supplier by contact number (fast indexed lookup)
  Future<SupplierEntity?> getSupplierByContact(String contact) async {
    for (final supplier in await _db.loadSuppliers()) {
      if (supplier.contact == contact &&
          supplier.syncStatus != SupplierSyncStatus.deleted) {
        return supplier;
      }
    }
    return null;
  }

  /// Search suppliers by name
  Future<List<SupplierEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAllSuppliers();

    final needle = query.toLowerCase();
    final suppliers = (await _db.loadSuppliers()).where((supplier) {
      if (supplier.syncStatus == SupplierSyncStatus.deleted) return false;
      return supplier.firstName.toLowerCase().contains(needle) ||
          supplier.lastName.toLowerCase().contains(needle) ||
          supplier.contact.contains(query);
    }).toList();
    suppliers.sort((a, b) => a.firstName.compareTo(b.firstName));
    return suppliers;
  }

  // ==================== UPDATE ====================

  /// Update an existing supplier
  /// If syncStatus was SYNCED, changes to UPDATED
  /// If syncStatus was NEW, keeps as NEW (not yet on server)
  Future<SupplierEntity?> updateSupplier({
    required int id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? supplierCode,
    String? contact,
    String? address,
    bool? isActive,
  }) async {
    final existing = await getSupplierById(id);
    if (existing == null) {
      debugPrint('[SupplierOffline] Supplier not found: $id');
      return null;
    }

    // Validate uniqueness of supplier code if changed
    if (supplierCode != null && supplierCode != existing.supplierCode) {
      final codeTaken = await isSupplierCodeTaken(supplierCode, excludeId: id);
      if (codeTaken) {
        throw Exception('Supplier code "$supplierCode" already exists');
      }
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
      supplierCode: supplierCode,
      contact: contact,
      address: address,
      isActive: isActive,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _db.saveSupplier(updated);

    debugPrint(
      '[SupplierOffline] Supplier updated: ${updated.id}, syncStatus: ${updated.syncStatus}',
    );
    notifyListeners();
    return updated;
  }

  // ==================== DELETE ====================

  /// Soft delete a supplier (marks for deletion, will be synced)
  Future<void> deleteSupplier(int id) async {
    final existing = await getSupplierById(id);
    if (existing == null) return;

    // If never synced to server (NEW), we can hard delete immediately
    if (existing.syncStatus == SupplierSyncStatus.newRecord) {
      debugPrint('[SupplierOffline] Hard deleting NEW supplier: $id');
      await _db.deleteSupplierById(id);
    } else {
      // Soft delete - mark for server sync
      debugPrint('[SupplierOffline] Soft deleting supplier: $id');
      final updated = existing.copyWith(
        syncStatus: SupplierSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );

      await _db.saveSupplier(updated);
    }

    notifyListeners();
  }

  /// Hard delete after confirmed server deletion
  Future<void> permanentlyDelete(int id) async {
    await _db.deleteSupplierById(id);
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all suppliers that need to be synced (delta sync)
  /// Returns suppliers where syncStatus != SYNCED
  Future<List<SupplierEntity>> getSuppliersNeedingSync() async {
    return (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus != SupplierSyncStatus.synced)
        .toList();
  }

  /// Get NEW suppliers (need to POST)
  Future<List<SupplierEntity>> getNewSuppliers() async {
    return (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus == SupplierSyncStatus.newRecord)
        .toList();
  }

  /// Get UPDATED suppliers (need to PUT)
  Future<List<SupplierEntity>> getUpdatedSuppliers() async {
    return (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus == SupplierSyncStatus.updated)
        .toList();
  }

  /// Get DELETED suppliers (need to DELETE on server)
  Future<List<SupplierEntity>> getDeletedSuppliers() async {
    return (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus == SupplierSyncStatus.deleted)
        .toList();
  }

  /// Get count of unsynced suppliers
  Future<int> getUnsyncedCount() async {
    return (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus != SupplierSyncStatus.synced)
        .length;
  }

  /// Mark supplier as synced (called after successful server sync)
  Future<void> markAsSynced(int id, {String? serverId}) async {
    final existing = await getSupplierById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId ?? existing.serverId,
      syncStatus: SupplierSyncStatus.synced,
    );

    await _db.saveSupplier(updated);
  }

  /// Import suppliers from server (for initial sync or refresh)
  /// Merges by serverId, only updates if server version is newer
  Future<int> importFromServer(
    List<Map<String, dynamic>> serverSuppliers,
  ) async {
    var imported = 0;

    await _db.transaction(() async {
      for (final supplierData in serverSuppliers) {
        final serverId = supplierData['id'] as String?;
        if (serverId == null) continue;

        final all = await _db.loadSuppliers();
        SupplierEntity? existing;
        for (final supplier in all) {
          if (supplier.serverId == serverId) {
            existing = supplier;
            break;
          }
        }

        // Fallback: check by contact (handles locally-created records without serverId yet)
        if (existing == null) {
          final contact = (supplierData['contact'] ?? '').toString();
          if (contact.isNotEmpty) {
            for (final supplier in all) {
              if (supplier.contact == contact) {
                existing = supplier;
                break;
              }
            }
            if (existing != null && existing.serverId == null) {
              // Link local record with server ID and mark synced
              existing.serverId = serverId;
              existing.syncStatus = SupplierSyncStatus.synced;
              await _db.saveSupplier(existing);
              imported++;
              continue;
            }
          }
          // Also check by supplierCode
          final supplierCode = (supplierData['supplierCode'] ?? '').toString();
          if (existing == null && supplierCode.isNotEmpty) {
            for (final supplier in all) {
              if (supplier.supplierCode == supplierCode) {
                existing = supplier;
                break;
              }
            }
            if (existing != null && existing.serverId == null) {
              existing.serverId = serverId;
              existing.syncStatus = SupplierSyncStatus.synced;
              await _db.saveSupplier(existing);
              imported++;
              continue;
            }
          }
        }

        if (existing != null) {
          // Only update if not locally modified AND server is newer
          if (existing.syncStatus == SupplierSyncStatus.synced) {
            final serverUpdatedAt = DateTime.tryParse(
              supplierData['updatedAt']?.toString() ?? '',
            );
            if (serverUpdatedAt != null &&
                serverUpdatedAt.isAfter(existing.updatedAt)) {
              final updated = SupplierEntity.fromServer(supplierData);
              updated.id = existing.id; // Keep local ID
              await _db.saveSupplier(updated);
              imported++;
            }
          }
          // If locally modified, don't overwrite - local changes take precedence
        } else {
          // Create new
          final newSupplier = SupplierEntity.fromServer(supplierData);
          await _db.saveSupplier(newSupplier);
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
  Future<void> updateWithServerResponse(
    int localId,
    Map<String, dynamic> serverResponse,
  ) async {
    final existing = await getSupplierById(localId);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverResponse['id'] as String?,
      syncStatus: SupplierSyncStatus.synced,
    );

    await _db.saveSupplier(updated);
  }

  /// Get total supplier count
  Future<int> getTotalCount() async {
    return (await _db.loadSuppliers())
        .where((supplier) => supplier.syncStatus != SupplierSyncStatus.deleted)
        .length;
  }
}
