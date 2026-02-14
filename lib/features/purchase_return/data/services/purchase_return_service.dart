import 'package:flutter/foundation.dart';
import '../../../inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import '../../../inventory_management/offline/controllers/stock_ledger_offline_controller.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../../inventory_management/offline/entities/stock_ledger_entity.dart';
import '../../domain/entities/purchase_return.dart';
import '../repositories/firebase_purchase_return_repository.dart';

/// Result of validating a return item
class ReturnValidation {
  final bool isValid;
  final String? errorMessage;
  ReturnValidation.valid() : isValid = true, errorMessage = null;
  ReturnValidation.invalid(this.errorMessage) : isValid = false;
}

/// Batch info for display in the UI
class ReturnableBatchInfo {
  final int localBatchId;
  final String batchId;
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final double purchasePrice;
  final double sellingPrice;
  final int quantityRemaining;
  final DateTime purchaseDate;
  final String? supplierName;
  final String? supplierId;

  ReturnableBatchInfo({
    required this.localBatchId,
    required this.batchId,
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantityRemaining,
    required this.purchaseDate,
    this.supplierName,
    this.supplierId,
  });
}

/// Result of processing a purchase return
class PurchaseReturnResult {
  final bool success;
  final String? errorMessage;
  final PurchaseReturn? purchaseReturn;

  PurchaseReturnResult.success(this.purchaseReturn)
      : success = true,
        errorMessage = null;
  PurchaseReturnResult.failure(this.errorMessage)
      : success = false,
        purchaseReturn = null;
}

/// Impact preview before confirming a return
class ReturnImpactPreview {
  final Map<String, int> stockAfterReturn; // productId -> new stock
  final double supplierCreditAdjustment;
  final double inventoryValueChange;

  ReturnImpactPreview({
    required this.stockAfterReturn,
    required this.supplierCreditAdjustment,
    required this.inventoryValueChange,
  });
}

/// Service for processing purchase returns with reverse-FIFO logic.
///
/// Reverse FIFO = deduct from the NEWEST batches first (latest purchase date).
/// This ensures older stock remains for sales while returning recently acquired stock.
class PurchaseReturnService {
  static PurchaseReturnService? _instance;

  final PurchaseBatchOfflineController _batchController;
  final StockLedgerOfflineController _ledgerController;
  final FirebasePurchaseReturnRepository _repository;

  PurchaseReturnService._({
    required PurchaseBatchOfflineController batchController,
    required StockLedgerOfflineController ledgerController,
    required FirebasePurchaseReturnRepository repository,
  })  : _batchController = batchController,
        _ledgerController = ledgerController,
        _repository = repository;

  static PurchaseReturnService get instance {
    _instance ??= PurchaseReturnService._(
      batchController: PurchaseBatchOfflineController.instance,
      ledgerController: StockLedgerOfflineController.instance,
      repository: FirebasePurchaseReturnRepository(),
    );
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ──────────────── QUERIES ────────────────

  /// Get all products with stock for a specific supplier.
  /// Groups batches by productId and sums remaining quantities.
  Future<List<ReturnableBatchInfo>> getReturnableProductsForSupplier(
      String supplierId) async {
    final batches =
        await _batchController.getBatchesBySupplierId(supplierId);
    final withStock =
        batches.where((b) => b.quantityRemaining > 0).toList();

    // Group by productId → aggregate
    final grouped = <String, List<PurchaseBatchEntity>>{};
    for (final b in withStock) {
      grouped.putIfAbsent(b.productId, () => []).add(b);
    }

    return grouped.entries.map((e) {
      final productBatches = e.value;
      final first = productBatches.first;
      final totalRemaining =
          productBatches.fold(0, (s, b) => s + b.quantityRemaining);
      return ReturnableBatchInfo(
        localBatchId: first.id,
        batchId: first.serverId ?? 'local_${first.id}',
        productId: first.productId,
        productName: first.productName,
        companyName: first.companyName,
        modelName: first.modelName,
        purchasePrice: first.purchasePrice,
        sellingPrice: first.sellingPrice,
        quantityRemaining: totalRemaining,
        purchaseDate: first.purchaseDate,
        supplierName: first.supplierName,
        supplierId: first.supplierId,
      );
    }).toList()
      ..sort((a, b) => b.quantityRemaining.compareTo(a.quantityRemaining));
  }

  /// Get individual batch breakdown for a product from a supplier.
  /// Sorted newest first (reverse FIFO).
  Future<List<ReturnableBatchInfo>> getBatchBreakdownForProduct(
      String productId, String supplierId) async {
    final batches =
        await _batchController.getBatchesBySupplierId(supplierId);
    final forProduct = batches
        .where((b) =>
            b.productId == productId && b.quantityRemaining > 0)
        .toList();

    // Sort newest first (reverse FIFO for returns)
    forProduct.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return forProduct
        .map((b) => ReturnableBatchInfo(
              localBatchId: b.id,
              batchId: b.serverId ?? 'local_${b.id}',
              productId: b.productId,
              productName: b.productName,
              companyName: b.companyName,
              modelName: b.modelName,
              purchasePrice: b.purchasePrice,
              sellingPrice: b.sellingPrice,
              quantityRemaining: b.quantityRemaining,
              purchaseDate: b.purchaseDate,
              supplierName: b.supplierName,
              supplierId: b.supplierId,
            ))
        .toList();
  }

  /// Get all return history
  Future<List<PurchaseReturn>> getReturnHistory() async {
    return await _repository.getAllReturns();
  }

  /// Get return history for a supplier
  Future<List<PurchaseReturn>> getReturnHistoryForSupplier(
      String supplierId) async {
    return await _repository.getReturnsBySupplierId(supplierId);
  }

  // ──────────────── VALIDATION ────────────────

  /// Validate a return item quantity against available stock
  ReturnValidation validateReturnQuantity({
    required int returnQty,
    required int availableQty,
  }) {
    if (returnQty <= 0) {
      return ReturnValidation.invalid('Return quantity must be > 0');
    }
    if (returnQty > availableQty) {
      return ReturnValidation.invalid(
          'Return qty ($returnQty) exceeds available ($availableQty)');
    }
    return ReturnValidation.valid();
  }

  /// Validate the entire return before processing
  ReturnValidation validateReturn({
    required String supplierId,
    required List<PurchaseReturnItem> items,
  }) {
    if (supplierId.isEmpty) {
      return ReturnValidation.invalid('Supplier is required');
    }
    if (items.isEmpty) {
      return ReturnValidation.invalid('At least one item is required');
    }
    final hasQuantity = items.any((i) => i.quantity > 0);
    if (!hasQuantity) {
      return ReturnValidation.invalid(
          'At least one product must have return qty > 0');
    }
    return ReturnValidation.valid();
  }

  // ──────────────── IMPACT PREVIEW ────────────────

  /// Preview the impact of a return before processing
  Future<ReturnImpactPreview> previewReturnImpact(
      List<PurchaseReturnItem> items) async {
    final stockAfter = <String, int>{};
    double creditAdj = 0.0;
    double valueChange = 0.0;

    for (final item in items) {
      if (item.quantity <= 0) continue;
      final currentStock =
          await _batchController.getTotalStockByProductId(item.productId);
      stockAfter[item.productId] = currentStock - item.quantity;
      creditAdj += item.amount;
      valueChange -= item.amount;
    }

    return ReturnImpactPreview(
      stockAfterReturn: stockAfter,
      supplierCreditAdjustment: creditAdj,
      inventoryValueChange: valueChange,
    );
  }

  // ──────────────── PROCESS RETURN (Reverse FIFO) ────────────────

  /// Process a purchase return.
  ///
  /// For each item:
  ///  1. Get batches for the product from that supplier (newest first)
  ///  2. Deduct from newest batches first (reverse FIFO)
  ///  3. Create PURCHASE_RETURN ledger entries
  ///  4. Save PurchaseReturn document to Firebase
  Future<PurchaseReturnResult> processReturn({
    required String supplierId,
    required String supplierName,
    required DateTime returnDate,
    required String reason,
    required List<PurchaseReturnItem> items,
  }) async {
    try {
      // Validate
      final validation =
          validateReturn(supplierId: supplierId, items: items);
      if (!validation.isValid) {
        return PurchaseReturnResult.failure(validation.errorMessage!);
      }

      final processedItems = <PurchaseReturnItem>[];
      double totalReturnAmount = 0.0;
      final returnRefId =
          'PRET_${DateTime.now().millisecondsSinceEpoch}';

      for (final item in items) {
        if (item.quantity <= 0) continue;

        // Get batches for this product from this supplier, newest first
        final batches = await _batchController
            .getBatchesBySupplierId(supplierId);
        final productBatches = batches
            .where((b) =>
                b.productId == item.productId &&
                b.quantityRemaining > 0)
            .toList();

        // Sort NEWEST first (reverse FIFO)
        productBatches
            .sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

        int remainingToReturn = item.quantity;

        // Check total available
        final totalAvailable =
            productBatches.fold(0, (s, b) => s + b.quantityRemaining);
        if (totalAvailable < item.quantity) {
          return PurchaseReturnResult.failure(
            'Insufficient stock for ${item.productName}. '
            'Available: $totalAvailable, Requested: ${item.quantity}',
          );
        }

        // Deduct from newest batches
        for (final batch in productBatches) {
          if (remainingToReturn <= 0) break;

          final qtyFromBatch = remainingToReturn <= batch.quantityRemaining
              ? remainingToReturn
              : batch.quantityRemaining;

          // Deduct from batch
          await _batchController.deductFromBatch(batch.id, qtyFromBatch);

          // Get updated balance
          final newTotalStock = await _batchController
              .getTotalStockByProductId(item.productId);
          final newTotalValue = await _batchController
              .getTotalStockValueByProductId(item.productId);

          // Create ledger entry
          final batchIdStr = batch.serverId ?? 'local_${batch.id}';
          await _ledgerController.recordMultipleEntries([
            StockLedgerEntity(
              productId: item.productId,
              productName: batch.productName,
              companyName: batch.companyName,
              modelName: batch.modelName,
              productUniqueKey:
                  '${batch.productName.toLowerCase().trim()}_${batch.companyName.toLowerCase().trim()}_${batch.modelName.toLowerCase().trim()}',
              batchId: batchIdStr,
              localBatchId: batch.id,
              ledgerType: LedgerTransactionType.PURCHASE_RETURN,
              referenceId: returnRefId,
              referenceType: 'PURCHASE_RETURN',
              quantity: qtyFromBatch,
              costPrice: batch.purchasePrice,
              sellingPrice: 0.0,
              totalCost: batch.purchasePrice * qtyFromBatch,
              totalRevenue: 0.0,
              profit: 0.0,
              balanceQuantity: newTotalStock,
              balanceValue: newTotalValue,
              transactionDate: returnDate,
              notes: reason.isNotEmpty ? reason : null,
              syncStatus: LedgerSyncStatus.newRecord,
              createdAt: DateTime.now(),
            ),
          ]);

          final returnItemAmount = batch.purchasePrice * qtyFromBatch;
          totalReturnAmount += returnItemAmount;

          processedItems.add(PurchaseReturnItem(
            id: '${returnRefId}_${batch.id}',
            purchaseReturnId: returnRefId,
            productId: item.productId,
            productName: batch.productName,
            companyName: batch.companyName,
            modelName: batch.modelName,
            batchId: batchIdStr,
            localBatchId: batch.id,
            quantity: qtyFromBatch,
            rate: batch.purchasePrice,
            amount: returnItemAmount,
            purchaseDate: batch.purchaseDate,
          ));

          remainingToReturn -= qtyFromBatch;

          debugPrint(
              '[PurchaseReturn] Deducted $qtyFromBatch from batch ${batch.id} '
              '(${batch.productName}), price: ${batch.purchasePrice}');
        }
      }

      // Create PurchaseReturn document
      final now = DateTime.now();
      final purchaseReturn = PurchaseReturn(
        id: returnRefId,
        supplierId: supplierId,
        supplierName: supplierName,
        returnDate: returnDate,
        totalAmount: totalReturnAmount,
        reason: reason,
        status: 'completed',
        items: processedItems,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firebase
      final docId = await _repository.createReturn(purchaseReturn);

      debugPrint(
          '[PurchaseReturn] Processed: $docId, items: ${processedItems.length}, '
          'total: ₹$totalReturnAmount');

      return PurchaseReturnResult.success(
          purchaseReturn.copyWith(id: docId));
    } catch (e) {
      debugPrint('[PurchaseReturn] Error: $e');
      return PurchaseReturnResult.failure(
          'Failed to process return: $e');
    }
  }
}
