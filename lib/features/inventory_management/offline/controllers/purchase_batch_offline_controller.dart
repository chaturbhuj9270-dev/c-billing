import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/purchase_batch_entity.dart';

/// Offline-first controller for Purchase Batch CRUD operations
/// Implements FIFO inventory management
class PurchaseBatchOfflineController extends ChangeNotifier {
  static PurchaseBatchOfflineController? _instance;
  
  final Isar _isar;

  PurchaseBatchOfflineController._(this._isar);

  /// Get the singleton instance
  static PurchaseBatchOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = PurchaseBatchOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Add a new purchase batch
  /// Creates a new batch even if same product exists with different price
  Future<PurchaseBatchEntity> addBatch({
    required String productId,
    required String productName,
    required String companyName,
    String modelName = '',
    String category = '',
    required double purchasePrice,
    required double sellingPrice,
    required int quantity,
    DateTime? purchaseDate,
    String? supplierId,
    String? supplierName,
    String unit = 'pcs',
    DateTime? expiryDate,
    DateTime? productionDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    final batch = PurchaseBatchEntity.create(
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      category: category,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      purchaseDate: purchaseDate,
      supplierId: supplierId,
      supplierName: supplierName,
      unit: unit,
      expiryDate: expiryDate,
      productionDate: productionDate,
      warrantyMonths: warrantyMonths,
      notes: notes,
      syncStatus: BatchSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.purchaseBatchEntitys.put(batch);
    });

    debugPrint('[BatchOffline] Batch added: ${batch.id}, product: ${batch.productName}, qty: ${batch.quantityPurchased}, status: NEW');
    notifyListeners();
    return batch;
  }

  // ==================== READ ====================

  /// Get all batches (excluding deleted)
  Future<List<PurchaseBatchEntity>> getAllBatches({bool includeConsumed = false}) async {
    if (includeConsumed) {
      return await _isar.purchaseBatchEntitys
          .filter()
          .not()
          .syncStatusEqualTo(BatchSyncStatus.deleted)
          .sortByPurchaseDate()
          .findAll();
    }
    return await _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .isConsumedEqualTo(false)
        .sortByPurchaseDate()
        .findAll();
  }

  /// Watch all batches for real-time updates
  Stream<List<PurchaseBatchEntity>> watchAllBatches({bool includeConsumed = false}) {
    if (includeConsumed) {
      return _isar.purchaseBatchEntitys
          .filter()
          .not()
          .syncStatusEqualTo(BatchSyncStatus.deleted)
          .sortByPurchaseDate()
          .watch(fireImmediately: true);
    }
    return _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .isConsumedEqualTo(false)
        .sortByPurchaseDate()
        .watch(fireImmediately: true);
  }

  /// Get batch by local Isar ID
  Future<PurchaseBatchEntity?> getBatchById(Id id) async {
    return await _isar.purchaseBatchEntitys.get(id);
  }

  /// Get batch by server ID
  Future<PurchaseBatchEntity?> getBatchByServerId(String serverId) async {
    return await _isar.purchaseBatchEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get batches by product ID sorted by purchase date (oldest first for FIFO)
  Future<List<PurchaseBatchEntity>> getBatchesByProductId(
    String productId, {
    bool onlyWithStock = true,
  }) async {
    if (onlyWithStock) {
      return await _isar.purchaseBatchEntitys
          .filter()
          .productIdEqualTo(productId)
          .not()
          .syncStatusEqualTo(BatchSyncStatus.deleted)
          .quantityRemainingGreaterThan(0)
          .sortByPurchaseDate() // Oldest first for FIFO
          .findAll();
    }
    return await _isar.purchaseBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDate()
        .findAll();
  }

  /// Get batches by product unique key (name + company + model)
  /// Sorted by purchase date ASC for FIFO
  Future<List<PurchaseBatchEntity>> getBatchesByProductUniqueKey(
    String productUniqueKey, {
    bool onlyWithStock = true,
  }) async {
    if (onlyWithStock) {
      return await _isar.purchaseBatchEntitys
          .filter()
          .productUniqueKeyEqualTo(productUniqueKey)
          .not()
          .syncStatusEqualTo(BatchSyncStatus.deleted)
          .quantityRemainingGreaterThan(0)
          .sortByPurchaseDate() // Oldest first for FIFO
          .findAll();
    }
    return await _isar.purchaseBatchEntitys
        .filter()
        .productUniqueKeyEqualTo(productUniqueKey)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDate()
        .findAll();
  }

  /// Get available batches for FIFO consumption
  /// Returns batches with stock, sorted by purchase date (oldest first)
  Future<List<PurchaseBatchEntity>> getAvailableBatchesForProduct(String productId) async {
    return await _isar.purchaseBatchEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .quantityRemainingGreaterThan(0)
        .sortByPurchaseDate() // FIFO: oldest first
        .findAll();
  }

  /// Get batches by supplier
  Future<List<PurchaseBatchEntity>> getBatchesBySupplierId(String supplierId) async {
    return await _isar.purchaseBatchEntitys
        .filter()
        .supplierIdEqualTo(supplierId)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDateDesc()
        .findAll();
  }

  /// Get batches by date range
  Future<List<PurchaseBatchEntity>> getBatchesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _isar.purchaseBatchEntitys
        .filter()
        .purchaseDateBetween(startDate, endDate)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .sortByPurchaseDate()
        .findAll();
  }

  /// Get batches expiring soon
  Future<List<PurchaseBatchEntity>> getBatchesExpiringSoon({int withinDays = 30}) async {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: withinDays));
    
    return await _isar.purchaseBatchEntitys
        .filter()
        .expiryDateIsNotNull()
        .expiryDateBetween(now, deadline)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .quantityRemainingGreaterThan(0)
        .sortByExpiryDate()
        .findAll();
  }

  /// Get expired batches
  Future<List<PurchaseBatchEntity>> getExpiredBatches() async {
    final now = DateTime.now();
    
    return await _isar.purchaseBatchEntitys
        .filter()
        .expiryDateIsNotNull()
        .expiryDateLessThan(now)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .quantityRemainingGreaterThan(0)
        .sortByExpiryDate()
        .findAll();
  }

  // ==================== UPDATE ====================

  /// Update a batch
  Future<PurchaseBatchEntity?> updateBatch({
    required Id id,
    double? purchasePrice,
    double? sellingPrice,
    int? quantityRemaining,
    String? notes,
    DateTime? expiryDate,
    DateTime? productionDate,
    int? warrantyMonths,
    bool? isConsumed,
  }) async {
    final existing = await _isar.purchaseBatchEntitys.get(id);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found: $id');
      return null;
    }

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
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      quantityRemaining: quantityRemaining,
      notes: notes,
      expiryDate: expiryDate,
      productionDate: productionDate,
      warrantyMonths: warrantyMonths,
      isConsumed: isConsumed ?? (quantityRemaining != null && quantityRemaining <= 0),
      syncStatus: newSyncStatus,
    );

    await _isar.writeTxn(() async {
      await _isar.purchaseBatchEntitys.put(updated);
    });

    debugPrint('[BatchOffline] Batch updated: $id, remaining: ${updated.quantityRemaining}, status: ${updated.syncStatus}');
    notifyListeners();
    return updated;
  }

  /// Deduct quantity from batch (for FIFO sale)
  /// Returns updated batch
  Future<PurchaseBatchEntity?> deductFromBatch(Id id, int quantity) async {
    final existing = await _isar.purchaseBatchEntitys.get(id);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found for deduction: $id');
      return null;
    }

    if (existing.quantityRemaining < quantity) {
      throw Exception(
        'Insufficient stock in batch. Available: ${existing.quantityRemaining}, Requested: $quantity'
      );
    }

    final newRemaining = existing.quantityRemaining - quantity;
    
    return await updateBatch(
      id: id,
      quantityRemaining: newRemaining,
      isConsumed: newRemaining <= 0,
    );
  }

  /// Add quantity to batch (for returns)
  /// Returns updated batch
  Future<PurchaseBatchEntity?> addToBatch(Id id, int quantity) async {
    final existing = await _isar.purchaseBatchEntitys.get(id);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found for addition: $id');
      return null;
    }

    final newRemaining = existing.quantityRemaining + quantity;
    
    return await updateBatch(
      id: id,
      quantityRemaining: newRemaining,
      isConsumed: false, // No longer consumed if we're adding stock back
    );
  }

  /// Mark batch as consumed
  Future<void> markBatchAsConsumed(Id id) async {
    await updateBatch(id: id, quantityRemaining: 0, isConsumed: true);
  }

  // ==================== DELETE ====================

  /// Soft delete batch
  Future<bool> deleteBatch(Id id) async {
    final existing = await _isar.purchaseBatchEntitys.get(id);
    if (existing == null) return false;

    final updated = existing.copyWith(syncStatus: BatchSyncStatus.deleted);

    await _isar.writeTxn(() async {
      await _isar.purchaseBatchEntitys.put(updated);
    });

    debugPrint('[BatchOffline] Batch soft-deleted: $id');
    notifyListeners();
    return true;
  }

  /// Hard delete batch (for local cleanup after server deletion)
  Future<bool> hardDeleteBatch(Id id) async {
    final result = await _isar.writeTxn(() async {
      return await _isar.purchaseBatchEntitys.delete(id);
    });

    if (result) {
      debugPrint('[BatchOffline] Batch hard-deleted: $id');
      notifyListeners();
    }
    return result;
  }

  // ==================== QUERY / AGGREGATIONS ====================

  /// Get total available stock for a product
  Future<int> getTotalStockByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    return batches.fold<int>(0, (sum, batch) => sum + batch.quantityRemaining);
  }

  /// Get total available stock by product unique key
  Future<int> getTotalStockByProductUniqueKey(String productUniqueKey) async {
    final batches = await getBatchesByProductUniqueKey(productUniqueKey, onlyWithStock: true);
    return batches.fold<int>(0, (sum, batch) => sum + batch.quantityRemaining);
  }

  /// Get total stock value for a product
  Future<double> getTotalStockValueByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    return batches.fold<double>(0.0, (sum, batch) => sum + (batch.quantityRemaining * batch.purchasePrice));
  }

  /// Get weighted average cost for a product
  Future<double> getWeightedAverageCost(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    if (batches.isEmpty) return 0.0;
    
    final totalValue = batches.fold<double>(0.0, (sum, b) => sum + (b.quantityRemaining * b.purchasePrice));
    final totalQty = batches.fold<int>(0, (sum, b) => sum + b.quantityRemaining);
    
    return totalQty > 0 ? totalValue / totalQty : 0.0;
  }

  /// Get all unique products with their total stock
  Future<Map<String, int>> getAllProductsWithStock() async {
    final batches = await getAllBatches(includeConsumed: false);
    final stockMap = <String, int>{};
    
    for (final batch in batches) {
      final current = stockMap[batch.productId] ?? 0;
      stockMap[batch.productId] = current + batch.quantityRemaining;
    }
    
    return stockMap;
  }

  /// Get batch count for a product
  Future<int> getBatchCountByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: false);
    return batches.length;
  }

  // ==================== SYNC HELPERS ====================

  /// Get batches that need to be synced
  Future<List<PurchaseBatchEntity>> getBatchesNeedingSync() async {
    return await _isar.purchaseBatchEntitys
        .filter()
        .not()
        .syncStatusEqualTo(BatchSyncStatus.synced)
        .findAll();
  }

  /// Mark batch as synced
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.purchaseBatchEntitys.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId,
      syncStatus: BatchSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.purchaseBatchEntitys.put(updated);
    });
    
    debugPrint('[BatchOffline] Batch marked as synced: $id -> $serverId');
    notifyListeners();
  }

  /// Permanently delete batch from local DB (after server deletion)
  Future<bool> permanentlyDelete(Id id) async {
    final result = await _isar.writeTxn(() async {
      return await _isar.purchaseBatchEntitys.delete(id);
    });

    if (result) {
      debugPrint('[BatchOffline] Batch permanently deleted: $id');
      notifyListeners();
    }
    return result;
  }

  /// Import batches from server
  Future<void> importFromServer(List<Map<String, dynamic>> serverBatches) async {
    await _isar.writeTxn(() async {
      for (final data in serverBatches) {
        final entity = PurchaseBatchEntity.fromServer(data);
        
        // Check if batch already exists locally
        final existing = await _isar.purchaseBatchEntitys
            .filter()
            .serverIdEqualTo(entity.serverId)
            .findFirst();
        
        if (existing != null) {
          // Update existing if server version is newer
          if (entity.updatedAt.isAfter(existing.updatedAt)) {
            entity.id = existing.id;
            await _isar.purchaseBatchEntitys.put(entity);
          }
        } else {
          await _isar.purchaseBatchEntitys.put(entity);
        }
      }
    });
    
    debugPrint('[BatchOffline] Imported ${serverBatches.length} batches from server');
    notifyListeners();
  }

  /// Clear all local batches (for testing or logout)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.purchaseBatchEntitys.clear();
    });
    debugPrint('[BatchOffline] All batches cleared');
    notifyListeners();
  }
}
