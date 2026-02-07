import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';

/// Firebase datasource for dashboard data
/// Optimized for minimal reads using parallel queries and Firestore caching
class DashboardFirebaseDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DashboardFirebaseDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get user's document reference
  DocumentReference? get _userRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId);
  }

  /// Fetch dashboard data from Firebase
  /// Uses parallel queries for maximum performance
  /// Leverages Firestore's built-in cache with Source.serverAndCache
  Future<DashboardSummary> fetchDashboardData({
    required DashboardParams params,
    bool forceNetwork = false,
  }) async {
    final userRef = _userRef;
    if (userRef == null) {
      throw Exception('User not authenticated');
    }

    final stopwatch = Stopwatch()..start();
    final (startDate, endDate) = params.getDateRange();

    // Debug: Log date range being queried
    print(
      '[DashboardFirebaseDataSource] Fetching data for filter: ${params.filter}',
    );
    print('[DashboardFirebaseDataSource] Date range: $startDate to $endDate');

    // Use cache source unless forced to network
    // Note: AggregateSource only supports server, but regular queries support cache
    final source = forceNetwork ? Source.server : Source.serverAndCache;

    try {
      // Execute ALL queries in parallel for maximum speed
      final results = await Future.wait([
        // Count aggregations (0-5) - always from server but very fast
        userRef.collection('bills').count().get(),
        userRef.collection('customers').count().get(),
        userRef.collection('products').count().get(),
        userRef.collection('suppliers').count().get(),
        userRef.collection('purchases').count().get(),
        userRef.collection('companies').count().get(),
        // Data queries with date filtering (6-8) - can use cache
        _getBillsForPeriod(userRef, startDate, endDate, source),
        _getPurchasesForPeriod(userRef, startDate, endDate, source),
        _getProductsSnapshot(userRef, source),
      ]);

      // Extract count results
      final invoicesCount = (results[0] as AggregateQuerySnapshot).count ?? 0;
      final clientsCount = (results[1] as AggregateQuerySnapshot).count ?? 0;
      final productsCount = (results[2] as AggregateQuerySnapshot).count ?? 0;
      final suppliersCount = (results[3] as AggregateQuerySnapshot).count ?? 0;
      final purchasesCount = (results[4] as AggregateQuerySnapshot).count ?? 0;
      final companiesCount = (results[5] as AggregateQuerySnapshot).count ?? 0;

      // Extract query results
      final billsSnapshot = results[6] as QuerySnapshot;
      final purchasesSnapshot = results[7] as QuerySnapshot;
      final productsSnapshot = results[8] as QuerySnapshot;

      // Debug: Log document counts
      print(
        '[DashboardFirebaseDataSource] Bills found: ${billsSnapshot.docs.length}',
      );
      print(
        '[DashboardFirebaseDataSource] Purchases found: ${purchasesSnapshot.docs.length}',
      );

      // Calculate metrics in a single pass
      final salesMetrics = _calculateSalesMetrics(billsSnapshot);
      final purchaseMetrics = _calculatePurchaseMetrics(purchasesSnapshot);
      final stockMetrics = _calculateStockMetrics(productsSnapshot);

      // Debug: Log calculated metrics
      print(
        '[DashboardFirebaseDataSource] Total Sales: ${salesMetrics.totalAmount}',
      );
      print(
        '[DashboardFirebaseDataSource] Total Purchases: ${purchaseMetrics.totalAmount}',
      );
      print(
        '[DashboardFirebaseDataSource] Profit: ${salesMetrics.totalProfit}',
      );

      // Use profit calculated from sales (sale price after discount - purchase price)
      final profit = salesMetrics.totalProfit;
      final profitPercentage = salesMetrics.totalAmount > 0
          ? (profit / salesMetrics.totalAmount) * 100
          : 0.0;

      stopwatch.stop();
      print(
        '[DashboardFirebaseDataSource] Data loaded in ${stopwatch.elapsedMilliseconds}ms',
      );

      return DashboardSummary(
        invoicesCount: invoicesCount,
        clientsCount: clientsCount,
        productsCount: productsCount,
        suppliersCount: suppliersCount,
        purchasesCount: purchasesCount,
        companiesCount: companiesCount,
        totalSales: salesMetrics.totalAmount,
        totalBillsCount: salesMetrics.count,
        totalItemsSold: salesMetrics.itemCount,
        totalPurchases: purchaseMetrics.totalAmount,
        purchaseOrders: purchaseMetrics.count,
        purchaseQty: purchaseMetrics.itemCount,
        profit: profit,
        profitPercentage: profitPercentage,
        stockValue: stockMetrics.stockValue,
        lowStockCount: stockMetrics.lowStockCount,
        lastUpdated: DateTime.now(),
        isFromCache: false,
      );
    } catch (e) {
      print('[DashboardFirebaseDataSource] Error: $e');
      rethrow;
    }
  }

  /// Stream dashboard data using Firestore snapshots for real-time updates
  Stream<DashboardSummary> watchDashboardData({
    required DashboardParams params,
  }) async* {
    final userRef = _userRef;
    if (userRef == null) {
      throw Exception('User not authenticated');
    }

    // First emit cached data if available (handled by repository)
    // Then stream real-time updates

    // For simplicity, we'll poll every 30 seconds
    // In production, consider using Firestore snapshots for specific collections
    while (true) {
      try {
        yield await fetchDashboardData(params: params);
        await Future.delayed(const Duration(seconds: 30));
      } catch (e) {
        print('[DashboardFirebaseDataSource] Stream error: $e');
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  /// Get bills with optional date filtering
  /// Note: billDate is stored as ISO8601 string in Firestore
  Future<QuerySnapshot> _getBillsForPeriod(
    DocumentReference userRef,
    DateTime? startDate,
    DateTime? endDate,
    Source source,
  ) async {
    Query query = userRef.collection('bills');

    if (startDate != null) {
      query = query.where(
        'billDate',
        isGreaterThanOrEqualTo: startDate.toIso8601String(),
      );
    }
    if (endDate != null) {
      query = query.where(
        'billDate',
        isLessThanOrEqualTo: endDate.toIso8601String(),
      );
    }

    return query.get(GetOptions(source: source));
  }

  /// Get purchases with optional date filtering
  /// Note: createdAt is stored as ISO8601 string in Firestore
  Future<QuerySnapshot> _getPurchasesForPeriod(
    DocumentReference userRef,
    DateTime? startDate,
    DateTime? endDate,
    Source source,
  ) async {
    Query query = userRef.collection('purchases');

    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: startDate.toIso8601String(),
      );
    }
    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: endDate.toIso8601String(),
      );
    }

    return query.get(GetOptions(source: source));
  }

  /// Get products snapshot
  Future<QuerySnapshot> _getProductsSnapshot(
    DocumentReference userRef,
    Source source,
  ) async {
    return userRef.collection('products').get(GetOptions(source: source));
  }

  /// Calculate sales metrics from bills snapshot
  /// Uses finalAmount (after discount) for total sales
  /// Calculates profit as: (selling price - purchase price) * quantity - discount portion
  _SalesMetrics _calculateSalesMetrics(QuerySnapshot billsSnapshot) {
    double totalAmount = 0; // Total after discounts (finalAmount)
    double totalProfit = 0;
    int itemCount = 0;

    for (var doc in billsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        // Use finalAmount if available (accounts for discounts), fallback to totalAmount
        final finalAmount = (data['finalAmount'] as num?)?.toDouble();
        final billTotalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalAmount += finalAmount ?? billTotalAmount;

        // Calculate discount ratio for this bill
        final discountAmount =
            (data['discountAmount'] as num?)?.toDouble() ?? 0;
        final discountRatio = billTotalAmount > 0
            ? discountAmount / billTotalAmount
            : 0.0;

        // Process items to calculate profit
        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          final sellingPrice = (item['sellingPrice'] as num?)?.toDouble() ?? 0;
          final purchasePrice =
              (item['purchasePrice'] as num?)?.toDouble() ?? 0;
          final subtotal =
              (item['subtotal'] as num?)?.toDouble() ??
              (sellingPrice * quantity);

          itemCount += quantity;

          // Profit = (selling price - purchase price) * quantity - proportional discount
          final itemRevenue = subtotal;
          final itemCost = purchasePrice * quantity;
          final itemDiscountPortion = itemRevenue * discountRatio;
          final itemProfit = itemRevenue - itemDiscountPortion - itemCost;
          totalProfit += itemProfit;
        }
      }
    }

    return _SalesMetrics(
      totalAmount: totalAmount,
      count: billsSnapshot.docs.length,
      itemCount: itemCount,
      totalProfit: totalProfit,
    );
  }

  /// Calculate purchase metrics from purchases snapshot
  _PurchaseMetrics _calculatePurchaseMetrics(QuerySnapshot purchasesSnapshot) {
    double totalAmount = 0;
    int itemCount = 0;

    for (var doc in purchasesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalAmount += (data['totalAmount'] as num?)?.toDouble() ?? 0;
        itemCount += (data['quantity'] as num?)?.toInt() ?? 0;
      }
    }

    return _PurchaseMetrics(
      totalAmount: totalAmount,
      count: purchasesSnapshot.docs.length,
      itemCount: itemCount,
    );
  }

  /// Calculate stock metrics from products snapshot
  _StockMetrics _calculateStockMetrics(QuerySnapshot productsSnapshot) {
    double stockValue = 0;
    int lowStockCount = 0;

    for (var doc in productsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
      final purchasePrice = (data['purchasePrice'] as num?)?.toDouble() ?? 0;
      stockValue += currentStock * purchasePrice;
      if (currentStock < 10 && currentStock > 0) {
        lowStockCount++;
      }
    }

    return _StockMetrics(stockValue: stockValue, lowStockCount: lowStockCount);
  }
}

/// Internal class for sales metrics calculation
class _SalesMetrics {
  final double totalAmount;
  final int count;
  final int itemCount;
  final double totalProfit;

  _SalesMetrics({
    required this.totalAmount,
    required this.count,
    required this.itemCount,
    required this.totalProfit,
  });
}

/// Internal class for purchase metrics calculation
class _PurchaseMetrics {
  final double totalAmount;
  final int count;
  final int itemCount;

  _PurchaseMetrics({
    required this.totalAmount,
    required this.count,
    required this.itemCount,
  });
}

/// Internal class for stock metrics calculation
class _StockMetrics {
  final double stockValue;
  final int lowStockCount;

  _StockMetrics({required this.stockValue, required this.lowStockCount});
}
