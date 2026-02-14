import 'package:flutter/foundation.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';
import '../../offline/controllers/stock_ledger_offline_controller.dart';
import '../../offline/entities/purchase_batch_entity.dart';
import '../../offline/entities/stock_ledger_entity.dart';

/// Result of a FIFO sale operation
class FifoSaleResult {
  final bool success;
  final String? errorMessage;
  final List<ConsumedBatchInfo> consumedBatches;
  final double totalCOGS;
  final double totalRevenue;
  final double totalProfit;
  
  FifoSaleResult({
    required this.success,
    this.errorMessage,
    this.consumedBatches = const [],
    this.totalCOGS = 0.0,
    this.totalRevenue = 0.0,
    this.totalProfit = 0.0,
  });
  
  factory FifoSaleResult.success({
    required List<ConsumedBatchInfo> consumedBatches,
    required double totalCOGS,
    required double totalRevenue,
    required double totalProfit,
  }) {
    return FifoSaleResult(
      success: true,
      consumedBatches: consumedBatches,
      totalCOGS: totalCOGS,
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
    );
  }
  
  factory FifoSaleResult.failure(String message) {
    return FifoSaleResult(success: false, errorMessage: message);
  }
}

/// Information about a consumed batch during sale
class ConsumedBatchInfo {
  final String batchId;
  final int localBatchId;
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final int quantityConsumed;
  final double costPrice;
  final double sellingPrice;
  final double totalCost;
  final double totalRevenue;
  final double profit;
  
  ConsumedBatchInfo({
    required this.batchId,
    required this.localBatchId,
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.quantityConsumed,
    required this.costPrice,
    required this.sellingPrice,
    required this.totalCost,
    required this.totalRevenue,
    required this.profit,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'localBatchId': localBatchId,
      'productId': productId,
      'productName': productName,
      'companyName': companyName,
      'modelName': modelName,
      'quantityConsumed': quantityConsumed,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'totalCost': totalCost,
      'totalRevenue': totalRevenue,
      'profit': profit,
    };
  }
}

/// Result of a purchase operation
class PurchaseResult {
  final bool success;
  final String? errorMessage;
  final PurchaseBatchEntity? batch;
  final StockLedgerEntity? ledgerEntry;
  
  PurchaseResult({
    required this.success,
    this.errorMessage,
    this.batch,
    this.ledgerEntry,
  });
  
  factory PurchaseResult.success({
    required PurchaseBatchEntity batch,
    required StockLedgerEntity ledgerEntry,
  }) {
    return PurchaseResult(
      success: true,
      batch: batch,
      ledgerEntry: ledgerEntry,
    );
  }
  
  factory PurchaseResult.failure(String message) {
    return PurchaseResult(success: false, errorMessage: message);
  }
}

/// Service for FIFO-based inventory management
/// Handles purchases, sales, and returns with proper batch tracking and COGS calculation
class FifoInventoryService {
  static FifoInventoryService? _instance;
  
  final PurchaseBatchOfflineController _batchController;
  final StockLedgerOfflineController _ledgerController;

  FifoInventoryService._({
    required PurchaseBatchOfflineController batchController,
    required StockLedgerOfflineController ledgerController,
  }) : _batchController = batchController,
       _ledgerController = ledgerController;

  /// Get the singleton instance
  static FifoInventoryService get instance {
    _instance ??= FifoInventoryService._(
      batchController: PurchaseBatchOfflineController.instance,
      ledgerController: StockLedgerOfflineController.instance,
    );
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== PURCHASE OPERATIONS ====================

  /// Process a purchase and create a new batch
  /// Each purchase creates a separate batch even for the same product
  Future<PurchaseResult> processPurchase({
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
    try {
      // Validate inputs
      if (quantity <= 0) {
        return PurchaseResult.failure('Quantity must be greater than 0');
      }
      if (purchasePrice < 0) {
        return PurchaseResult.failure('Purchase price cannot be negative');
      }
      if (sellingPrice < 0) {
        return PurchaseResult.failure('Selling price cannot be negative');
      }
      if (productName.trim().isEmpty) {
        return PurchaseResult.failure('Product name is required');
      }

      // Create new batch
      final batch = await _batchController.addBatch(
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
      );

      // Get current total stock for balance calculation
      final totalStock = await _batchController.getTotalStockByProductId(productId);
      final totalValue = await _batchController.getTotalStockValueByProductId(productId);

      // Create ledger entry for purchase
      final batchId = batch.serverId ?? 'local_${batch.id}';
      final ledgerEntry = await _ledgerController.recordPurchase(
        productId: productId,
        productName: productName,
        companyName: companyName,
        modelName: modelName,
        batchId: batchId,
        localBatchId: batch.id,
        purchaseReferenceId: 'PURCHASE_${DateTime.now().millisecondsSinceEpoch}',
        quantity: quantity,
        costPrice: purchasePrice,
        balanceQuantity: totalStock,
        balanceValue: totalValue,
        notes: notes,
      );

      debugPrint('[FifoService] Purchase processed: ${batch.productName}, qty: $quantity, batchId: ${batch.id}');
      
      return PurchaseResult.success(batch: batch, ledgerEntry: ledgerEntry);
    } catch (e) {
      debugPrint('[FifoService] Purchase failed: $e');
      return PurchaseResult.failure('Failed to process purchase: $e');
    }
  }

  // ==================== SALE OPERATIONS (FIFO) ====================

  /// Process a FIFO sale for a product
  /// Deducts from oldest batches first and creates ledger entries
  Future<FifoSaleResult> processFifoSale({
    required String productId,
    required int quantity,
    required double sellingPrice,
    required String billId,
    String? notes,
  }) async {
    try {
      // Validate inputs
      if (quantity <= 0) {
        return FifoSaleResult.failure('Quantity must be greater than 0');
      }

      // Get available batches sorted by purchase date (oldest first = FIFO)
      final availableBatches = await _batchController.getAvailableBatchesForProduct(productId);
      
      if (availableBatches.isEmpty) {
        return FifoSaleResult.failure('No stock available for this product');
      }

      // Calculate total available stock
      final totalAvailable = availableBatches.fold(0, (sum, b) => sum + b.quantityRemaining);
      
      if (totalAvailable < quantity) {
        return FifoSaleResult.failure(
          'Insufficient stock. Available: $totalAvailable, Requested: $quantity'
        );
      }

      // FIFO: Consume from oldest batches first
      int remainingToSell = quantity;
      final consumedBatches = <ConsumedBatchInfo>[];
      final ledgerEntries = <StockLedgerEntity>[];
      double totalCOGS = 0.0;
      double totalRevenue = 0.0;
      double totalProfit = 0.0;

      for (final batch in availableBatches) {
        if (remainingToSell <= 0) break;

        final qtyFromThisBatch = remainingToSell <= batch.quantityRemaining
            ? remainingToSell
            : batch.quantityRemaining;

        // Deduct from batch
        await _batchController.deductFromBatch(batch.id, qtyFromThisBatch);

        // Calculate costs and profit for this batch consumption
        final batchCost = batch.purchasePrice * qtyFromThisBatch;
        final batchRevenue = sellingPrice * qtyFromThisBatch;
        final batchProfit = batchRevenue - batchCost;

        totalCOGS += batchCost;
        totalRevenue += batchRevenue;
        totalProfit += batchProfit;

        // Get updated balance after deduction
        final newTotalStock = await _batchController.getTotalStockByProductId(productId);
        final newTotalValue = await _batchController.getTotalStockValueByProductId(productId);

        // Create ledger entry for this batch consumption
        final batchId = batch.serverId ?? 'local_${batch.id}';
        final ledgerEntry = await _ledgerController.recordSale(
          productId: productId,
          productName: batch.productName,
          companyName: batch.companyName,
          modelName: batch.modelName,
          batchId: batchId,
          localBatchId: batch.id,
          billId: billId,
          quantity: qtyFromThisBatch,
          costPrice: batch.purchasePrice,
          sellingPrice: sellingPrice,
          balanceQuantity: newTotalStock,
          balanceValue: newTotalValue,
          notes: notes,
        );

        ledgerEntries.add(ledgerEntry);

        // Track consumed batch info
        consumedBatches.add(ConsumedBatchInfo(
          batchId: batchId,
          localBatchId: batch.id,
          productId: productId,
          productName: batch.productName,
          companyName: batch.companyName,
          modelName: batch.modelName,
          quantityConsumed: qtyFromThisBatch,
          costPrice: batch.purchasePrice,
          sellingPrice: sellingPrice,
          totalCost: batchCost,
          totalRevenue: batchRevenue,
          profit: batchProfit,
        ));

        remainingToSell -= qtyFromThisBatch;
        
        debugPrint('[FifoService] Consumed $qtyFromThisBatch from batch ${batch.id} (${batch.productName}), cost: ${batch.purchasePrice}');
      }

      debugPrint('[FifoService] FIFO Sale completed: qty=$quantity, COGS=$totalCOGS, revenue=$totalRevenue, profit=$totalProfit');
      
      return FifoSaleResult.success(
        consumedBatches: consumedBatches,
        totalCOGS: totalCOGS,
        totalRevenue: totalRevenue,
        totalProfit: totalProfit,
      );
    } catch (e) {
      debugPrint('[FifoService] FIFO Sale failed: $e');
      return FifoSaleResult.failure('Failed to process sale: $e');
    }
  }

  /// Check if sufficient stock is available for a sale
  Future<bool> hasAvailableStock(String productId, int requiredQuantity) async {
    final totalStock = await _batchController.getTotalStockByProductId(productId);
    return totalStock >= requiredQuantity;
  }

  /// Get available stock for a product
  Future<int> getAvailableStock(String productId) async {
    return await _batchController.getTotalStockByProductId(productId);
  }

  /// Validate stock availability for multiple products
  /// Returns map of productId -> error message for products with insufficient stock
  Future<Map<String, String>> validateStockForSale(Map<String, int> productQuantities) async {
    final errors = <String, String>{};
    
    for (final entry in productQuantities.entries) {
      final productId = entry.key;
      final requiredQty = entry.value;
      
      final availableStock = await _batchController.getTotalStockByProductId(productId);
      
      if (availableStock < requiredQty) {
        errors[productId] = 'Insufficient stock. Available: $availableStock, Required: $requiredQty';
      }
    }
    
    return errors;
  }

  // ==================== RETURN OPERATIONS ====================

  /// Process a sale return
  /// Adds quantity back to the original batch (if specified) or creates adjustment
  Future<bool> processSaleReturn({
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
    required String returnReferenceId,
    String? notes,
  }) async {
    try {
      if (quantity <= 0) {
        throw Exception('Return quantity must be greater than 0');
      }

      // Try to add back to the original batch
      if (localBatchId != null) {
        await _batchController.addToBatch(localBatchId, quantity);
      }

      // Get updated balance
      final totalStock = await _batchController.getTotalStockByProductId(productId);
      final totalValue = await _batchController.getTotalStockValueByProductId(productId);

      // Create ledger entry for return
      await _ledgerController.recordSaleReturn(
        productId: productId,
        productName: productName,
        companyName: companyName,
        modelName: modelName,
        batchId: batchId,
        localBatchId: localBatchId,
        returnReferenceId: returnReferenceId,
        quantity: quantity,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        balanceQuantity: totalStock,
        balanceValue: totalValue,
        notes: notes,
      );

      debugPrint('[FifoService] Sale return processed: $productName, qty: $quantity');
      return true;
    } catch (e) {
      debugPrint('[FifoService] Sale return failed: $e');
      return false;
    }
  }

  // ==================== STOCK QUERIES ====================

  /// Get total stock for a product across all batches
  Future<int> getTotalStock(String productId) async {
    return await _batchController.getTotalStockByProductId(productId);
  }

  /// Get total stock value for a product
  Future<double> getTotalStockValue(String productId) async {
    return await _batchController.getTotalStockValueByProductId(productId);
  }

  /// Get weighted average cost for a product
  Future<double> getWeightedAverageCost(String productId) async {
    return await _batchController.getWeightedAverageCost(productId);
  }

  /// Get all batches for a product
  Future<List<PurchaseBatchEntity>> getBatchesForProduct(
    String productId, {
    bool onlyWithStock = true,
  }) async {
    return await _batchController.getBatchesByProductId(productId, onlyWithStock: onlyWithStock);
  }

  /// Get all products with their stock levels
  Future<Map<String, int>> getAllProductsWithStock() async {
    return await _batchController.getAllProductsWithStock();
  }

  // ==================== REPORTING ====================

  /// Get COGS for a date range
  Future<double> getTotalCOGS({DateTime? startDate, DateTime? endDate}) async {
    return await _ledgerController.getTotalCOGS(startDate: startDate, endDate: endDate);
  }

  /// Get profit for a date range
  Future<double> getTotalProfit({DateTime? startDate, DateTime? endDate}) async {
    return await _ledgerController.getTotalProfit(startDate: startDate, endDate: endDate);
  }

  /// Get revenue for a date range
  Future<double> getTotalRevenue({DateTime? startDate, DateTime? endDate}) async {
    return await _ledgerController.getTotalRevenue(startDate: startDate, endDate: endDate);
  }

  /// Get stock movement summary for a product
  Future<Map<String, dynamic>> getStockMovementSummary(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _ledgerController.getStockMovementSummary(
      productId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get batches expiring soon
  Future<List<PurchaseBatchEntity>> getBatchesExpiringSoon({int withinDays = 30}) async {
    return await _batchController.getBatchesExpiringSoon(withinDays: withinDays);
  }

  /// Get expired batches
  Future<List<PurchaseBatchEntity>> getExpiredBatches() async {
    return await _batchController.getExpiredBatches();
  }
}
