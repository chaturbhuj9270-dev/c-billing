import 'package:flutter/foundation.dart';
import '../models/dashboard_data.dart';
import '../../../customer/offline/controllers/customer_offline_controller.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../inventory_management/offline/controllers/purchase_offline_controller.dart';
import '../../../inventory_management/offline/controllers/purchase_batch_offline_controller.dart';
import '../../../event_order/offline/controllers/event_order_offline_controller.dart';
import '../../../event_order/domain/entities/event_order.dart';

/// Ultra-fast offline-first dashboard repository
/// Uses Isar local database for microsecond-level data loading
/// No network calls - all data is from local Isar database
class DashboardOfflineRepository {
  static DashboardOfflineRepository? _instance;

  DashboardOfflineRepository._();

  static DashboardOfflineRepository get instance {
    _instance ??= DashboardOfflineRepository._();
    return _instance!;
  }

  /// Fetch dashboard data from local Isar database
  /// Returns data in microseconds since all queries are local
  Future<DashboardData> fetchDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Execute ALL local queries in parallel for maximum speed
    final results = await Future.wait([
      // Counts - instant from Isar
      CustomerOfflineController.instance.getTotalCount(), // 0
      ProductOfflineController.instance.getTotalCount(), // 1
      SupplierOfflineController.instance.getTotalCount(), // 2
      CompanyOfflineController.instance.getTotalCount(), // 3
      BillOfflineController.instance.getTotalCount(), // 4
      PurchaseOfflineController.instance.getTotalCount(), // 5
      // Sales data for period
      _getSalesDataForPeriod(startDate, endDate), // 6
      // Purchase data for period
      _getPurchaseDataForPeriod(startDate, endDate), // 7
      // Stock data
      _getStockData(), // 8
      // Event/Order data for period
      _getEventOrderDataForPeriod(startDate, endDate), // 9
    ]);

    // Extract counts
    final customersCount = results[0] as int;
    final productsCount = results[1] as int;
    final suppliersCount = results[2] as int;
    final companiesCount = results[3] as int;
    final billsCount = results[4] as int;
    final purchasesCount = results[5] as int;

    // Extract sales data
    final salesData = results[6] as Map<String, dynamic>;
    final totalSalesAmount = salesData['totalAmount'] as double;
    final totalBillsCount = salesData['billsCount'] as int;
    final totalItemsSold = salesData['itemsSold'] as int;
    final totalReturns = salesData['totalReturns'] as double;
    final totalPending = salesData['totalPending'] as double;

    // Extract purchase data
    final purchaseData = results[7] as Map<String, dynamic>;
    final totalPurchaseAmount = purchaseData['totalAmount'] as double;
    final totalPurchaseQty = purchaseData['totalQty'] as int;
    final purchaseOrdersCount = purchaseData['ordersCount'] as int;

    // Extract stock data
    final stockData = results[8] as Map<String, dynamic>;
    final stockValue = stockData['stockValue'] as double;
    final lowStockCount = stockData['lowStockCount'] as int;

    // Extract event/order data
    final eventOrderData = results[9] as Map<String, dynamic>;
    final totalEventOrders = eventOrderData['totalCount'] as int;
    final upcomingEvents = eventOrderData['upcomingEvents'] as int;
    final pendingOrders = eventOrderData['pendingOrders'] as int;
    final eventOrdersAmount = eventOrderData['totalAmount'] as double;
    final eventOrdersAdvance = eventOrderData['totalAdvance'] as double;
    final eventOrdersPending = eventOrderData['totalPending'] as double;
    final eventOrdersProfit = eventOrderData['profit'] as double;

    // Calculate profit from net sales (after returns) + event/order profit
    final netSales = totalSalesAmount - totalReturns;
    final billsProfit = salesData['netProfit'] as double;
    final totalProfit = billsProfit + eventOrdersProfit;
    final profitPercentage = (netSales + eventOrdersAmount) > 0
        ? (totalProfit / (netSales + eventOrdersAmount)) * 100
        : 0.0;

    stopwatch.stop();
    debugPrint(
      '[DashboardOffline] Data loaded in ${stopwatch.elapsedMicroseconds}μs (${stopwatch.elapsedMilliseconds}ms)',
    );

    return DashboardData(
      invoicesCount: billsCount,
      clientsCount: customersCount,
      productsCount: productsCount,
      suppliersCount: suppliersCount,
      purchasesCount: purchasesCount,
      companiesCount: companiesCount,
      inventoryCount: productsCount,
      totalSales: totalSalesAmount,
      totalBillsCount: totalBillsCount,
      totalItemsSold: totalItemsSold,
      totalReturns: totalReturns,
      totalReturnedItems: salesData['returnedItems'] as int,
      netSales: netSales,
      totalPurchases: totalPurchaseAmount,
      purchaseOrders: purchaseOrdersCount,
      purchaseQty: totalPurchaseQty,
      profit: totalProfit,
      profitPercentage: profitPercentage,
      stockValue: stockValue,
      lowStockCount: lowStockCount,
      totalPendingAmount: totalPending,
      totalEventOrders: totalEventOrders,
      upcomingEvents: upcomingEvents,
      pendingOrders: pendingOrders,
      eventOrdersAmount: eventOrdersAmount,
      eventOrdersAdvance: eventOrdersAdvance,
      eventOrdersPending: eventOrdersPending,
    );
  }

  /// Get sales data for the specified period
  /// CORRECTLY handles returns: deducts returnedQuantity from sales and profit
  Future<Map<String, dynamic>> _getSalesDataForPeriod(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final bills = await BillOfflineController.instance.getBillsByDateRange(
      startDate ?? DateTime(2000),
      endDate ?? DateTime.now().add(const Duration(days: 1)),
    );

    double grossAmount = 0;
    double totalReturns = 0;
    double netProfit = 0;
    int itemsSold = 0;
    int returnedItems = 0;
    double totalPending = 0;

    for (final bill in bills) {
      // Gross sales = sum of finalAmount (after discounts)
      grossAmount += bill.finalAmount;

      // Track pending amounts
      totalPending += bill.pendingAmount;

      // Calculate discount ratio for proportional return calculation
      final discountRatio = bill.totalAmount > 0
          ? bill.discountAmount / bill.totalAmount
          : 0.0;

      // Sum up quantities from all items, accounting for returns
      for (final item in bill.items) {
        final qty = item.quantity;
        final returnedQty = item.returnedQuantity;
        final netSoldQty = qty - returnedQty;

        itemsSold += qty.round(); // Round for dashboard display
        returnedItems += returnedQty.round(); // Round for dashboard display

        // Return amount = returnedQty × sellingPrice × (1 - discountRatio)
        final returnAmount =
            returnedQty * item.sellingPrice * (1 - discountRatio);
        totalReturns += returnAmount;

        // Profit from net sold items only
        final netRevenue = netSoldQty * item.sellingPrice * (1 - discountRatio);
        final netCost = netSoldQty * item.purchasePrice;
        netProfit += (netRevenue - netCost);
      }
    }

    return {
      'totalAmount': grossAmount,
      'totalReturns': totalReturns,
      'netProfit': netProfit,
      'billsCount': bills.length,
      'itemsSold': itemsSold,
      'returnedItems': returnedItems,
      'totalPending': totalPending,
    };
  }

  /// Get purchase data for the specified period
  Future<Map<String, dynamic>> _getPurchaseDataForPeriod(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final purchases = await PurchaseOfflineController.instance
        .getPurchasesByDateRange(
          startDate ?? DateTime(2000),
          endDate ?? DateTime.now().add(const Duration(days: 1)),
        );

    double totalAmount = 0;
    int totalQty = 0;

    for (final purchase in purchases) {
      totalAmount += purchase.totalAmount;
      totalQty += purchase.quantity;
    }

    return {
      'totalAmount': totalAmount,
      'ordersCount': purchases.length,
      'totalQty': totalQty,
    };
  }

  /// Get stock data from products
  Future<Map<String, dynamic>> _getStockData() async {
    final products = await ProductOfflineController.instance.getAllProducts();

    double stockValue = 0;
    int lowStockCount = 0;

    for (final product in products) {
      stockValue += product.currentStock * product.purchasePrice;

      // Check for low stock (below minimum or below 10 if no minimum set)
      final minStock = product.minStockLevel ?? 10;
      if (product.currentStock > 0 && product.currentStock < minStock) {
        lowStockCount++;
      }
    }

    return {'stockValue': stockValue, 'lowStockCount': lowStockCount};
  }

  /// Get event/order data for the specified period
  /// Calculates profit from sales orders and event charges
  Future<Map<String, dynamic>> _getEventOrderDataForPeriod(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final orders = await EventOrderOfflineController.instance
        .getEventOrdersByDateRange(
          startDate ?? DateTime(2000),
          endDate ?? DateTime.now().add(const Duration(days: 1)),
        );

    // Get all products for looking up purchase prices
    final products = await ProductOfflineController.instance.getAllProducts();
    final productPriceMap = <String, double>{};
    for (final product in products) {
      // Map both serverId and local id for lookup
      if (product.serverId != null) {
        productPriceMap[product.serverId!] = product.purchasePrice;
      }
      productPriceMap['local_${product.id}'] = product.purchasePrice;
    }

    int totalCount = 0;
    int upcomingEvents = 0;
    int pendingOrders = 0;
    double totalAmount = 0.0;
    double totalAdvance = 0.0;
    double totalPending = 0.0;
    double profit = 0.0;

    final now = DateTime.now();

    for (final order in orders) {
      // Skip cancelled orders from calculations
      if (order.status == OrderStatus.cancelled.index) continue;

      // Skip orders that have been converted to bills (already counted in bill profit)
      if (order.status == OrderStatus.convertedToBill.index) continue;

      totalCount++;
      totalAmount += order.totalAmount;
      totalAdvance += order.advanceAmount;
      totalPending += order.remainingAmount;

      // Count upcoming events (event date in future)
      if (order.eventDate.isAfter(now) &&
          order.orderType == OrderType.event.index) {
        upcomingEvents++;
      }

      // Count pending orders (not delivered, cancelled, or converted)
      if (order.status < OrderStatus.delivered.index) {
        pendingOrders++;
      }

      // Calculate profit based on order type
      if (order.orderType == OrderType.event.index) {
        // For events: profit = eventCharges + sum of sub-event charges (service revenue)
        // Events are service-based, so we count the full amount as profit
        profit += order.eventCharges;
        for (final subEvent in order.subEvents) {
          profit += subEvent.charges;
        }
      } else {
        // For sales orders: profit = (selling price - purchase price) * quantity for each item
        for (final item in order.items) {
          final productId = item.productId ?? '';
          final purchasePrice = productPriceMap[productId] ?? 0.0;

          // Calculate profit: (rate - purchasePrice) * quantity
          // Note: Using subtotal before tax and after discount
          final itemProfit = (item.rate - purchasePrice) * item.quantity;
          profit += itemProfit;
        }
      }
    }

    return {
      'totalCount': totalCount,
      'upcomingEvents': upcomingEvents,
      'pendingOrders': pendingOrders,
      'totalAmount': totalAmount,
      'totalAdvance': totalAdvance,
      'totalPending': totalPending,
      'profit': profit,
    };
  }

  /// Get top selling products (by net quantity sold - excluding returns)
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 5,
  }) async {
    final bills = await BillOfflineController.instance.getAllBills();

    // Aggregate sales by product (accounting for returns)
    final productSales = <String, Map<String, dynamic>>{};

    for (final bill in bills) {
      for (final item in bill.items) {
        final productId = item.productId ?? '';
        if (productId.isEmpty) continue;

        // Net sold quantity = quantity - returned quantity
        final netQty = item.quantity - item.returnedQuantity;
        if (netQty <= 0) continue;

        if (!productSales.containsKey(productId)) {
          productSales[productId] = {
            'productId': productId,
            'productName': item.productName ?? 'Unknown',
            'totalQty': 0,
            'totalAmount': 0.0,
            'billCount': 0,
          };
        }

        productSales[productId]!['totalQty'] =
            (productSales[productId]!['totalQty'] as int) + netQty;
        productSales[productId]!['totalAmount'] =
            (productSales[productId]!['totalAmount'] as double) +
            (netQty * item.sellingPrice);
        productSales[productId]!['billCount'] =
            (productSales[productId]!['billCount'] as int) + 1;
      }
    }

    // Sort by quantity and take top N
    final sorted = productSales.values.toList()
      ..sort((a, b) => (b['totalQty'] as int).compareTo(a['totalQty'] as int));

    return sorted.take(limit).toList();
  }

  /// Get low stock products (products below minimum stock level or below 10 if not set)
  /// Uses batch-based stock calculation for accurate real-time stock levels
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int limit = 5,
  }) async {
    final allProducts = await ProductOfflineController.instance
        .getAllProducts();
    final allBatches = await PurchaseBatchOfflineController.instance
        .getAllBatches(includeConsumed: false);

    // Calculate actual stock from batches for each product
    final Map<String, int> productStockFromBatches = {};
    for (final batch in allBatches) {
      final productId = batch.productId;
      productStockFromBatches[productId] =
          (productStockFromBatches[productId] ?? 0) + batch.quantityRemaining;
    }

    // Filter products that are low on stock (using batch-based stock)
    final lowStockProducts = <Map<String, dynamic>>[];

    for (final p in allProducts) {
      final productId = p.serverId ?? p.id.toString();
      // Use batch stock if available, otherwise fall back to product's currentStock
      final actualStock = productStockFromBatches[productId] ?? p.currentStock;

      if (actualStock <= 0) continue; // Out of stock shown separately

      final minStock = p.minStockLevel ?? 10; // Default threshold of 10
      if (actualStock < minStock) {
        lowStockProducts.add({
          'id': productId,
          'name': p.name,
          'currentStock': actualStock,
          'minStockLevel': minStock,
          'stockPercent': actualStock / minStock,
        });
      }
    }

    // Sort by urgency (lowest stock percentage first)
    lowStockProducts.sort((a, b) {
      final aPercent = a['stockPercent'] as double;
      final bPercent = b['stockPercent'] as double;
      return aPercent.compareTo(bPercent);
    });

    return lowStockProducts.take(limit).toList();
  }

  /// Get customers with pending payments
  Future<List<Map<String, dynamic>>> getCustomersWithPendingBalance({
    int limit = 5,
  }) async {
    final customers = await CustomerOfflineController.instance
        .getCustomersWithPendingBalance();

    return customers
        .take(limit)
        .map(
          (c) => {
            'id': c.serverId ?? c.id.toString(),
            'name': c.name,
            'currentPendingAmount': c.currentPendingAmount,
            'mobile': c.mobile,
          },
        )
        .toList();
  }

  /// Get recent bills with pending amount
  Future<List<Map<String, dynamic>>> getRecentPendingBills({
    int limit = 5,
  }) async {
    final bills = await BillOfflineController.instance.getPendingBills();

    return bills
        .take(limit)
        .map(
          (b) => {
            'id': b.serverId ?? b.id.toString(),
            'customerName': b.customerName ?? 'Unknown',
            'pendingAmount': b.pendingAmount,
            'billDate': b.billDate.toIso8601String(),
            'totalAmount': b.finalAmount,
          },
        )
        .toList();
  }

  /// Get upcoming payment dues - pending bills that need collection soonest
  /// Returns bills sorted by oldest first (most overdue for collection)
  Future<List<Map<String, dynamic>>> getUpcomingPaymentDues({
    int limit = 5,
  }) async {
    final pendingBills = await BillOfflineController.instance.getPendingBills();

    if (pendingBills.isEmpty) return [];

    // Sort by bill date (oldest first - most urgent to collect)
    final sortedBills = List.of(pendingBills)
      ..sort((a, b) => a.billDate.compareTo(b.billDate));

    return sortedBills.take(limit).map((b) {
      // Calculate days since bill was created
      final daysSinceBill = DateTime.now().difference(b.billDate).inDays;

      return {
        'id': b.serverId ?? b.id.toString(),
        'customerName': b.customerName ?? 'Unknown',
        'customerContact': b.customerContact ?? '',
        'pendingAmount': b.pendingAmount,
        'totalAmount': b.finalAmount,
        'billDate': b.billDate.toIso8601String(),
        'daysPending': daysSinceBill,
        'isOverdue':
            daysSinceBill > 30, // Consider 30 days as overdue threshold
      };
    }).toList();
  }
}
