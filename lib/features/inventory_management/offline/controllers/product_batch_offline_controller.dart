import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/product_batch_entity.dart';
import '../entities/stock_ledger_entity.dart';

/// Offline-first controller for Product Batch CRUD operations
/// All operations go to local Isar first, then sync in background
/// Supports FIFO/LIFO stock tracking, multi-company products, and batch management
class ProductBatchOfflineController extends ChangeNotifier {
  static ProductBatchOfflineController? _instance;

  final Isar _isar;

  ProductBatchOfflineController._(this._isar);

  /// Get the singleton instance
  static ProductBatchOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = ProductBatchOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Create a new product batch (typically when recording a purchase)
  /// Returns the created batch entity
  Future<ProductBatchEntity> createBatch({
    required String productId,
    required String productName,
    required String companyId,
    required String companyName,
    required String supplierId,
    required String supplierName,
    required double quantity,
    required String unit,
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
    String? purchaseId,
  }) async {
    final batch = ProductBatchEntity.create(
      productId: productId,
      productName: productName,
      companyId: companyId,
      companyName: companyName,
      supplierId: supplierId,
      supplierName: supplierName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      salesPrice: salesPrice,
      productionDate: productionDate,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      purchaseId: purchaseId,
      syncStatus: BatchSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.put(batch);
    });

    debugPrint('[BatchOffline] Batch created: ${batch.id}, batch#: ${batch.batchNumber}, '
        'product: ${batch.productName}, company: ${batch.companyName}, '
        'qty: ${batch.currentQuantity}, status: NEW');
    notifyListeners();
    return batch;
  }

  // ==================== READ ====================

  /// Get all batches (excluding deleted)
  Future<List<ProductBatchEntity>> getAllBatches() async {
    return await _isar.productBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Watch all batches for real-time updates (excluding deleted)
  Stream<List<ProductBatchEntity>> watchAllBatches() {
    return _isar.productBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Get batch by local Isar ID
  Future<ProductBatchEntity?> getBatchById(Id id) async {
    return await _isar.productBatchEntitys.get(id);
  }

  /// Get batch by server ID
  Future<ProductBatchEntity?> getBatchByServerId(String serverId) async {
    return await _isar.productBatchEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get all active batches for a product (has stock, not deleted)
  Future<List<ProductBatchEntity>> getActiveBatches(String productId) async {
    return await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDate()
        .findAll();
  }

  /// Get active batches sorted by purchase date (oldest first - for FIFO)
  Future<List<ProductBatchEntity>> getActiveBatchesSortedByDate(String productId) async {
    return await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .currentQuantityGreaterThan(0)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDate() // Ascending = oldest first = FIFO
        .findAll();
  }

  /// Get active batches sorted by purchase date descending (newest first - for LIFO)
  Future<List<ProductBatchEntity>> getActiveBatchesSortedByDateDesc(String productId) async {
    return await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .currentQuantityGreaterThan(0)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDateDesc() // Descending = newest first = LIFO
        .findAll();
  }

  /// Get all batches for a product from a specific company
  Future<List<ProductBatchEntity>> getBatchesByCompany(String productId, String companyId) async {
    return await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .companyIdEqualTo(companyId)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDateDesc()
        .findAll();
  }

  /// Get all batches for a product (including exhausted, for history)
  Future<List<ProductBatchEntity>> getAllBatchesForProduct(String productId) async {
    return await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDateDesc()
        .findAll();
  }

  /// Get batches by supplier
  Future<List<ProductBatchEntity>> getBatchesBySupplier(String supplierId) async {
    return await _isar.productBatchEntitys
        .filter()
        .supplierIdEqualTo(supplierId)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDateDesc()
        .findAll();
  }

  /// Get expired batches (for alerts)
  Future<List<ProductBatchEntity>> getExpiredBatches() async {
    final now = DateTime.now();
    return await _isar.productBatchEntitys
        .filter()
        .statusEqualTo(BatchStatus.active)
        .expiryDateIsNotNull()
        .expiryDateLessThan(now)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();
  }

  /// Get batches expiring soon (within given days)
  Future<List<ProductBatchEntity>> getBatchesExpiringSoon({int withinDays = 30}) async {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: withinDays));
    return await _isar.productBatchEntitys
        .filter()
        .statusEqualTo(BatchStatus.active)
        .expiryDateIsNotNull()
        .expiryDateBetween(now, threshold)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();
  }

  // ==================== STOCK OPERATIONS ====================

  /// Reduce stock from a specific batch (used on sale)
  /// Returns the updated batch or null if not found/insufficient stock
  Future<ProductBatchEntity?> reduceStock(Id batchId, double quantity) async {
    final existing = await _isar.productBatchEntitys.get(batchId);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found for stock reduction: $batchId');
      return null;
    }

    if (existing.currentQuantity < quantity) {
      debugPrint('[BatchOffline] Insufficient stock in batch $batchId: '
          'available=${existing.currentQuantity}, requested=$quantity');
      return null;
    }

    final newQuantity = existing.currentQuantity - quantity;
    final newStatus = newQuantity <= 0 ? BatchStatus.exhausted : BatchStatus.active;

    // Determine new syncStatus
    BatchSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case BatchSyncStatus.newRecord:
        newSyncStatus = BatchSyncStatus.newRecord;
        break;
      case BatchSyncStatus.synced:
        newSyncStatus = BatchSyncStatus.updated;
        break;
      case BatchSyncStatus.updated:
        newSyncStatus = BatchSyncStatus.updated;
        break;
      case BatchSyncStatus.deleted:
        newSyncStatus = BatchSyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      currentQuantity: newQuantity,
      status: newStatus,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.put(updated);
    });

    debugPrint('[BatchOffline] Stock reduced in batch ${existing.batchNumber}: '
        '${existing.currentQuantity} - $quantity = $newQuantity (status: ${newStatus.name})');
    notifyListeners();
    return updated;
  }

  /// Increase stock in a specific batch (used for returns)
  /// Returns the updated batch or null if not found
  Future<ProductBatchEntity?> increaseStock(Id batchId, double quantity) async {
    final existing = await _isar.productBatchEntitys.get(batchId);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found for stock increase: $batchId');
      return null;
    }

    final newQuantity = existing.currentQuantity + quantity;
    final newStatus = newQuantity > 0 ? BatchStatus.active : existing.status;

    BatchSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case BatchSyncStatus.newRecord:
        newSyncStatus = BatchSyncStatus.newRecord;
        break;
      case BatchSyncStatus.synced:
        newSyncStatus = BatchSyncStatus.updated;
        break;
      case BatchSyncStatus.updated:
        newSyncStatus = BatchSyncStatus.updated;
        break;
      case BatchSyncStatus.deleted:
        newSyncStatus = BatchSyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      currentQuantity: newQuantity,
      status: newStatus,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.put(updated);
    });

    debugPrint('[BatchOffline] Stock increased in batch ${existing.batchNumber}: '
        '${existing.currentQuantity} + $quantity = $newQuantity');
    notifyListeners();
    return updated;
  }

  // ==================== AGGREGATION ====================

  /// Get total stock for a product across all active batches
  Future<double> getTotalStockForProduct(String productId) async {
    final batches = await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();

    return batches.fold<double>(0.0, (sum, batch) => sum + batch.currentQuantity);
  }

  /// Get weighted average purchase price for a product (across active batches)
  Future<double> getAveragePurchasePrice(String productId) async {
    final batches = await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();

    if (batches.isEmpty) return 0.0;

    double totalValue = 0.0;
    double totalQuantity = 0.0;
    for (final batch in batches) {
      totalValue += batch.currentQuantity * batch.purchasePrice;
      totalQuantity += batch.currentQuantity;
    }

    return totalQuantity > 0 ? totalValue / totalQuantity : 0.0;
  }

  /// Get total stock value for a product at purchase price
  Future<double> getTotalStockValue(String productId) async {
    final batches = await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();

    return batches.fold<double>(0.0, (sum, batch) => sum + batch.totalValue);
  }

  /// Get count of active batches for a product
  Future<int> getActiveBatchCount(String productId) async {
    return await _isar.productBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(BatchStatus.active)
        .currentQuantityGreaterThan(0)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .count();
  }

  // ==================== UPDATE ====================

  /// Update an existing batch
  /// If syncStatus was SYNCED, changes to UPDATED
  /// If syncStatus was NEW, keeps as NEW (not yet on server)
  Future<ProductBatchEntity?> updateBatch({
    required Id id,
    double? salesPrice,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    final existing = await _isar.productBatchEntitys.get(id);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found: $id');
      return null;
    }

    BatchSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case BatchSyncStatus.newRecord:
        newSyncStatus = BatchSyncStatus.newRecord;
        break;
      case BatchSyncStatus.synced:
        newSyncStatus = BatchSyncStatus.updated;
        break;
      case BatchSyncStatus.updated:
        newSyncStatus = BatchSyncStatus.updated;
        break;
      case BatchSyncStatus.deleted:
        newSyncStatus = BatchSyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      salesPrice: salesPrice,
      expiryDate: expiryDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.put(updated);
    });

    debugPrint('[BatchOffline] Batch updated: ${updated.id}, syncStatus: ${updated.syncStatus}');
    notifyListeners();
    return updated;
  }

  // ==================== DELETE ====================

  /// Soft delete a batch (mark for deletion, don't remove from DB)
  Future<void> deleteBatch(Id id) async {
    final existing = await _isar.productBatchEntitys.get(id);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found for delete: $id');
      return;
    }

    // If it's a NEW record (never synced), we can hard delete
    if (existing.syncStatus == BatchSyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.productBatchEntitys.delete(id);
      });
      debugPrint('[BatchOffline] Batch hard deleted (was never synced): $id');
    } else {
      // Mark for deletion - background sync will delete from server
      final deleted = existing.copyWith(
        syncStatus: BatchSyncStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() async {
        await _isar.productBatchEntitys.put(deleted);
      });
      debugPrint('[BatchOffline] Batch marked for deletion: $id');
    }

    notifyListeners();
  }

  /// Hard delete after successful server deletion
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.delete(id);
    });
    debugPrint('[BatchOffline] Batch permanently deleted: $id');
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all batches that need to be synced to server
  Future<List<ProductBatchEntity>> getBatchesNeedingSync() async {
    return await _isar.productBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.synced)
        .findAll();
  }

  /// Get count of unsynced batches
  Future<int> getUnsyncedCount() async {
    return await _isar.productBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.synced)
        .count();
  }

  /// Mark a batch as synced (after successful server sync)
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.productBatchEntitys.get(id);
    if (existing == null) return;

    final synced = existing.copyWith(
      serverId: serverId,
      syncStatus: BatchSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.put(synced);
    });

    debugPrint('[BatchOffline] Batch marked as synced: $id -> $serverId');
  }

  /// Import batches from server (initial load or refresh)
  /// Only updates if server data is newer
  Future<void> importFromServer(List<Map<String, dynamic>> serverBatches) async {
    await _isar.writeTxn(() async {
      for (final data in serverBatches) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        // Check if we already have this batch
        final existing = await _isar.productBatchEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing == null) {
          // New batch from server
          final batch = ProductBatchEntity.fromServer(data);
          await _isar.productBatchEntitys.put(batch);
        } else if (existing.syncStatus == BatchSyncStatus.synced) {
          // Only update if local is synced (no local changes)
          final updated = ProductBatchEntity.fromServer(data);
          updated.id = existing.id;
          await _isar.productBatchEntitys.put(updated);
        }
        // If local has changes (NEW, UPDATED, DELETED), don't overwrite
      }
    });

    debugPrint('[BatchOffline] Imported ${serverBatches.length} batches from server');
    notifyListeners();
  }

  // ==================== BATCH STATUS MANAGEMENT ====================

  /// Check and update expired batches
  /// Call this periodically or on app start
  Future<int> updateExpiredBatches() async {
    final now = DateTime.now();
    final expiredBatches = await _isar.productBatchEntitys
        .filter()
        .statusEqualTo(BatchStatus.active)
        .expiryDateIsNotNull()
        .expiryDateLessThan(now)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();

    if (expiredBatches.isEmpty) return 0;

    await _isar.writeTxn(() async {
      for (final batch in expiredBatches) {
        final updated = batch.copyWith(
          status: BatchStatus.expired,
          syncStatus: batch.syncStatus == BatchSyncStatus.synced
              ? BatchSyncStatus.updated
              : batch.syncStatus,
          updatedAt: now,
        );
        await _isar.productBatchEntitys.put(updated);
      }
    });

    debugPrint('[BatchOffline] Marked ${expiredBatches.length} batches as expired');
    notifyListeners();
    return expiredBatches.length;
  }

  // ==================== STATISTICS ====================

  /// Get total batch count (excluding deleted)
  Future<int> getTotalCount() async {
    return await _isar.productBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .count();
  }

  /// Get batches by date range
  Future<List<ProductBatchEntity>> getBatchesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _isar.productBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .purchaseDateBetween(startDate, endDate)
        .findAll();
  }

  /// Clear all local batches (use with caution)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.productBatchEntitys.clear();
    });
    debugPrint('[BatchOffline] All batches cleared');
    notifyListeners();
  }
}
