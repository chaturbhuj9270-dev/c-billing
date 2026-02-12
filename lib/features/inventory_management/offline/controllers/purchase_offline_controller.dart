import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/purchase_entity.dart';

/// Offline-first controller for Purchase CRUD operations
/// All operations go to local Isar first, then sync in background
class PurchaseOfflineController extends ChangeNotifier {
  static PurchaseOfflineController? _instance;
  
  final Isar _isar;

  PurchaseOfflineController._(this._isar);

  /// Get the singleton instance
  static PurchaseOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = PurchaseOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Add a new purchase locally
  /// Sets syncStatus to NEW for background sync
  Future<PurchaseEntity> addPurchase({
    required String productId,
    required String productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    required int quantity,
    required String unit,
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    final purchase = PurchaseEntity.create(
      productId: productId,
      productName: productName,
      supplierId: supplierId,
      supplierName: supplierName,
      companyId: companyId,
      companyName: companyName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: PurchaseSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.purchaseEntitys.put(purchase);
    });

    debugPrint('[PurchaseOffline] Purchase added: ${purchase.id}, product: ${purchase.productName}, status: NEW');
    notifyListeners();
    return purchase;
  }

  // ==================== READ ====================

  /// Get all purchases (excluding deleted)
  Future<List<PurchaseEntity>> getAllPurchases() async {
    return await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Watch all purchases for real-time updates (excluding deleted)
  Stream<List<PurchaseEntity>> watchAllPurchases() {
    return _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Get purchase by local Isar ID
  Future<PurchaseEntity?> getPurchaseById(Id id) async {
    return await _isar.purchaseEntitys.get(id);
  }

  /// Get purchase by server ID
  Future<PurchaseEntity?> getPurchaseByServerId(String serverId) async {
    return await _isar.purchaseEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get purchases by product ID
  Future<List<PurchaseEntity>> getPurchasesByProductId(String productId) async {
    return await _isar.purchaseEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get purchases by supplier ID
  Future<List<PurchaseEntity>> getPurchasesBySupplierId(String supplierId) async {
    return await _isar.purchaseEntitys
        .filter()
        .supplierIdEqualTo(supplierId)
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get purchases by company ID
  Future<List<PurchaseEntity>> getPurchasesByCompanyId(String companyId) async {
    return await _isar.purchaseEntitys
        .filter()
        .companyIdEqualTo(companyId)
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get recent purchases (last N)
  Future<List<PurchaseEntity>> getRecentPurchases({int limit = 50}) async {
    return await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update an existing purchase
  /// If syncStatus was SYNCED, changes to UPDATED
  /// If syncStatus was NEW, keeps as NEW (not yet on server)
  Future<PurchaseEntity?> updatePurchase({
    required Id id,
    int? quantity,
    String? unit,
    double? purchasePrice,
    double? salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    final existing = await _isar.purchaseEntitys.get(id);
    if (existing == null) {
      debugPrint('[PurchaseOffline] Purchase not found: $id');
      return null;
    }

    // Determine new syncStatus
    PurchaseSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case PurchaseSyncStatus.newRecord:
        newSyncStatus = PurchaseSyncStatus.newRecord;
        break;
      case PurchaseSyncStatus.synced:
        newSyncStatus = PurchaseSyncStatus.updated;
        break;
      case PurchaseSyncStatus.updated:
        newSyncStatus = PurchaseSyncStatus.updated;
        break;
      case PurchaseSyncStatus.deleted:
        newSyncStatus = PurchaseSyncStatus.deleted;
        break;
    }

    // Recalculate total if quantity or price changed
    final newQuantity = quantity ?? existing.quantity;
    final newPrice = purchasePrice ?? existing.purchasePrice;
    final newTotal = newQuantity * newPrice;

    final updated = existing.copyWith(
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      totalAmount: newTotal,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.purchaseEntitys.put(updated);
    });

    debugPrint('[PurchaseOffline] Purchase updated: ${updated.id}, syncStatus: ${updated.syncStatus}');
    notifyListeners();
    return updated;
  }

  // ==================== DELETE ====================

  /// Soft delete a purchase (mark for deletion, don't remove from DB)
  /// This allows background sync to delete from server first
  Future<void> deletePurchase(Id id) async {
    final existing = await _isar.purchaseEntitys.get(id);
    if (existing == null) {
      debugPrint('[PurchaseOffline] Purchase not found for delete: $id');
      return;
    }

    // If it's a NEW record (never synced), we can hard delete
    if (existing.syncStatus == PurchaseSyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.purchaseEntitys.delete(id);
      });
      debugPrint('[PurchaseOffline] Purchase hard deleted (was never synced): $id');
    } else {
      // Mark for deletion - background sync will delete from server
      final deleted = existing.copyWith(
        syncStatus: PurchaseSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() async {
        await _isar.purchaseEntitys.put(deleted);
      });
      debugPrint('[PurchaseOffline] Purchase marked for deletion: $id');
    }

    notifyListeners();
  }

  /// Hard delete after successful server deletion
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.purchaseEntitys.delete(id);
    });
    debugPrint('[PurchaseOffline] Purchase permanently deleted: $id');
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all purchases that need to be synced to server
  Future<List<PurchaseEntity>> getPurchasesNeedingSync() async {
    return await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.synced)
        .findAll();
  }

  /// Get count of unsynced purchases
  Future<int> getUnsyncedCount() async {
    return await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.synced)
        .count();
  }

  /// Mark a purchase as synced (after successful server sync)
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.purchaseEntitys.get(id);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: PurchaseSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.purchaseEntitys.put(synced);
    });

    debugPrint('[PurchaseOffline] Purchase marked as synced: $id -> $serverId');
  }

  /// Import purchases from server (initial load or refresh)
  /// Only updates if server data is newer
  Future<void> importFromServer(List<Map<String, dynamic>> serverPurchases) async {
    await _isar.writeTxn(() async {
      for (final data in serverPurchases) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        // Check if we already have this purchase
        final existing = await _isar.purchaseEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing == null) {
          // New purchase from server
          final purchase = PurchaseEntity.fromServer(data);
          await _isar.purchaseEntitys.put(purchase);
        } else if (existing.syncStatus == PurchaseSyncStatus.synced) {
          // Only update if local is synced (no local changes)
          final updated = PurchaseEntity.fromServer(data);
          updated.id = existing.id;
          await _isar.purchaseEntitys.put(updated);
        }
        // If local has changes (NEW, UPDATED, DELETED), don't overwrite
      }
    });

    debugPrint('[PurchaseOffline] Imported ${serverPurchases.length} purchases from server');
    notifyListeners();
  }

  // ==================== STATISTICS ====================

  /// Get total purchase count
  Future<int> getTotalCount() async {
    return await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .count();
  }

  /// Get purchases by date range
  Future<List<PurchaseEntity>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .createdAtBetween(startDate, endDate)
        .findAll();
  }

  /// Get total purchase amount for a date range
  Future<double> getTotalPurchaseAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted);

    if (startDate != null) {
      query = query.createdAtGreaterThan(startDate);
    }
    if (endDate != null) {
      query = query.createdAtLessThan(endDate);
    }

    final purchases = await query.findAll();
    return purchases.fold<double>(0.0, (sum, p) => sum + p.totalAmount);
  }

  /// Clear all local purchases (use with caution)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.purchaseEntitys.clear();
    });
    debugPrint('[PurchaseOffline] All purchases cleared');
    notifyListeners();
  }

  // ==================== SEARCH & FILTER ====================

  /// Search purchases by product name or supplier name
  Future<List<PurchaseEntity>> searchPurchases(String query) async {
    if (query.isEmpty) return getAllPurchases();
    
    final lowerQuery = query.toLowerCase();
    final allPurchases = await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .findAll();
    
    return allPurchases.where((p) {
      return p.productName.toLowerCase().contains(lowerQuery) ||
             (p.supplierName?.toLowerCase().contains(lowerQuery) ?? false) ||
             (p.companyName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get purchases with filters
  Future<List<PurchaseEntity>> getFilteredPurchases({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? supplierId,
    bool? syncedOnly,
    bool? pendingOnly,
  }) async {
    var results = await _isar.purchaseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(PurchaseSyncStatus.deleted)
        .findAll();
    
    // Apply date range filter
    if (startDate != null) {
      results = results.where((p) => p.createdAt.isAfter(startDate) || 
                                     p.createdAt.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      results = results.where((p) => p.createdAt.isBefore(endOfDay) || 
                                     p.createdAt.isAtSameMomentAs(endOfDay)).toList();
    }
    
    // Apply supplier filter
    if (supplierId != null && supplierId.isNotEmpty) {
      results = results.where((p) => p.supplierId == supplierId).toList();
    }
    
    // Apply sync status filter
    if (syncedOnly == true) {
      results = results.where((p) => p.syncStatus == PurchaseSyncStatus.synced).toList();
    } else if (pendingOnly == true) {
      results = results.where((p) => p.syncStatus != PurchaseSyncStatus.synced).toList();
    }
    
    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      results = results.where((p) {
        return p.productName.toLowerCase().contains(lowerQuery) ||
               (p.supplierName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    
    // Sort by created date descending
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Get all unique suppliers from purchases
  Future<List<Map<String, String>>> getUniqueSuppliers() async {
    final purchases = await getAllPurchases();
    final suppliers = <String, String>{};
    
    for (final p in purchases) {
      if (p.supplierId != null && p.supplierName != null) {
        suppliers[p.supplierId!] = p.supplierName!;
      }
    }
    
    return suppliers.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  /// Bulk update purchase quantities (for stock adjustment)
  Future<void> bulkUpdateQuantities(List<Map<String, dynamic>> updates) async {
    await _isar.writeTxn(() async {
      for (final update in updates) {
        final id = update['id'] as Id;
        final addedQty = update['addedQty'] as int;
        
        final existing = await _isar.purchaseEntitys.get(id);
        if (existing == null) continue;
        
        // Determine new sync status
        PurchaseSyncStatus newSyncStatus;
        if (existing.syncStatus == PurchaseSyncStatus.newRecord) {
          newSyncStatus = PurchaseSyncStatus.newRecord;
        } else {
          newSyncStatus = PurchaseSyncStatus.updated;
        }
        
        final newQuantity = existing.quantity + addedQty;
        final newTotal = newQuantity * existing.purchasePrice;
        
        final updated = existing.copyWith(
          quantity: newQuantity,
          totalAmount: newTotal,
          syncStatus: newSyncStatus,
          updatedAt: DateTime.now(),
        );
        
        await _isar.purchaseEntitys.put(updated);
        debugPrint('[PurchaseOffline] Bulk updated purchase: ${updated.id}, qty: $newQuantity');
      }
    });
    
    notifyListeners();
  }
}
