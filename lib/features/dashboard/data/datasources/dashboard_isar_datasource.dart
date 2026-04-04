import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../billing/offline/entities/bill_entity.dart';
import '../../../customer/offline/controllers/customer_offline_controller.dart';
import '../../../customer/offline/entities/customer_entity.dart';
import '../../../inventory_management/offline/controllers/purchase_offline_controller.dart';
import '../../../inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import '../../../inventory_management/offline/entities/purchase_batch_entity.dart';
import '../../../inventory_management/offline/entities/purchase_entity.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../product/offline/entities/product_entity.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../supplier/offline/entities/supplier_entity.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../../company/offline/entities/company_entity.dart';
import '../../../event_order/offline/entities/event_order_entity.dart';
import '../../../event_order/domain/entities/event_order.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';

/// Ultra-fast Isar-based dashboard datasource
/// All calculations are from local Isar DB — instant, offline-capable, and accurate.
///
/// Key fixes over the old Firebase datasource:
/// 1. Returns are properly deducted from sales/profit
/// 2. Stock value uses batch quantityRemaining × purchasePrice (not product-level)
/// 3. Pending amounts are tracked
/// 4. Reactive streams via Isar watchLazy()
class DashboardIsarDataSource {
  static DashboardIsarDataSource? _instance;

  Isar get _isar => IsarService.instance.isar;

  DashboardIsarDataSource._();

  static DashboardIsarDataSource get instance {
    _instance ??= DashboardIsarDataSource._();
    return _instance!;
  }

  /// Debounce timer for reactive updates
  Timer? _debounceTimer;

  /// Active stream subscriptions for Isar watchers
  final List<StreamSubscription> _watchSubscriptions = [];

  /// Fetch dashboard summary from local Isar DB
  /// All calculations are local — typically completes in < 5ms
  Future<DashboardSummary> fetchDashboardSummary({
    required DashboardParams params,
  }) async {
    final stopwatch = Stopwatch()..start();
    final (startDate, endDate) = params.getDateRange();

    // Execute ALL local queries in parallel for maximum speed
    final results = await Future.wait([
      // Counts — instant from Isar (0-5)
      CustomerOfflineController.instance.getTotalCount(),
      ProductOfflineController.instance.getTotalCount(),
      SupplierOfflineController.instance.getTotalCount(),
      CompanyOfflineController.instance.getTotalCount(),
      BillOfflineController.instance.getTotalCount(),
      PurchaseOfflineController.instance.getTotalCount(),
      // Period-specific data (6-8)
      _getSalesDataForPeriod(startDate, endDate),
      _getPurchaseDataForPeriod(startDate, endDate),
      _getStockDataFromBatches(),
      // Pending amounts (9)
      _getTotalPendingAmount(),
      // Event/Order data (10)
      _getEventOrderData(),
    ]);

    // Extract counts
    final customersCount = results[0] as int;
    final productsCount = results[1] as int;
    final suppliersCount = results[2] as int;
    final companiesCount = results[3] as int;
    final billsCount = results[4] as int;
    final purchasesCount = results[5] as int;

    // Extract sales data (with returns properly deducted)
    final salesData = results[6] as _SalesResult;

    // Extract purchase data
    final purchaseData = results[7] as _PurchaseResult;

    // Extract stock data (from batches)
    final stockData = results[8] as _StockResult;

    // Extract pending amount
    final totalPendingAmount = results[9] as double;

    // Extract event/order data
    final eventOrderData = results[10] as _EventOrderResult;

    // Net Sales = Gross Sales - Returns
    final netSales = salesData.grossSales - salesData.totalReturns;

    // Profit = Revenue from sold (non-returned) items - Cost of sold (non-returned) items
    final profit = salesData.netProfit;
    final profitPercentage = netSales > 0 ? (profit / netSales) * 100 : 0.0;

    stopwatch.stop();
    debugPrint(
      '[DashboardIsarDS] Data loaded in ${stopwatch.elapsedMicroseconds}μs '
      '(${stopwatch.elapsedMilliseconds}ms) | '
      'GrossSales: ${salesData.grossSales.toStringAsFixed(0)}, '
      'Returns: ${salesData.totalReturns.toStringAsFixed(0)}, '
      'NetSales: ${netSales.toStringAsFixed(0)}, '
      'Profit: ${profit.toStringAsFixed(0)}, '
      'Events/Orders: ${eventOrderData.totalCount}',
    );

    return DashboardSummary(
      invoicesCount: billsCount,
      clientsCount: customersCount,
      productsCount: productsCount,
      suppliersCount: suppliersCount,
      purchasesCount: purchasesCount,
      companiesCount: companiesCount,
      totalSales: salesData.grossSales,
      totalBillsCount: salesData.billCount,
      totalItemsSold: salesData.totalItemsSold,
      totalReturns: salesData.totalReturns,
      totalReturnedItems: salesData.totalReturnedItems,
      netSales: netSales,
      totalPurchases: purchaseData.totalAmount,
      purchaseOrders: purchaseData.orderCount,
      purchaseQty: purchaseData.totalQty,
      profit: profit,
      profitPercentage: profitPercentage,
      stockValue: stockData.stockValue,
      lowStockCount: stockData.lowStockCount,
      totalPendingAmount: totalPendingAmount,
      totalEventOrders: eventOrderData.totalCount,
      upcomingEvents: eventOrderData.upcomingEvents,
      pendingOrders: eventOrderData.pendingOrders,
      eventOrdersAmount: eventOrderData.totalAmount,
      eventOrdersAdvance: eventOrderData.totalAdvance,
      eventOrdersPending: eventOrderData.totalPending,
      lastUpdated: DateTime.now(),
      isFromCache: false,
    );
  }

  /// Create a reactive stream that emits new DashboardSummary whenever
  /// bills, purchases, or batches change in the local Isar DB.
  /// Uses Isar's watchLazy() + debounce to avoid excessive recalculations.
  Stream<DashboardSummary> watchDashboardSummary({
    required DashboardParams params,
  }) {
    late StreamController<DashboardSummary> controller;

    controller = StreamController<DashboardSummary>(
      onListen: () async {
        // Emit initial data immediately
        try {
          final initial = await fetchDashboardSummary(params: params);
          if (!controller.isClosed) {
            controller.add(initial);
          }
        } catch (e) {
          debugPrint('[DashboardIsarDS] Error fetching initial data: $e');
        }

        // Watch Isar collections for changes
        void onCollectionChanged() {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
            try {
              final updated = await fetchDashboardSummary(params: params);
              if (!controller.isClosed) {
                controller.add(updated);
              }
            } catch (e) {
              debugPrint('[DashboardIsarDS] Error in watch update: $e');
            }
          });
        }

        // Watch ALL relevant collections for complete real-time updates
        // Bills, purchases, and batches for financial data
        _watchSubscriptions.add(
          _isar.billEntitys.watchLazy().listen((_) => onCollectionChanged()),
        );
        _watchSubscriptions.add(
          _isar.purchaseEntitys.watchLazy().listen(
            (_) => onCollectionChanged(),
          ),
        );
        _watchSubscriptions.add(
          _isar.purchaseBatchEntitys.watchLazy().listen(
            (_) => onCollectionChanged(),
          ),
        );
        // Customers, products, suppliers, companies for count stats
        _watchSubscriptions.add(
          _isar.customerEntitys.watchLazy().listen(
            (_) => onCollectionChanged(),
          ),
        );
        _watchSubscriptions.add(
          _isar.productEntitys.watchLazy().listen((_) => onCollectionChanged()),
        );
        _watchSubscriptions.add(
          _isar.supplierEntitys.watchLazy().listen(
            (_) => onCollectionChanged(),
          ),
        );
        _watchSubscriptions.add(
          _isar.companyEntitys.watchLazy().listen((_) => onCollectionChanged()),
        );
        // Event orders for real-time event/order updates
        _watchSubscriptions.add(
          _isar.eventOrderEntitys.watchLazy().listen(
            (_) => onCollectionChanged(),
          ),
        );
        // Also listen to DashboardRefreshService for external refresh requests
        _watchSubscriptions.add(
          DashboardRefreshService.instance.onRefreshNeeded.listen(
            (_) => onCollectionChanged(),
          ),
        );
      },
      onCancel: () {
        _debounceTimer?.cancel();
        for (final sub in _watchSubscriptions) {
          sub.cancel();
        }
        _watchSubscriptions.clear();
        controller.close();
      },
    );

    return controller.stream;
  }

  // ==================== SALES CALCULATION ====================

  /// Calculate sales metrics for the given period.
  /// CORRECTLY handles:
  /// - Partial/full returns (deducts returnedQuantity from sold quantity)
  /// - Discount proportioning per item
  /// - Profit based on net sold items only
  Future<_SalesResult> _getSalesDataForPeriod(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final bills = await BillOfflineController.instance.getBillsByDateRange(
      startDate ?? DateTime(2000),
      endDate ?? DateTime.now().add(const Duration(days: 1)),
    );

    double grossSales = 0;
    double totalReturns = 0;
    double netProfit = 0;
    int totalItemsSold = 0;
    int totalReturnedItems = 0;

    for (final bill in bills) {
      // Gross sales = sum of finalAmount (already includes discount)
      grossSales += bill.finalAmount;

      // Calculate discount ratio for proportional return calculation
      final billTotalAmount = bill.totalAmount; // pre-discount total
      final discountRatio = billTotalAmount > 0
          ? bill.discountAmount / billTotalAmount
          : 0.0;

      for (final item in bill.items) {
        final qty = item.quantity;
        final returnedQty = item.returnedQuantity;
        final netSoldQty = qty - returnedQty;
        final sellingPrice = item.sellingPrice;
        final purchasePrice = item.purchasePrice;

        totalItemsSold += qty.round(); // Round for dashboard display
        totalReturnedItems += returnedQty
            .round(); // Round for dashboard display

        // Return amount = returnedQty × sellingPrice × (1 - discountRatio)
        // This accounts for the proportional discount that was applied at sale
        final returnAmount = returnedQty * sellingPrice * (1 - discountRatio);
        totalReturns += returnAmount;

        // Profit from this item = revenue from NET sold items - cost of NET sold items
        // Revenue = netSoldQty × sellingPrice × (1 - discountRatio)
        // Cost = netSoldQty × purchasePrice
        final netRevenue = netSoldQty * sellingPrice * (1 - discountRatio);
        final netCost = netSoldQty * purchasePrice;
        netProfit += (netRevenue - netCost);
      }
    }

    return _SalesResult(
      grossSales: grossSales,
      totalReturns: totalReturns,
      netProfit: netProfit,
      billCount: bills.length,
      totalItemsSold: totalItemsSold,
      totalReturnedItems: totalReturnedItems,
    );
  }

  // ==================== PURCHASE CALCULATION ====================

  /// Calculate purchase totals from PurchaseBatchEntity for real-time accuracy.
  /// Using batches instead of PurchaseEntity ensures dashboard updates immediately
  /// when users edit purchase records (which modify batch data).
  Future<_PurchaseResult> _getPurchaseDataForPeriod(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Use PurchaseBatchEntity for real-time accuracy since edits update batches
    final batches = await PurchaseBatchOfflineController.instance
        .getBatchesByDateRange(
          startDate ?? DateTime(2000),
          endDate ?? DateTime.now().add(const Duration(days: 1)),
        );

    double totalAmount = 0;
    int totalQty = 0;

    for (final batch in batches) {
      // Calculate total purchase amount: quantityPurchased × purchasePrice
      totalAmount += batch.quantityPurchased * batch.purchasePrice;
      totalQty += batch.quantityPurchased;
    }

    return _PurchaseResult(
      totalAmount: totalAmount,
      orderCount: batches.length,
      totalQty: totalQty,
    );
  }

  // ==================== STOCK CALCULATION ====================

  /// Stock value from BATCHES (not product-level currentStock).
  /// Sum of (quantityRemaining × purchasePrice) for all unconsumed batches.
  /// This is the accurate FIFO-based stock valuation.
  Future<_StockResult> _getStockDataFromBatches() async {
    // Query unconsumed batches directly from Isar
    final batches = await _isar.purchaseBatchEntitys
        .filter()
        .isConsumedEqualTo(false)
        .not()
        .syncStatusEqualTo(BatchSyncStatus.deleted)
        .findAll();

    double stockValue = 0;
    int lowStockCount = 0;

    // Track per-product remaining stock for low stock detection
    final productStockMap = <String, int>{};

    for (final batch in batches) {
      stockValue += batch.quantityRemaining * batch.purchasePrice;

      // Accumulate total remaining stock per product
      productStockMap[batch.productId] =
          (productStockMap[batch.productId] ?? 0) + batch.quantityRemaining;
    }

    // Count products with low stock (> 0 but < 10)
    for (final entry in productStockMap.entries) {
      if (entry.value > 0 && entry.value < 10) {
        lowStockCount++;
      }
    }

    return _StockResult(stockValue: stockValue, lowStockCount: lowStockCount);
  }

  // ==================== PENDING AMOUNTS ====================

  /// Total pending = exact sum of what customer list page shows per customer.
  /// Per customer: entity.currentPendingAmount + event order remaining for that customer.
  /// This mirrors enhanced_customer_page._entityToMap() logic exactly.
  Future<double> _getTotalPendingAmount() async {
    // 1. Get all customers
    final customers = await _isar.customerEntitys
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    // 2. Build event pending map per customer (same as enhanced_customer_page)
    final allOrders = await _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .findAll();

    final eventPendingByCustomer = <String, double>{};
    for (final order in allOrders) {
      final custId = order.customerId;
      if (custId == null || custId.isEmpty) continue;
      if (order.status == OrderStatus.cancelled.index ||
          order.status == OrderStatus.convertedToBill.index) continue;
      eventPendingByCustomer[custId] =
          (eventPendingByCustomer[custId] ?? 0.0) + order.remainingAmount;
    }

    // 3. Sum per-customer pending (same formula as _entityToMap)
    double total = 0;
    for (final customer in customers) {
      final customerPending = customer.currentPendingAmount +
          (eventPendingByCustomer[customer.serverId] ?? 0.0) +
          (eventPendingByCustomer['local_${customer.id}'] ?? 0.0);
      if (customerPending > 0) {
        total += customerPending;
      }
    }

    return total;
  }

  // ==================== EVENT ORDER CALCULATION ====================

  /// Get event/order statistics from Isar
  /// Returns total count, upcoming events, pending orders, and financial totals
  Future<_EventOrderResult> _getEventOrderData() async {
    // Get all non-deleted event orders
    final allOrders = await _isar.eventOrderEntitys
        .filter()
        .not()
        .syncStatusEqualTo(EventOrderSyncStatus.deleted)
        .findAll();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int totalCount = allOrders.length;
    int upcomingEvents = 0;
    int pendingOrders = 0;
    double totalAmount = 0;
    double totalAdvance = 0;
    double totalPending = 0;

    for (final order in allOrders) {
      totalAmount += order.totalAmount;
      totalAdvance += order.advanceAmount;
      totalPending += order.remainingAmount;

      // Count upcoming events (event date today or in future)
      final eventDateOnly = DateTime(
        order.eventDate.year,
        order.eventDate.month,
        order.eventDate.day,
      );
      if (!eventDateOnly.isBefore(today)) {
        upcomingEvents++;
      }

      // Count pending orders (not delivered, cancelled, or converted)
      if (order.status < OrderStatus.delivered.index) {
        pendingOrders++;
      }
    }

    return _EventOrderResult(
      totalCount: totalCount,
      upcomingEvents: upcomingEvents,
      pendingOrders: pendingOrders,
      totalAmount: totalAmount,
      totalAdvance: totalAdvance,
      totalPending: totalPending,
    );
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    for (final sub in _watchSubscriptions) {
      sub.cancel();
    }
    _watchSubscriptions.clear();
  }
}

// ==================== Internal Result Classes ====================

class _SalesResult {
  final double grossSales;
  final double totalReturns;
  final double netProfit;
  final int billCount;
  final int totalItemsSold;
  final int totalReturnedItems;

  const _SalesResult({
    required this.grossSales,
    required this.totalReturns,
    required this.netProfit,
    required this.billCount,
    required this.totalItemsSold,
    required this.totalReturnedItems,
  });
}

class _PurchaseResult {
  final double totalAmount;
  final int orderCount;
  final int totalQty;

  const _PurchaseResult({
    required this.totalAmount,
    required this.orderCount,
    required this.totalQty,
  });
}

class _StockResult {
  final double stockValue;
  final int lowStockCount;

  const _StockResult({required this.stockValue, required this.lowStockCount});
}

class _EventOrderResult {
  final int totalCount;
  final int upcomingEvents;
  final int pendingOrders;
  final double totalAmount;
  final double totalAdvance;
  final double totalPending;

  const _EventOrderResult({
    required this.totalCount,
    required this.upcomingEvents,
    required this.pendingOrders,
    required this.totalAmount,
    required this.totalAdvance,
    required this.totalPending,
  });
}
