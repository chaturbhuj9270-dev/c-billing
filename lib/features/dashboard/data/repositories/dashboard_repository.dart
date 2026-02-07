import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dashboard_data.dart';

/// Repository for fetching dashboard data from Firestore
class DashboardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // In-memory cache for dashboard data
  static DashboardData? _cachedData;
  static String? _cachedKey;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(seconds: 30);

  DashboardRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID or null if not authenticated
  String? get _userId => _auth.currentUser?.uid;

  /// Get user's collection reference
  DocumentReference? get _userRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId);
  }

  /// Generate cache key based on date range
  String _getCacheKey(DateTime? startDate, DateTime? endDate) {
    final userId = _userId ?? 'unknown';
    final start = startDate?.toIso8601String() ?? 'null';
    final end = endDate?.toIso8601String() ?? 'null';
    return '$userId-$start-$end';
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String cacheKey) {
    if (_cachedData == null ||
        _cachedKey != cacheKey ||
        _cacheTimestamp == null) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Clear the cache (call after data changes)
  static void invalidateCache() {
    _cachedData = null;
    _cachedKey = null;
    _cacheTimestamp = null;
  }

  /// Fetch dashboard data with optional date filtering
  /// Uses parallel queries for maximum performance
  /// Implements in-memory caching for faster repeated loads
  Future<DashboardData> fetchDashboardData({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final userRef = _userRef;
    if (userRef == null) {
      throw Exception('User not authenticated');
    }

    // Check cache first (unless force refresh)
    final cacheKey = _getCacheKey(startDate, endDate);
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      print('[DashboardRepository] Returning cached data');
      return _cachedData!;
    }

    final stopwatch = Stopwatch()..start();

    // Execute ALL queries in parallel for maximum speed
    final results = await Future.wait([
      // Counts (0-5)
      userRef.collection('bills').count().get(),
      userRef.collection('customers').count().get(),
      userRef.collection('products').count().get(),
      userRef.collection('suppliers').count().get(),
      userRef.collection('purchases').count().get(),
      userRef.collection('companies').count().get(),
      // Data queries (6-8)
      _getBillsForPeriod(userRef, startDate, endDate),
      _getPurchasesForPeriod(userRef, startDate, endDate),
      userRef.collection('products').get(),
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

    // Calculate sales data
    double totalSalesAmount = 0;
    int totalItemsSold = 0;
    for (var doc in billsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalSalesAmount += (data['totalAmount'] as num?)?.toDouble() ?? 0;
        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          totalItemsSold += (item['quantity'] as num?)?.toInt() ?? 0;
        }
      }
    }

    // Calculate purchase data
    double totalPurchaseAmount = 0;
    int totalPurchaseQty = 0;
    for (var doc in purchasesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalPurchaseAmount += (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalPurchaseQty += (data['quantity'] as num?)?.toInt() ?? 0;
      }
    }

    // Calculate stock data
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

    // Calculate profit
    final profit = totalSalesAmount - totalPurchaseAmount;
    final profitPercentage = totalSalesAmount > 0
        ? (profit / totalSalesAmount) * 100
        : 0.0;

    stopwatch.stop();
    print(
      '[DashboardRepository] Data loaded in ${stopwatch.elapsedMilliseconds}ms',
    );

    final data = DashboardData(
      invoicesCount: invoicesCount,
      clientsCount: clientsCount,
      productsCount: productsCount,
      suppliersCount: suppliersCount,
      purchasesCount: purchasesCount,
      companiesCount: companiesCount,
      inventoryCount: productsCount,
      totalSales: totalSalesAmount,
      totalBillsCount: billsSnapshot.docs.length,
      totalItemsSold: totalItemsSold,
      totalPurchases: totalPurchaseAmount,
      purchaseOrders: purchasesSnapshot.docs.length,
      purchaseQty: totalPurchaseQty,
      profit: profit,
      profitPercentage: profitPercentage,
      stockValue: stockValue,
      lowStockCount: lowStockCount,
    );

    // Store in cache
    _cachedData = data;
    _cachedKey = cacheKey;
    _cacheTimestamp = DateTime.now();

    return data;
  }

  /// Get bills with optional date filtering
  Future<QuerySnapshot> _getBillsForPeriod(
    DocumentReference userRef,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    Query query = userRef.collection('bills');

    if (startDate != null) {
      query = query.where(
        'billDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'billDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.get();
  }

  /// Get purchases with optional date filtering
  Future<QuerySnapshot> _getPurchasesForPeriod(
    DocumentReference userRef,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    Query query = userRef.collection('purchases');

    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.get();
  }

  /// Get customers with pending balance (for pending payments section)
  Future<List<Map<String, dynamic>>> getCustomersWithPendingBalance({
    int limit = 5,
  }) async {
    final userRef = _userRef;
    if (userRef == null) return [];

    try {
      final snapshot = await userRef
          .collection('customers')
          .where('isActive', isEqualTo: true)
          .where('currentPendingAmount', isGreaterThan: 0)
          .orderBy('currentPendingAmount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[DashboardRepository] Error fetching pending customers: $e');
      return [];
    }
  }

  /// Get recent bills with pending amount (for last dues section)
  Future<List<Map<String, dynamic>>> getRecentPendingBills({
    int limit = 5,
  }) async {
    final userRef = _userRef;
    if (userRef == null) return [];

    try {
      final snapshot = await userRef
          .collection('bills')
          .where('pendingAmount', isGreaterThan: 0)
          .orderBy('pendingAmount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // Fallback: get bills without ordering if index not available
      try {
        final snapshot = await userRef
            .collection('bills')
            .orderBy('billDate', descending: true)
            .limit(20)
            .get();

        final bills = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            })
            .where((bill) => ((bill['pendingAmount'] ?? 0) as num) > 0)
            .take(limit)
            .toList();

        return bills;
      } catch (e2) {
        print('[DashboardRepository] Error fetching pending bills: $e2');
        return [];
      }
    }
  }

  /// Get top selling products (for top products section)
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 5,
  }) async {
    final userRef = _userRef;
    if (userRef == null) return [];

    try {
      // Get bills from last 30 days for top products
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await userRef
          .collection('bills')
          .where(
            'billDate',
            isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String(),
          )
          .get();

      // Aggregate sales by product
      final productSales = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final productId = item['productId'] as String? ?? '';
          final productName =
              item['productName'] as String? ?? 'Unknown Product';
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

          if (productId.isEmpty) continue;

          if (!productSales.containsKey(productId)) {
            productSales[productId] = {
              'productId': productId,
              'productName': productName,
              'totalQuantity': 0,
              'totalRevenue': 0.0,
            };
          }

          productSales[productId]!['totalQuantity'] += quantity;
          productSales[productId]!['totalRevenue'] += subtotal;
        }
      }

      // Sort by revenue and return top items
      final sortedProducts = productSales.values.toList()
        ..sort(
          (a, b) => (b['totalRevenue'] as double).compareTo(
            a['totalRevenue'] as double,
          ),
        );

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('[DashboardRepository] Error fetching top products: $e');
      return [];
    }
  }

  /// Get low stock products (for order now section)
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int limit = 5,
    int threshold = 10,
  }) async {
    final userRef = _userRef;
    if (userRef == null) return [];

    try {
      final snapshot = await userRef
          .collection('products')
          .where('currentStock', isLessThan: threshold)
          .where('currentStock', isGreaterThan: 0)
          .orderBy('currentStock')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // Fallback if index not available
      try {
        final snapshot = await userRef.collection('products').get();
        final products = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            })
            .where((p) {
              final stock = (p['currentStock'] as num?)?.toInt() ?? 0;
              return stock > 0 && stock < threshold;
            })
            .toList();

        products.sort(
          (a, b) => ((a['currentStock'] as num?) ?? 0).compareTo(
            (b['currentStock'] as num?) ?? 0,
          ),
        );

        return products.take(limit).toList();
      } catch (e2) {
        print('[DashboardRepository] Error fetching low stock products: $e2');
        return [];
      }
    }
  }

  /// Get upcoming payment dues (bills due in next 7 days)
  Future<List<Map<String, dynamic>>> getUpcomingPaymentDues({
    int limit = 5,
  }) async {
    final userRef = _userRef;
    if (userRef == null) return [];

    try {
      // Get all pending bills and filter by customer's payment pattern
      // For now, get recent pending bills as "upcoming"
      final snapshot = await userRef
          .collection('bills')
          .where('paymentStatus', whereIn: ['pending', 'partiallyPaid'])
          .orderBy('billDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // Fallback
      try {
        final snapshot = await userRef
            .collection('bills')
            .orderBy('billDate', descending: true)
            .limit(20)
            .get();

        final pendingBills = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            })
            .where((bill) {
              final status = bill['paymentStatus'] as String?;
              return status == 'pending' || status == 'partiallyPaid';
            })
            .take(limit)
            .toList();

        return pendingBills;
      } catch (e2) {
        print('[DashboardRepository] Error fetching upcoming payments: $e2');
        return [];
      }
    }
  }
}
