import 'package:flutter/foundation.dart';
import '../../../billing/domain/entities/bill_item.dart';
import '../../../billing/offline/entities/bill_entity.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../data/services/fifo_inventory_service.dart';
import '../../offline/controllers/purchase_batch_offline_controller.dart';

/// Result class for FIFO billing operations
class FifoBillingResult {
  final bool success;
  final String? billId;
  final String? errorMessage;
  final List<String>? failedProducts;
  final double totalCOGS;
  final double totalProfit;
  final List<ConsumedBatchInfo> consumedBatches;

  FifoBillingResult({
    required this.success,
    this.billId,
    this.errorMessage,
    this.failedProducts,
    this.totalCOGS = 0.0,
    this.totalProfit = 0.0,
    this.consumedBatches = const [],
  });

  factory FifoBillingResult.success({
    required String billId,
    required double totalCOGS,
    required double totalProfit,
    required List<ConsumedBatchInfo> consumedBatches,
  }) {
    return FifoBillingResult(
      success: true,
      billId: billId,
      totalCOGS: totalCOGS,
      totalProfit: totalProfit,
      consumedBatches: consumedBatches,
    );
  }

  factory FifoBillingResult.failure(
    String message, {
    List<String>? failedProducts,
  }) {
    return FifoBillingResult(
      success: false,
      errorMessage: message,
      failedProducts: failedProducts,
    );
  }
}

/// Service for handling billing operations with FIFO inventory management
/// Ensures accurate COGS calculation by tracking which batches are consumed
class FifoBillingService {
  static FifoBillingService? _instance;

  final FifoInventoryService _fifoService;
  final BillOfflineController _billController;
  // ignore: unused_field
  final PurchaseBatchOfflineController _batchController;

  FifoBillingService._({
    required FifoInventoryService fifoService,
    required BillOfflineController billController,
    required PurchaseBatchOfflineController batchController,
  }) : _fifoService = fifoService,
       _billController = billController,
       _batchController = batchController;

  /// Get the singleton instance
  static FifoBillingService get instance {
    _instance ??= FifoBillingService._(
      fifoService: FifoInventoryService.instance,
      billController: BillOfflineController.instance,
      batchController: PurchaseBatchOfflineController.instance,
    );
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Validate stock availability for bill items
  /// Returns map of productId -> error message for products with insufficient stock
  Future<Map<String, String>> validateStock(List<BillItem> items) async {
    final errors = <String, String>{};

    for (final item in items) {
      final availableStock = await _fifoService.getAvailableStock(
        item.productId,
      );

      // Use rounded quantity for stock comparison since stock is integer-based
      if (availableStock < item.quantityInt) {
        final displayQty = item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toStringAsFixed(2);
        errors[item.productId] =
            '${item.productName}: Insufficient stock. Available: $availableStock, Requested: $displayQty';
      }
    }

    return errors;
  }

  /// Get current stock for a product
  Future<int> getProductStock(String productId) async {
    return await _fifoService.getAvailableStock(productId);
  }

  /// Process and save a bill with FIFO inventory management
  /// Creates ledger entries for each consumed batch with accurate COGS
  Future<FifoBillingResult> processBill({
    required List<BillItem> items,
    String? customerId,
    String? customerName,
    String? customerContact,
    String? notes,
    double discountAmount = 0.0,
    double discountPercent = 0.0,
    double? paidAmount,
  }) async {
    // Validate that there are items
    if (items.isEmpty) {
      return FifoBillingResult.failure('Cannot create a bill with no items');
    }

    // Validate stock availability first
    final stockErrors = await validateStock(items);
    if (stockErrors.isNotEmpty) {
      return FifoBillingResult.failure(
        'Insufficient stock for some products',
        failedProducts: stockErrors.keys.toList(),
      );
    }

    try {
      // Calculate totals (use rounded quantity for display total)
      final totalQuantity = items.fold(
        0,
        (sum, item) => sum + item.quantityInt,
      );
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.subtotal);

      // Apply discount
      double finalDiscount = discountAmount;
      if (discountPercent > 0 && discountAmount == 0) {
        finalDiscount = totalAmount * (discountPercent / 100);
      }
      final finalAmount = totalAmount - finalDiscount;

      // Determine payment status
      final actualPaidAmount = paidAmount ?? finalAmount;
      final pendingAmount = finalAmount - actualPaidAmount;

      BillPaymentStatus paymentStatus;
      if (pendingAmount <= 0) {
        paymentStatus = BillPaymentStatus.paid;
      } else if (actualPaidAmount > 0) {
        paymentStatus = BillPaymentStatus.partiallyPaid;
      } else {
        paymentStatus = BillPaymentStatus.pending;
      }

      // Create bill items with embedded format
      final billItemsEmbedded = items
          .map(
            (item) => BillItemEmbedded(
              itemId: item.id.isEmpty
                  ? 'item_${DateTime.now().millisecondsSinceEpoch}_${item.productId}'
                  : item.id,
              productId: item.productId,
              productName: item.productName,
              purchasePrice:
                  item.purchasePrice, // Will be updated with actual COGS
              sellingPrice: item.sellingPrice,
              quantity: item.quantity,
              subtotal: item.subtotal,
              returnedQuantity: 0,
            ),
          )
          .toList();

      // Create bill locally first
      final bill = await _billController.addBill(
        customerId: customerId,
        customerName: customerName,
        customerContact: customerContact,
        items: billItemsEmbedded,
        totalQuantity: totalQuantity,
        totalAmount: totalAmount,
        discountAmount: finalDiscount,
        discountPercent: discountPercent,
        finalAmount: finalAmount,
        notes: notes,
        paymentStatus: paymentStatus,
        paidAmount: actualPaidAmount,
        pendingAmount: pendingAmount > 0 ? pendingAmount : 0,
      );

      final billId = bill.serverId ?? 'local_${bill.id}';

      // Process FIFO sales for each item
      final allConsumedBatches = <ConsumedBatchInfo>[];
      double totalCOGS = 0.0;
      double totalRevenue = 0.0;
      double totalProfit = 0.0;

      for (final item in items) {
        final saleResult = await _fifoService.processFifoSale(
          productId: item.productId,
          quantity: item.quantityInt, // Round for FIFO stock tracking
          sellingPrice: item.sellingPrice,
          billId: billId,
          notes: 'Bill: $billId',
        );

        if (!saleResult.success) {
          // This shouldn't happen since we validated stock, but handle it
          debugPrint(
            '[FifoBilling] Warning: Sale failed for ${item.productName}: ${saleResult.errorMessage}',
          );
          continue;
        }

        allConsumedBatches.addAll(saleResult.consumedBatches);
        totalCOGS += saleResult.totalCOGS;
        totalRevenue += saleResult.totalRevenue;
        totalProfit += saleResult.totalProfit;
      }

      debugPrint(
        '[FifoBilling] Bill processed: $billId, COGS: $totalCOGS, Revenue: $totalRevenue, Profit: $totalProfit',
      );

      return FifoBillingResult.success(
        billId: billId,
        totalCOGS: totalCOGS,
        totalProfit: totalProfit,
        consumedBatches: allConsumedBatches,
      );
    } catch (e) {
      debugPrint('[FifoBilling] Failed to process bill: $e');
      return FifoBillingResult.failure('Failed to process bill: $e');
    }
  }

  /// Process a return for bill items
  /// Adds stock back to original batches using FIFO reverse
  Future<bool> processReturn({
    required String billId,
    required List<ReturnItemInfo> returnItems,
    String? notes,
  }) async {
    try {
      for (final returnItem in returnItems) {
        await _fifoService.processSaleReturn(
          productId: returnItem.productId,
          productName: returnItem.productName,
          companyName: returnItem.companyName,
          modelName: returnItem.modelName,
          batchId: returnItem.batchId,
          localBatchId: returnItem.localBatchId,
          quantity: returnItem.quantity,
          costPrice: returnItem.costPrice,
          sellingPrice: returnItem.sellingPrice,
          returnReferenceId:
              'RETURN_${billId}_${DateTime.now().millisecondsSinceEpoch}',
          notes: notes,
        );
      }

      debugPrint('[FifoBilling] Return processed for bill: $billId');
      return true;
    } catch (e) {
      debugPrint('[FifoBilling] Failed to process return: $e');
      return false;
    }
  }

  /// Get bill with COGS information
  Future<Map<String, dynamic>?> getBillWithCOGS(String billId) async {
    // This would typically join bill data with ledger entries to show
    // which batches were consumed and at what cost
    // Implementation depends on your specific needs
    return null;
  }

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
      'profitMargin': totalRevenue > 0
          ? (totalProfit / totalRevenue * 100)
          : 0.0,
    };
  }
}

/// Information about an item being returned
class ReturnItemInfo {
  final String productId;
  final String productName;
  final String companyName;
  final String modelName;
  final String batchId;
  final int? localBatchId;
  final int quantity;
  final double costPrice;
  final double sellingPrice;

  ReturnItemInfo({
    required this.productId,
    required this.productName,
    this.companyName = '',
    this.modelName = '',
    required this.batchId,
    this.localBatchId,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
  });
}
