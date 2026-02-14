import '../entities/purchase_batch.dart';

/// Repository interface for Purchase Batch operations (FIFO inventory)
abstract class PurchaseBatchRepository {
  // ==================== CREATE ====================
  
  /// Add a new purchase batch
  Future<String> addBatch(PurchaseBatch batch);

  // ==================== READ ====================
  
  /// Get batch by ID
  Future<PurchaseBatch?> getBatchById(String batchId);
  
  /// Get all batches (excluding consumed unless specified)
  Future<List<PurchaseBatch>> getAllBatches({bool includeConsumed = false});
  
  /// Get batches by product ID sorted by purchase date (oldest first for FIFO)
  Future<List<PurchaseBatch>> getBatchesByProductId(
    String productId, {
    bool onlyWithStock = true,
  });
  
  /// Get batches by product unique key (name + company + model)
  /// Sorted by purchase date ASC for FIFO
  Future<List<PurchaseBatch>> getBatchesByProductUniqueKey(
    String productUniqueKey, {
    bool onlyWithStock = true,
  });
  
  /// Get batches for a specific product that have available stock
  /// Sorted by purchase date ASC for FIFO consumption
  Future<List<PurchaseBatch>> getAvailableBatchesForProduct(String productId);
  
  /// Get batches by supplier ID
  Future<List<PurchaseBatch>> getBatchesBySupplierId(String supplierId);
  
  /// Get batches by date range
  Future<List<PurchaseBatch>> getBatchesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get batches expiring soon (within specified days)
  Future<List<PurchaseBatch>> getBatchesExpiringSoon({int withinDays = 30});
  
  /// Get expired batches
  Future<List<PurchaseBatch>> getExpiredBatches();

  // ==================== UPDATE ====================
  
  /// Update batch (general update)
  Future<void> updateBatch(PurchaseBatch batch);
  
  /// Deduct quantity from batch (for FIFO sale)
  /// Returns updated batch
  Future<PurchaseBatch> deductFromBatch(String batchId, int quantity);
  
  /// Add quantity to batch (for returns)
  /// Returns updated batch
  Future<PurchaseBatch> addToBatch(String batchId, int quantity);
  
  /// Mark batch as consumed
  Future<void> markBatchAsConsumed(String batchId);

  // ==================== DELETE ====================
  
  /// Delete batch
  Future<void> deleteBatch(String batchId);

  // ==================== QUERY / AGGREGATIONS ====================
  
  /// Get total available stock for a product (sum of all batches)
  Future<int> getTotalStockByProductId(String productId);
  
  /// Get total available stock by product unique key
  Future<int> getTotalStockByProductUniqueKey(String productUniqueKey);
  
  /// Get total stock value for a product (sum of remaining quantities * purchase prices)
  Future<double> getTotalStockValueByProductId(String productId);
  
  /// Get weighted average cost for a product
  Future<double> getWeightedAverageCost(String productId);
  
  /// Get all unique products with their total stock
  Future<Map<String, int>> getAllProductsWithStock();
  
  /// Get batch count for a product
  Future<int> getBatchCountByProductId(String productId);
}
