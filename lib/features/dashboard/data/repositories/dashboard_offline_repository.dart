import 'package:flutter/foundation.dart';
import '../models/dashboard_data.dart';
import '../../../customer/offline/controllers/customer_offline_controller.dart';
import '../../../product/offline/controllers/product_offline_controller.dart';
import '../../../supplier/offline/controllers/supplier_offline_controller.dart';
import '../../../company/offline/controllers/company_offline_controller.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../inventory_management/offline/controllers/purchase_offline_controller.dart';

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
      CustomerOfflineController.instance.getTotalCount(),       // 0
      ProductOfflineController.instance.getTotalCount(),        // 1
      SupplierOfflineController.instance.getTotalCount(),       // 2
      CompanyOfflineController.instance.getTotalCount(),        // 3
      BillOfflineController.instance.getTotalCount(),           // 4
      PurchaseOfflineController.instance.getTotalCount(),       // 5
      
      // Sales data for period
      _getSalesDataForPeriod(startDate, endDate),               // 6
      
      // Purchase data for period
      _getPurchaseDataForPeriod(startDate, endDate),            // 7
      
      // Stock data
      _getStockData(),                                           // 8
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

    // Calculate profit from net sales (after returns)
    final netSales = totalSalesAmount - totalReturns;
    final profit = salesData['netProfit'] as double;
    final profitPercentage = netSales > 0
        ? (profit / netSales) * 100
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
      profit: profit,
      profitPercentage: profitPercentage,
      stockValue: stockValue,
      lowStockCount: lowStockCount,
      totalPendingAmount: totalPending,
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
        
        itemsSold += qty;
        returnedItems += returnedQty;
        
        // Return amount = returnedQty × sellingPrice × (1 - discountRatio)
        final returnAmount = returnedQty * item.sellingPrice * (1 - discountRatio);
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
    final purchases = await PurchaseOfflineController.instance.getPurchasesByDateRange(
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

    return {
      'stockValue': stockValue,
      'lowStockCount': lowStockCount,
    };
  }

  /// Get top selling products (by quantity sold in bills)
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5}) async {
    final bills = await BillOfflineController.instance.getAllBills();
    
    // Aggregate sales by product
    final productSales = <String, Map<String, dynamic>>{};
    
    for (final bill in bills) {
      for (final item in bill.items) {
        final productId = item.productId ?? '';
        if (productId.isEmpty) continue;
        
        if (!productSales.containsKey(productId)) {
          productSales[productId] = {
            'productId': productId,
            'productName': item.productName ?? 'Unknown',
            'totalQty': 0,
            'totalAmount': 0.0,
          };
        }
        
        productSales[productId]!['totalQty'] = 
            (productSales[productId]!['totalQty'] as int) + item.quantity;
        productSales[productId]!['totalAmount'] = 
            (productSales[productId]!['totalAmount'] as double) + item.subtotal;
      }
    }
    
    // Sort by quantity and take top N
    final sorted = productSales.values.toList()
      ..sort((a, b) => (b['totalQty'] as int).compareTo(a['totalQty'] as int));
    
    return sorted.take(limit).toList();
  }

  /// Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts({int limit = 5}) async {
    final products = await ProductOfflineController.instance.getLowStockProducts();
    
    return products.take(limit).map((p) => {
      'id': p.serverId ?? p.id.toString(),
      'name': p.name,
      'currentStock': p.currentStock,
      'minStockLevel': p.minStockLevel ?? 10,
    }).toList();
  }

  /// Get customers with pending payments
  Future<List<Map<String, dynamic>>> getCustomersWithPendingBalance({int limit = 5}) async {
    final customers = await CustomerOfflineController.instance.getCustomersWithPendingBalance();
    
    return customers.take(limit).map((c) => {
      'id': c.serverId ?? c.id.toString(),
      'name': c.name,
      'currentPendingAmount': c.currentPendingAmount,
      'mobile': c.mobile,
    }).toList();
  }

  /// Get recent bills with pending amount
  Future<List<Map<String, dynamic>>> getRecentPendingBills({int limit = 5}) async {
    final bills = await BillOfflineController.instance.getPendingBills();
    
    return bills.take(limit).map((b) => {
      'id': b.serverId ?? b.id.toString(),
      'customerName': b.customerName ?? 'Unknown',
      'pendingAmount': b.pendingAmount,
      'billDate': b.billDate.toIso8601String(),
      'totalAmount': b.finalAmount,
    }).toList();
  }

  /// Get upcoming payment dues (purchases - just return empty for now since purchases don't have pending amounts)
  Future<List<Map<String, dynamic>>> getUpcomingPaymentDues({int limit = 5}) async {
    // For now, return supplier pending amounts if available
    // Purchases don't track pending amounts directly in this schema
    return [];
  }
}
