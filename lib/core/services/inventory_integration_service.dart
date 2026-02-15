import 'package:flutter/foundation.dart';
import '../../features/inventory_management/data/services/fifo_inventory_service.dart';
import '../../features/inventory_management/offline/controllers/purchase_offline_controller.dart';
import '../../features/inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import '../../features/inventory_management/offline/controllers/stock_ledger_offline_controller.dart';
import '../../features/inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../features/product/offline/controllers/product_offline_controller.dart';
import '../../features/billing/offline/controllers/bill_offline_controller.dart';
import '../../features/billing/offline/entities/bill_entity.dart';
import '../../features/billing/domain/entities/bill_item.dart';

/// Unified service that orchestrates the integration between:
/// - Old modules: Product, Supplier, Company, Purchase, Bill
/// - New FIFO system: PurchaseBatch, StockLedger, FifoInventoryService
///
/// This ensures all data stays in sync across the entire system.
/// UI pages should call this service instead of individual controllers directly.
class InventoryIntegrationService {
  static InventoryIntegrationService? _instance;

  final FifoInventoryService _fifoService;
  final PurchaseOfflineController _purchaseController;
  final PurchaseBatchOfflineController _batchController;
  // ignore: unused_field
  final StockLedgerOfflineController _ledgerController;
  final ProductOfflineController _productController;
  final BillOfflineController _billController;

  InventoryIntegrationService._({
    required FifoInventoryService fifoService,
    required PurchaseOfflineController purchaseController,
    required PurchaseBatchOfflineController batchController,
    required StockLedgerOfflineController ledgerController,
    required ProductOfflineController productController,
    required BillOfflineController billController,
  })  : _fifoService = fifoService,
        _purchaseController = purchaseController,
        _batchController = batchController,
        _ledgerController = ledgerController,
        _productController = productController,
        _billController = billController;

  /// Get the singleton instance
  static InventoryIntegrationService get instance {
    _instance ??= InventoryIntegrationService._(
      fifoService: FifoInventoryService.instance,
      purchaseController: PurchaseOfflineController.instance,
      batchController: PurchaseBatchOfflineController.instance,
      ledgerController: StockLedgerOfflineController.instance,
      productController: ProductOfflineController.instance,
      billController: BillOfflineController.instance,
    );
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== PURCHASE INTEGRATION ====================

  /// Process a complete purchase with all integrations:
  /// 1. Creates PurchaseEntity (old system record)
  /// 2. Creates PurchaseBatchEntity (FIFO tracking)
  /// 3. Creates StockLedgerEntity (audit trail)
  /// 4. Updates ProductEntity.currentStock
  /// 5. Updates ProductEntity prices
  ///
  /// Returns [IntegratedPurchaseResult] with all created entities
  Future<IntegratedPurchaseResult> processPurchase({
    required String productId,
    required String productName,
    String? supplierId,
    String? supplierName,
    String? companyId,
    String? companyName,
    String modelName = '',
    String category = '',
    required int quantity,
    String unit = 'pcs',
    required double purchasePrice,
    required double salesPrice,
    DateTime? productionDate,
    DateTime? expiryDate,
    int? warrantyMonths,
    String? notes,
  }) async {
    try {
      debugPrint('[Integration] Processing purchase: $productName, qty: $quantity');

      // 1. Create PurchaseEntity (old system - for sync, history, reporting)
      final purchaseEntity = await _purchaseController.addPurchase(
        productId: productId,
        productName: productName,
        supplierId: supplierId,
        supplierName: supplierName,
        companyId: companyId,
        companyName: companyName ?? '',
        quantity: quantity,
        unit: unit,
        purchasePrice: purchasePrice,
        salesPrice: salesPrice,
        productionDate: productionDate,
        expiryDate: expiryDate,
        warrantyMonths: warrantyMonths,
        notes: notes,
      );
      debugPrint('[Integration] PurchaseEntity created: ${purchaseEntity.id}');

      // 2. Create PurchaseBatch + StockLedger via FIFO service
      final fifoResult = await _fifoService.processPurchase(
        productId: productId,
        productName: productName,
        companyName: companyName ?? '',
        modelName: modelName,
        category: category,
        purchasePrice: purchasePrice,
        sellingPrice: salesPrice,
        quantity: quantity,
        purchaseDate: DateTime.now(),
        supplierId: supplierId,
        supplierName: supplierName,
        unit: unit,
        expiryDate: expiryDate,
        productionDate: productionDate,
        warrantyMonths: warrantyMonths,
        notes: notes,
      );

      if (!fifoResult.success) {
        debugPrint('[Integration] FIFO purchase failed: ${fifoResult.errorMessage}');
        return IntegratedPurchaseResult.failure(
          'FIFO processing failed: ${fifoResult.errorMessage}',
        );
      }
      debugPrint('[Integration] PurchaseBatch created: ${fifoResult.batch?.id}');

      // 3. Update ProductEntity stock and prices
      // Only update purchasePrice to latest cost; keep salesPrice from product creation
      // Try by serverId first, then by local ID
      final isValidServerId = productId.isNotEmpty &&
          !productId.startsWith('local_') &&
          productId.length >= 10;

      if (isValidServerId) {
        // Product has a server ID
        await _productController.incrementStock(productId, quantity);
        final entity = await _productController.getProductByServerId(productId);
        if (entity != null) {
          await _productController.updateProduct(
            id: entity.id,
            purchasePrice: purchasePrice,
            // Only update salesPrice if it was 0 (not yet set)
            salesPrice: entity.salesPrice == 0 ? salesPrice : null,
          );
        }
      } else {
        // Product has a local-only ID
        final localId = int.tryParse(productId);
        if (localId != null) {
          final entity = await _productController.getProductById(localId);
          if (entity != null) {
            final newStock = entity.currentStock + quantity;
            await _productController.updateProduct(
              id: entity.id,
              purchasePrice: purchasePrice,
              // Only update salesPrice if it was 0 (not yet set)
              salesPrice: entity.salesPrice == 0 ? salesPrice : null,
              currentStock: newStock,
            );
          }
        }
      }
      debugPrint('[Integration] ProductEntity stock updated');

      return IntegratedPurchaseResult.success(
        purchaseEntityId: purchaseEntity.id,
        batchEntity: fifoResult.batch!,
        ledgerEntity: fifoResult.ledgerEntry!,
      );
    } catch (e) {
      debugPrint('[Integration] Purchase failed: $e');
      return IntegratedPurchaseResult.failure('Failed to process purchase: $e');
    }
  }

  // ==================== BILLING / SALE INTEGRATION ====================

  /// Process a complete bill/sale with all integrations:
  /// 1. Creates BillEntity (bill record)
  /// 2. For each item: FIFO deduction from oldest batches
  /// 3. Creates StockLedger entries for each consumed batch
  /// 4. Updates ProductEntity.currentStock for each product
  ///
  /// Returns [IntegratedBillResult] with COGS and profit data
  Future<IntegratedBillResult> processBill({
    String? customerId,
    String? customerName,
    String? customerContact,
    required List<BillItem> items,
    required int totalQuantity,
    required double totalAmount,
    double discountAmount = 0.0,
    double discountPercent = 0.0,
    required double finalAmount,
    DateTime? billDate,
    String? notes,
    BillPaymentStatus paymentStatus = BillPaymentStatus.paid,
    double paidAmount = 0.0,
    double pendingAmount = 0.0,
    bool isGstApplied = false,
    bool isTaxInclusive = false,
    double cgstPercent = 0.0,
    double sgstPercent = 0.0,
    double otherTaxPercent = 0.0,
    String? otherTaxName,
    double cgstAmount = 0.0,
    double sgstAmount = 0.0,
    double otherTaxAmount = 0.0,
    double totalTaxAmount = 0.0,
  }) async {
    try {
      debugPrint('[Integration] Processing bill: ${items.length} items, total: $finalAmount');

      // 1. Create BillEntity
      final embeddedItems = items
          .map((item) => BillItemEmbedded(
                itemId: item.id.isNotEmpty
                    ? item.id
                    : 'item_${DateTime.now().millisecondsSinceEpoch}_${item.productId}',
                productId: item.productId,
                productName: item.productName,
                purchasePrice: item.purchasePrice,
                sellingPrice: item.sellingPrice,
                quantity: item.quantity,
                subtotal: item.subtotal,
                returnedQuantity: item.returnedQuantity,
              ))
          .toList();

      final billEntity = await _billController.addBill(
        customerId: customerId,
        customerName: customerName,
        customerContact: customerContact,
        items: embeddedItems,
        totalQuantity: totalQuantity,
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        discountPercent: discountPercent,
        finalAmount: finalAmount,
        billDate: billDate,
        notes: notes,
        paymentStatus: paymentStatus,
        paidAmount: paidAmount,
        pendingAmount: pendingAmount,
        isGstApplied: isGstApplied,
        isTaxInclusive: isTaxInclusive,
        cgstPercent: cgstPercent,
        sgstPercent: sgstPercent,
        otherTaxPercent: otherTaxPercent,
        otherTaxName: otherTaxName,
        cgstAmount: cgstAmount,
        sgstAmount: sgstAmount,
        otherTaxAmount: otherTaxAmount,
        totalTaxAmount: totalTaxAmount,
      );

      final billId = billEntity.serverId ?? 'local_${billEntity.id}';
      debugPrint('[Integration] BillEntity created: $billId');

      // 2. Process FIFO sales for each item
      final allConsumedBatches = <ConsumedBatchInfo>[];
      double totalCOGS = 0.0;
      double totalRevenue = 0.0;
      double totalProfit = 0.0;

      for (final item in items) {
        // 2a. FIFO deduction from batches + ledger entries
        final saleResult = await _fifoService.processFifoSale(
          productId: item.productId,
          quantity: item.quantity,
          sellingPrice: item.sellingPrice,
          billId: billId,
          notes: 'Bill: $billId',
        );

        if (!saleResult.success) {
          debugPrint(
              '[Integration] Warning: FIFO sale failed for ${item.productName}: ${saleResult.errorMessage}');
          // Continue even if FIFO fails - the bill is already created
          // The stock inconsistency can be resolved later
        } else {
          allConsumedBatches.addAll(saleResult.consumedBatches);
          totalCOGS += saleResult.totalCOGS;
          totalRevenue += saleResult.totalRevenue;
          totalProfit += saleResult.totalProfit;
        }

        // 2b. Update ProductEntity.currentStock
        await _decrementProductStock(item.productId, item.quantity);
      }

      debugPrint(
          '[Integration] Bill processed: COGS=$totalCOGS, Revenue=$totalRevenue, Profit=$totalProfit');

      return IntegratedBillResult.success(
        billEntity: billEntity,
        billId: billId,
        totalCOGS: totalCOGS,
        totalRevenue: totalRevenue,
        totalProfit: totalProfit,
        consumedBatches: allConsumedBatches,
      );
    } catch (e) {
      debugPrint('[Integration] Bill processing failed: $e');
      return IntegratedBillResult.failure('Failed to process bill: $e');
    }
  }

  // ==================== RETURN INTEGRATION ====================

  /// Process a sale return with all integrations:
  /// 1. Updates BillEntity with return info
  /// 2. Adds stock back to FIFO batches
  /// 3. Creates StockLedger entries for return
  /// 4. Increments ProductEntity.currentStock
  ///
  /// Returns true if successful
  Future<IntegratedReturnResult> processReturn({
    required String billId,
    required int billLocalId,
    required List<ReturnItemDetail> returnItems,
    String? notes,
  }) async {
    try {
      debugPrint('[Integration] Processing return for bill: $billId');

      double totalRefundAmount = 0.0;

      for (final returnItem in returnItems) {
        if (returnItem.returnQuantity <= 0) continue;

        // 1. Process FIFO return (add stock back to batch + create ledger entry)
        final returned = await _fifoService.processSaleReturn(
          productId: returnItem.productId,
          productName: returnItem.productName,
          companyName: returnItem.companyName,
          modelName: returnItem.modelName,
          batchId: returnItem.batchId,
          localBatchId: returnItem.localBatchId,
          quantity: returnItem.returnQuantity,
          costPrice: returnItem.costPrice,
          sellingPrice: returnItem.sellingPrice,
          returnReferenceId: 'RETURN_${billId}_${DateTime.now().millisecondsSinceEpoch}',
          notes: notes ?? 'Return for bill: $billId',
        );

        if (!returned) {
          debugPrint('[Integration] Warning: FIFO return failed for ${returnItem.productName}');
        }

        // 2. Increment ProductEntity.currentStock
        await _incrementProductStock(returnItem.productId, returnItem.returnQuantity);

        totalRefundAmount += returnItem.sellingPrice * returnItem.returnQuantity;
      }

      // 3. Update BillEntity with return info
      final bill = await _billController.getBillById(billLocalId);
      if (bill != null) {
        // Update return quantities on bill items
        final updatedItems = bill.items.map((item) {
          final returnItem = returnItems.firstWhere(
            (ri) => ri.productId == item.productId,
            orElse: () => ReturnItemDetail(
              productId: '',
              productName: '',
              returnQuantity: 0,
              costPrice: 0,
              sellingPrice: 0,
              batchId: '',
            ),
          );

          if (returnItem.productId.isNotEmpty) {
            return BillItemEmbedded(
              itemId: item.itemId,
              productId: item.productId,
              productName: item.productName,
              purchasePrice: item.purchasePrice,
              sellingPrice: item.sellingPrice,
              quantity: item.quantity,
              subtotal: item.subtotal,
              returnedQuantity: item.returnedQuantity + returnItem.returnQuantity,
            );
          }
          return item;
        }).toList();

        // Check if all items are fully returned
        final allReturned = updatedItems.every(
          (item) => item.returnedQuantity >= item.quantity,
        );

        await _billController.updateBill(
          id: billLocalId,
          items: updatedItems,
          returnStatus: allReturned,
          returnDate: DateTime.now(),
        );
      }

      debugPrint('[Integration] Return processed: refund=$totalRefundAmount');

      return IntegratedReturnResult.success(
        refundAmount: totalRefundAmount,
      );
    } catch (e) {
      debugPrint('[Integration] Return failed: $e');
      return IntegratedReturnResult.failure('Failed to process return: $e');
    }
  }

  // ==================== STOCK QUERY HELPERS ====================

  /// Get accurate stock for a product from FIFO batches
  /// This is the source of truth for stock levels
  Future<int> getAccurateStock(String productId) async {
    return await _fifoService.getAvailableStock(productId);
  }

  /// Validate stock availability for bill items using FIFO data
  Future<Map<String, String>> validateStockForBill(List<BillItem> items) async {
    return await _fifoService.validateStockForSale(
      {for (final item in items) item.productId: item.quantity},
    );
  }

  /// Check if a product has sufficient stock
  Future<bool> hasStock(String productId, int requiredQuantity) async {
    return await _fifoService.hasAvailableStock(productId, requiredQuantity);
  }

  /// Get all batches for a product (for viewing batch details)
  Future<List<PurchaseBatchEntity>> getProductBatches(
    String productId, {
    bool onlyWithStock = true,
  }) async {
    return await _batchController.getBatchesByProductId(
      productId,
      onlyWithStock: onlyWithStock,
    );
  }

  /// Get weighted average cost for a product
  Future<double> getWeightedAverageCost(String productId) async {
    return await _batchController.getWeightedAverageCost(productId);
  }

  // ==================== REPORTING HELPERS ====================

  /// Get profit summary for a date range
  Future<Map<String, dynamic>> getProfitSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final totalCOGS = await _fifoService.getTotalCOGS(
      startDate: startDate,
      endDate: endDate,
    );
    final totalRevenue = await _fifoService.getTotalRevenue(
      startDate: startDate,
      endDate: endDate,
    );
    final totalProfit = await _fifoService.getTotalProfit(
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'totalCOGS': totalCOGS,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'profitMargin':
          totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0.0,
    };
  }

  /// Get stock movement summary for a product
  Future<Map<String, dynamic>> getStockMovementSummary(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _fifoService.getStockMovementSummary(
      productId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Sync ProductEntity.currentStock with FIFO batch data
  /// Use this to fix any stock inconsistencies
  Future<int> syncAllProductStock() async {
    int fixedCount = 0;
    try {
      final allProducts = await _productController.getAllProducts();
      for (final product in allProducts) {
        final productId = product.serverId ?? product.id.toString();
        final fifoStock = await _fifoService.getAvailableStock(productId);

        if (product.currentStock != fifoStock) {
          debugPrint(
              '[Integration] Stock mismatch for ${product.name}: Product=${product.currentStock}, FIFO=$fifoStock. Fixing...');
          await _productController.updateProduct(
            id: product.id,
            currentStock: fifoStock,
          );
          fixedCount++;
        }
      }
      debugPrint('[Integration] Stock sync complete. Fixed: $fixedCount products');
    } catch (e) {
      debugPrint('[Integration] Stock sync failed: $e');
    }
    return fixedCount;
  }

  // ==================== PRIVATE HELPERS ====================

  /// Decrement product stock by server ID or local ID
  Future<void> _decrementProductStock(String productId, int quantity) async {
    final isValidServerId = productId.isNotEmpty &&
        !productId.startsWith('local_') &&
        productId.length >= 10;

    if (isValidServerId) {
      await _productController.decrementStock(productId, quantity);
    } else {
      final localId = int.tryParse(productId);
      if (localId != null) {
        final entity = await _productController.getProductById(localId);
        if (entity != null) {
          final newStock = (entity.currentStock - quantity).clamp(0, 999999999);
          await _productController.updateProduct(
            id: entity.id,
            currentStock: newStock,
          );
        }
      }
    }
  }

  /// Increment product stock by server ID or local ID
  Future<void> _incrementProductStock(String productId, int quantity) async {
    final isValidServerId = productId.isNotEmpty &&
        !productId.startsWith('local_') &&
        productId.length >= 10;

    if (isValidServerId) {
      await _productController.incrementStock(productId, quantity);
    } else {
      final localId = int.tryParse(productId);
      if (localId != null) {
        final entity = await _productController.getProductById(localId);
        if (entity != null) {
          final newStock = entity.currentStock + quantity;
          await _productController.updateProduct(
            id: entity.id,
            currentStock: newStock,
          );
        }
      }
    }
  }
}

// ==================== RESULT CLASSES ====================

/// Result of an integrated purchase operation
class IntegratedPurchaseResult {
  final bool success;
  final String? errorMessage;
  final int? purchaseEntityId;
  final PurchaseBatchEntity? batchEntity;
  final dynamic ledgerEntity;

  IntegratedPurchaseResult({
    required this.success,
    this.errorMessage,
    this.purchaseEntityId,
    this.batchEntity,
    this.ledgerEntity,
  });

  factory IntegratedPurchaseResult.success({
    required int purchaseEntityId,
    required PurchaseBatchEntity batchEntity,
    required dynamic ledgerEntity,
  }) {
    return IntegratedPurchaseResult(
      success: true,
      purchaseEntityId: purchaseEntityId,
      batchEntity: batchEntity,
      ledgerEntity: ledgerEntity,
    );
  }

  factory IntegratedPurchaseResult.failure(String message) {
    return IntegratedPurchaseResult(success: false, errorMessage: message);
  }
}

/// Result of an integrated bill/sale operation
class IntegratedBillResult {
  final bool success;
  final String? errorMessage;
  final BillEntity? billEntity;
  final String? billId;
  final double totalCOGS;
  final double totalRevenue;
  final double totalProfit;
  final List<ConsumedBatchInfo> consumedBatches;

  IntegratedBillResult({
    required this.success,
    this.errorMessage,
    this.billEntity,
    this.billId,
    this.totalCOGS = 0.0,
    this.totalRevenue = 0.0,
    this.totalProfit = 0.0,
    this.consumedBatches = const [],
  });

  factory IntegratedBillResult.success({
    required BillEntity billEntity,
    required String billId,
    required double totalCOGS,
    required double totalRevenue,
    required double totalProfit,
    required List<ConsumedBatchInfo> consumedBatches,
  }) {
    return IntegratedBillResult(
      success: true,
      billEntity: billEntity,
      billId: billId,
      totalCOGS: totalCOGS,
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      consumedBatches: consumedBatches,
    );
  }

  factory IntegratedBillResult.failure(String message) {
    return IntegratedBillResult(success: false, errorMessage: message);
  }
}

/// Result of an integrated return operation
class IntegratedReturnResult {
  final bool success;
  final String? errorMessage;
  final double refundAmount;

  IntegratedReturnResult({
    required this.success,
    this.errorMessage,
    this.refundAmount = 0.0,
  });

  factory IntegratedReturnResult.success({required double refundAmount}) {
    return IntegratedReturnResult(
      success: true,
      refundAmount: refundAmount,
    );
  }

  factory IntegratedReturnResult.failure(String message) {
    return IntegratedReturnResult(success: false, errorMessage: message);
  }
}

/// Detail for a return item
class ReturnItemDetail {
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final int returnQuantity;
  final double costPrice;
  final double sellingPrice;
  final String batchId;
  final int? localBatchId;

  ReturnItemDetail({
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.returnQuantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.batchId,
    this.localBatchId,
  });
}
