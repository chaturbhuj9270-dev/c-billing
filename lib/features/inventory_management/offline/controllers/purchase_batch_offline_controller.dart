import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../entities/purchase_batch_entity.dart';
import '../entities/purchase_entity.dart';
import 'purchase_offline_controller.dart';

// Offline-first controller for Purchase Batch CRUD operations Implements FIFO inventory management
class PurchaseBatchOfflineController extends ChangeNotifier {
  static PurchaseBatchOfflineController? _instance;

  final AppDatabase _db;

  PurchaseBatchOfflineController._(this._db);

  // Get the singleton instance
  static PurchaseBatchOfflineController get instance {
    _instance ??= PurchaseBatchOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  // Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  // Add a new purchase batch Creates a new batch even if same product exists with different price
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

    await _db.saveBatch(batch);

    debugPrint(
      '[BatchOffline] Batch added: ${batch.id}, product: ${batch.productName}, qty: ${batch.quantityPurchased}, status: NEW',
    );
    notifyListeners();
    return batch;
  }

  // ==================== READ ====================

  // Get all batches (excluding deleted)
  Future<List<PurchaseBatchEntity>> getAllBatches({
    bool includeConsumed = false,
  }) async {
    if (includeConsumed) {
      final batches = (await _db.loadBatches())
          .where((batch) => batch.syncStatus != BatchSyncStatus.deleted)
          .toList();
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
    final batches = (await _db.loadBatches()).where((batch) {
      return batch.syncStatus != BatchSyncStatus.deleted &&
          batch.isConsumed == false;
    }).toList();
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    return batches;
  }

  // Watch all batches for real-time updates
  Stream<List<PurchaseBatchEntity>> watchAllBatches({
    bool includeConsumed = false,
  }) {
    if (includeConsumed) {
      return _db.watchBatches().map((rows) {
        final batches = rows
            .where((batch) => batch.syncStatus != BatchSyncStatus.deleted)
            .toList();
        batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        return batches;
      });
    }
    return _db.watchBatches().map((rows) {
      final batches = rows.where((batch) {
        return batch.syncStatus != BatchSyncStatus.deleted &&
            batch.isConsumed == false;
      }).toList();
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    });
  }

  Future<PurchaseBatchEntity?> getBatchById(int id) async {
    for (final batch in await _db.loadBatches()) {
      if (batch.id == id) return batch;
    }
    return null;
  }

  // Get batch by server ID
  Future<PurchaseBatchEntity?> getBatchByServerId(String serverId) async {
    for (final batch in await _db.loadBatches()) {
      if (batch.serverId == serverId) return batch;
    }
    return null;
  }

  // Get batches by product ID sorted by purchase date (oldest first for FIFO)
  Future<List<PurchaseBatchEntity>> getBatchesByProductId(
    String productId, {
    bool onlyWithStock = true,
  }) async {
    if (onlyWithStock) {
      final batches = (await _db.loadBatches()).where((batch) {
        return batch.productId == productId &&
            batch.syncStatus != BatchSyncStatus.deleted &&
            batch.quantityRemaining > 0;
      }).toList();
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
    final batches = (await _db.loadBatches()).where((batch) {
      return batch.productId == productId &&
          batch.syncStatus != BatchSyncStatus.deleted;
    }).toList();
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    return batches;
  }

  // Get batches by product unique key (name + company + model) Sorted by purchase date ASC for FIFO
  Future<List<PurchaseBatchEntity>> getBatchesByProductUniqueKey(
    String productUniqueKey, {
    bool onlyWithStock = true,
  }) async {
    if (onlyWithStock) {
      final batches = (await _db.loadBatches()).where((batch) {
        return batch.productUniqueKey == productUniqueKey &&
            batch.syncStatus != BatchSyncStatus.deleted &&
            batch.quantityRemaining > 0;
      }).toList();
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
    final batches = (await _db.loadBatches()).where((batch) {
      return batch.productUniqueKey == productUniqueKey &&
          batch.syncStatus != BatchSyncStatus.deleted;
    }).toList();
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    return batches;
  }

  // Get available batches for FIFO consumption Returns batches with stock, sorted by purchase date (oldest first)
  Future<List<PurchaseBatchEntity>> getAvailableBatchesForProduct(
    String productId,
  ) async {
    final batches = (await _db.loadBatches()).where((batch) {
      return batch.productId == productId &&
          batch.syncStatus != BatchSyncStatus.deleted &&
          batch.quantityRemaining > 0;
    }).toList();
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    return batches;
  }

  // Get batches by supplier
  Future<List<PurchaseBatchEntity>> getBatchesBySupplierId(
    String supplierId,
  ) async {
    final batches = (await _db.loadBatches()).where((batch) {
      return batch.supplierId == supplierId &&
          batch.syncStatus != BatchSyncStatus.deleted;
    }).toList();
    batches.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return batches;
  }

  // Get batches by date range
  Future<List<PurchaseBatchEntity>> getBatchesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final batches = (await _db.loadBatches()).where((batch) {
      if (batch.syncStatus == BatchSyncStatus.deleted) return false;
      return !batch.purchaseDate.isBefore(startDate) &&
          !batch.purchaseDate.isAfter(endDate);
    }).toList();
    batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
    return batches;
  }

  // Get batches expiring soon
  Future<List<PurchaseBatchEntity>> getBatchesExpiringSoon({
    int withinDays = 30,
  }) async {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: withinDays));

    final batches = (await _db.loadBatches()).where((batch) {
      final expiryDate = batch.expiryDate;
      if (expiryDate == null) return false;
      if (batch.syncStatus == BatchSyncStatus.deleted) return false;
      if (batch.quantityRemaining <= 0) return false;
      return !expiryDate.isBefore(now) && !expiryDate.isAfter(deadline);
    }).toList();
    batches.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return batches;
  }

  // Get expired batches
  Future<List<PurchaseBatchEntity>> getExpiredBatches() async {
    final now = DateTime.now();

    final batches = (await _db.loadBatches()).where((batch) {
      final expiryDate = batch.expiryDate;
      if (expiryDate == null) return false;
      if (batch.syncStatus == BatchSyncStatus.deleted) return false;
      if (batch.quantityRemaining <= 0) return false;
      return expiryDate.isBefore(now);
    }).toList();
    batches.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return batches;
  }

  // ==================== UPDATE ====================

  // Update a batch
  Future<PurchaseBatchEntity?> updateBatch({
    required int id,
    double? purchasePrice,
    double? sellingPrice,
    int? quantityPurchased,
    int? quantityRemaining,
    String? supplierName,
    String? supplierId,
    String? unit,
    String? notes,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    DateTime? productionDate,
    int? warrantyMonths,
    bool? isConsumed,
  }) async {
    final existing = await getBatchById(id);
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
      quantityPurchased: quantityPurchased,
      quantityRemaining: quantityRemaining,
      supplierName: supplierName,
      supplierId: supplierId,
      unit: unit,
      notes: notes,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      productionDate: productionDate,
      warrantyMonths: warrantyMonths,
      isConsumed:
          isConsumed ?? (quantityRemaining != null && quantityRemaining <= 0),
      syncStatus: newSyncStatus,
    );

    await _db.saveBatch(updated);

    debugPrint(
      '[BatchOffline] Batch updated: $id, remaining: ${updated.quantityRemaining}, status: ${updated.syncStatus}',
    );
    notifyListeners();
    return updated;
  }

  // Deduct quantity from batch (for FIFO sale) Returns updated batch
  Future<PurchaseBatchEntity?> deductFromBatch(int id, int quantity) async {
    final existing = await getBatchById(id);
    if (existing == null) {
      debugPrint('[BatchOffline] Batch not found for deduction: $id');
      return null;
    }

    if (existing.quantityRemaining < quantity) {
      throw Exception(
        'Insufficient stock in batch. Available: ${existing.quantityRemaining}, Requested: $quantity',
      );
    }

    final newRemaining = existing.quantityRemaining - quantity;

    return await updateBatch(
      id: id,
      quantityRemaining: newRemaining,
      isConsumed: newRemaining <= 0,
    );
  }

  // Add quantity to batch (for returns) Returns updated batch
  Future<PurchaseBatchEntity?> addToBatch(int id, int quantity) async {
    final existing = await getBatchById(id);
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

  // Mark batch as consumed
  Future<void> markBatchAsConsumed(int id) async {
    await updateBatch(id: id, quantityRemaining: 0, isConsumed: true);
  }

  // ==================== DELETE ====================

  // Soft delete batch
  Future<bool> deleteBatch(int id) async {
    final existing = await getBatchById(id);
    if (existing == null) return false;

    final updated = existing.copyWith(syncStatus: BatchSyncStatus.deleted);

    await _db.saveBatch(updated);

    debugPrint('[BatchOffline] Batch soft-deleted: $id');
    notifyListeners();
    return true;
  }

  // Hard delete batch (for local cleanup after server deletion)
  Future<bool> hardDeleteBatch(int id) async {
    final result = await _db.deleteBatchById(id);

    if (result) {
      debugPrint('[BatchOffline] Batch hard-deleted: $id');
      notifyListeners();
    }
    return result;
  }

  // ==================== QUERY / AGGREGATIONS ====================

  // Get total available stock for a product
  Future<int> getTotalStockByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    return batches.fold<int>(
      0,
      (total, batch) => total + batch.quantityRemaining,
    );
  }

  // Get total available stock by product unique key
  Future<int> getTotalStockByProductUniqueKey(String productUniqueKey) async {
    final batches = await getBatchesByProductUniqueKey(
      productUniqueKey,
      onlyWithStock: true,
    );
    return batches.fold<int>(
      0,
      (total, batch) => total + batch.quantityRemaining,
    );
  }

  // Get total stock value for a product
  Future<double> getTotalStockValueByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    return batches.fold<double>(
      0.0,
      (total, batch) => total + (batch.quantityRemaining * batch.purchasePrice),
    );
  }

  // Get weighted average cost for a product
  Future<double> getWeightedAverageCost(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    if (batches.isEmpty) return 0.0;

    final totalValue = batches.fold<double>(
      0.0,
      (total, b) => total + (b.quantityRemaining * b.purchasePrice),
    );
    final totalQty = batches.fold<int>(
      0,
      (total, b) => total + b.quantityRemaining,
    );

    return totalQty > 0 ? totalValue / totalQty : 0.0;
  }

  // Get all unique products with their total stock
  Future<Map<String, int>> getAllProductsWithStock() async {
    final batches = await getAllBatches(includeConsumed: false);
    final stockMap = <String, int>{};

    for (final batch in batches) {
      final current = stockMap[batch.productId] ?? 0;
      stockMap[batch.productId] = current + batch.quantityRemaining;
    }

    return stockMap;
  }

  // Get batch count for a product
  Future<int> getBatchCountByProductId(String productId) async {
    final batches = await getBatchesByProductId(
      productId,
      onlyWithStock: false,
    );
    return batches.length;
  }

  // ==================== SYNC HELPERS ====================

  // Get batches that need to be synced
  Future<List<PurchaseBatchEntity>> getBatchesNeedingSync() async {
    return (await _db.loadBatches())
        .where((batch) => batch.syncStatus != BatchSyncStatus.synced)
        .toList();
  }

  // Mark batch as synced
  Future<void> markAsSynced(int id, String serverId) async {
    final existing = await getBatchById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId,
      syncStatus: BatchSyncStatus.synced,
    );

    await _db.saveBatch(updated);

    debugPrint('[BatchOffline] Batch marked as synced: $id -> $serverId');
    notifyListeners();
  }

  // Permanently delete batch from local DB (after server deletion)
  Future<bool> permanentlyDelete(int id) async {
    final result = await _db.deleteBatchById(id);

    if (result) {
      debugPrint('[BatchOffline] Batch permanently deleted: $id');
      notifyListeners();
    }
    return result;
  }

  // Import batches from server
  Future<void> importFromServer(
    List<Map<String, dynamic>> serverBatches,
  ) async {
    int imported = 0;
    int skipped = 0;
    int updated = 0;

    await _db.transaction(() async {
      for (final data in serverBatches) {
        final entity = PurchaseBatchEntity.fromServer(data);
        final all = await _db.loadBatches();

        // 1. Check if batch already exists by serverId
        PurchaseBatchEntity? existing;
        if (entity.serverId != null && entity.serverId!.isNotEmpty) {
          for (final batch in all) {
            if (batch.serverId == entity.serverId) {
              existing = batch;
              break;
            }
          }
        }

        // 2. If not found by serverId, check by business key to prevent duplicates (same product, same purchase date, same quantity, same price)
        existing ??= _firstBatchByBusinessKey(all, entity);

        if (existing != null) {
          // Update existing if server version is newer
          if (entity.updatedAt.isAfter(existing.updatedAt) ||
              existing.serverId == null) {
            entity.id = existing.id;
            // Preserve server ID from incoming data
            if (entity.serverId != null && entity.serverId!.isNotEmpty) {
              existing.serverId = entity.serverId;
            }
            await _db.saveBatch(entity);
            updated++;
          } else {
            // Just update the serverId if missing locally
            if (existing.serverId == null && entity.serverId != null) {
              existing.serverId = entity.serverId;
              existing.syncStatus = BatchSyncStatus.synced;
              await _db.saveBatch(existing);
              updated++;
            } else {
              skipped++;
            }
          }
        } else {
          await _db.saveBatch(entity);
          imported++;
        }
      }
    });

    debugPrint(
      '[BatchOffline] Import complete: $imported new, $updated updated, $skipped skipped (total ${serverBatches.length})',
    );
    notifyListeners();
  }

  // purchaseDateEqualTo OR purchaseDateBetween(target ± 2 seconds), both inclusive.
  PurchaseBatchEntity? _firstBatchByBusinessKey(
    List<PurchaseBatchEntity> batches,
    PurchaseBatchEntity entity,
  ) {
    final start = entity.purchaseDate.subtract(const Duration(seconds: 2));
    final end = entity.purchaseDate.add(const Duration(seconds: 2));
    for (final batch in batches) {
      if (batch.productId != entity.productId) continue;
      if (batch.quantityPurchased != entity.quantityPurchased) continue;
      if (batch.purchasePrice != entity.purchasePrice) continue;
      final sameInstant = batch.purchaseDate == entity.purchaseDate;
      final inWindow =
          !batch.purchaseDate.isBefore(start) &&
          !batch.purchaseDate.isAfter(end);
      if (sameInstant || inWindow) return batch;
    }
    return null;
  }

  // Remove duplicate batches from local database Keeps the one with serverId (synced) or the newest one
  Future<int> deduplicateBatches() async {
    int removedCount = 0;

    await _db.transaction(() async {
      final allBatches = await _db.loadBatches();

      // Group batches by business key: productId + purchasePrice + quantityPurchased + purchaseDate (rounded to minute)
      final Map<String, List<PurchaseBatchEntity>> groups = {};

      for (final batch in allBatches) {
        // Round purchase date to nearest minute to group near-identical timestamps
        final roundedDate = DateTime(
          batch.purchaseDate.year,
          batch.purchaseDate.month,
          batch.purchaseDate.day,
          batch.purchaseDate.hour,
          batch.purchaseDate.minute,
        );
        final key =
            '${batch.productId}_${batch.purchasePrice}_${batch.quantityPurchased}_${roundedDate.toIso8601String()}';

        groups.putIfAbsent(key, () => []);
        groups[key]!.add(batch);
      }

      // For each group with more than one batch, keep the best one and remove others
      for (final entry in groups.entries) {
        if (entry.value.length <= 1) continue;

        // Sort: prefer synced (with serverId), then newest updatedAt
        entry.value.sort((a, b) {
          // Prefer one with serverId
          if (a.serverId != null && b.serverId == null) return -1;
          if (a.serverId == null && b.serverId != null) return 1;
          // Then prefer newest
          return b.updatedAt.compareTo(a.updatedAt);
        });

        // Keep first (best), remove rest
        for (int i = 1; i < entry.value.length; i++) {
          await _db.deleteBatchById(entry.value[i].id);
          removedCount++;
        }
      }
    });

    if (removedCount > 0) {
      debugPrint(
        '[BatchOffline] Deduplication removed $removedCount duplicate batches',
      );
      notifyListeners();
    }

    return removedCount;
  }

  // ==================== LEGACY MIGRATION ====================

  static const _legacyMigrationNotePrefix = '[legacy-purchase:';
  static const _openingStockNote = '[opening-stock]';

  // Build purchase history from legacy PurchaseEntity records and opening stock. The purchase list UI reads PurchaseBatchEntity only; older data lives in PurchaseEntity (Firestore `...
  Future<int> ensurePurchaseHistoryAvailable() async {
    var batches = await getAllBatches(includeConsumed: true);
    if (batches.isNotEmpty) return batches.length;

    final migrated = await migrateLegacyPurchasesToBatches();
    debugPrint('[BatchOffline] Legacy migration created $migrated batches');

    batches = await getAllBatches(includeConsumed: true);
    if (batches.isNotEmpty) return batches.length;

    final backfilled = await backfillOpeningStockBatches();
    debugPrint(
      '[BatchOffline] Opening stock backfill created $backfilled batches',
    );

    return (await getAllBatches(includeConsumed: true)).length;
  }

  // Convert legacy PurchaseEntity records into PurchaseBatchEntity records.
  Future<int> migrateLegacyPurchasesToBatches() async {
    final purchases = await PurchaseOfflineController.instance
        .getAllPurchases();
    if (purchases.isEmpty) return 0;

    int migrated = 0;

    await _db.transaction(() async {
      for (final purchase in purchases) {
        if (await _hasLegacyBatchForPurchase(purchase)) continue;

        final batch = PurchaseBatchEntity.create(
          serverId: purchase.serverId,
          productId: purchase.productId,
          productName: purchase.productName,
          companyName: purchase.companyName ?? '',
          purchasePrice: purchase.purchasePrice,
          sellingPrice: purchase.salesPrice,
          quantity: purchase.quantity,
          purchaseDate: purchase.createdAt,
          supplierId: purchase.supplierId,
          supplierName: purchase.supplierName,
          unit: purchase.unit,
          expiryDate: purchase.expiryDate,
          productionDate: purchase.productionDate,
          warrantyMonths: purchase.warrantyMonths,
          notes: purchase.notes != null && purchase.notes!.isNotEmpty
              ? '${purchase.notes}\n$_legacyMigrationNotePrefix${purchase.serverId ?? purchase.id}]'
              : '$_legacyMigrationNotePrefix${purchase.serverId ?? purchase.id}]',
          syncStatus: purchase.serverId != null
              ? BatchSyncStatus.synced
              : BatchSyncStatus.newRecord,
        );
        batch.createdAt = purchase.createdAt;
        batch.updatedAt = purchase.updatedAt;

        await _db.saveBatch(batch);
        migrated++;
      }
    });

    if (migrated > 0) {
      await _reconcileBatchStockWithProducts();
      notifyListeners();
    }

    return migrated;
  }

  // Create batch records for products that have stock but no purchase history.
  Future<int> backfillOpeningStockBatches() async {
    final products = await ProductOfflineController.instance.getAllProducts();
    int created = 0;

    await _db.transaction(() async {
      for (final product in products) {
        if (product.currentStock <= 0) continue;
        if (await _productHasAnyBatch(product)) continue;

        final productId = _productIdForBatch(product);
        final batch = PurchaseBatchEntity.create(
          productId: productId,
          productName: product.name,
          companyName: product.companyName,
          category: product.category,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.salesPrice,
          quantity: product.currentStock,
          purchaseDate: product.createdAt,
          supplierId: product.defaultSupplierId,
          supplierName: product.defaultSupplierName,
          notes: _openingStockNote,
          syncStatus: BatchSyncStatus.synced,
        );
        batch.createdAt = product.createdAt;
        batch.updatedAt = product.updatedAt;

        await _db.saveBatch(batch);
        created++;
      }
    });

    if (created > 0) {
      notifyListeners();
    }

    return created;
  }

  Future<bool> _hasLegacyBatchForPurchase(PurchaseEntity purchase) async {
    final migrationTag =
        '$_legacyMigrationNotePrefix${purchase.serverId ?? purchase.id}]';

    final batches = await _db.loadBatches();
    for (final batch in batches) {
      if (batch.notes?.contains(migrationTag) == true) return true;
    }

    final start = purchase.createdAt.subtract(const Duration(seconds: 2));
    final end = purchase.createdAt.add(const Duration(seconds: 2));
    for (final batch in batches) {
      if (batch.productId == purchase.productId &&
          batch.quantityPurchased == purchase.quantity &&
          batch.purchasePrice == purchase.purchasePrice &&
          !batch.purchaseDate.isBefore(start) &&
          !batch.purchaseDate.isAfter(end)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _productHasAnyBatch(ProductEntity product) async {
    final batches = await _db.loadBatches();
    for (final productId in _productIdsForLookup(product)) {
      final count = batches
          .where(
            (batch) =>
                batch.productId == productId &&
                batch.syncStatus != BatchSyncStatus.deleted,
          )
          .length;
      if (count > 0) return true;
    }
    return false;
  }

  String _productIdForBatch(ProductEntity product) {
    return product.serverId ?? product.id.toString();
  }

  Set<String> _productIdsForLookup(ProductEntity product) {
    return {
      product.id.toString(),
      if (product.serverId != null && product.serverId!.isNotEmpty)
        product.serverId!,
    };
  }

  // Align batch remaining quantities with product.currentStock using FIFO.
  Future<void> _reconcileBatchStockWithProducts() async {
    final products = await ProductOfflineController.instance.getAllProducts();

    await _db.transaction(() async {
      for (final product in products) {
        final batches = <PurchaseBatchEntity>[];
        final all = await _db.loadBatches();
        for (final productId in _productIdsForLookup(product)) {
          batches.addAll(
            all.where(
              (batch) =>
                  batch.productId == productId &&
                  batch.syncStatus != BatchSyncStatus.deleted,
            ),
          );
        }

        if (batches.isEmpty) continue;

        batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

        final uniqueBatches = <int, PurchaseBatchEntity>{};
        for (final batch in batches) {
          uniqueBatches[batch.id] = batch;
        }
        final orderedBatches = uniqueBatches.values.toList()
          ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

        var totalRemaining = orderedBatches.fold<int>(
          0,
          (total, batch) => total + batch.quantityRemaining,
        );
        final targetStock = math.max(0, product.currentStock);

        if (totalRemaining > targetStock) {
          var excess = totalRemaining - targetStock;
          for (final batch in orderedBatches.reversed) {
            if (excess <= 0) break;
            final reduce = math.min(excess, batch.quantityRemaining);
            batch.quantityRemaining -= reduce;
            batch.isConsumed = batch.quantityRemaining <= 0;
            batch.updatedAt = DateTime.now();
            excess -= reduce;
            await _db.saveBatch(batch);
          }
        } else if (totalRemaining < targetStock && orderedBatches.isNotEmpty) {
          final newest = orderedBatches.last;
          newest.quantityRemaining += targetStock - totalRemaining;
          newest.isConsumed = false;
          newest.updatedAt = DateTime.now();
          await _db.saveBatch(newest);
        }
      }
    });
  }

  // Clear all local batches (for testing or logout)
  Future<void> clearAll() async {
    await _db.clearBatches();
    debugPrint('[BatchOffline] All batches cleared');
    notifyListeners();
  }
}
