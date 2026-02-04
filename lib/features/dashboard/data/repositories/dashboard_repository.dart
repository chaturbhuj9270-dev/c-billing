import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dashboard_data.dart';

/// Repository for fetching dashboard data from Firestore
class DashboardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

  /// Fetch dashboard data with optional date filtering
  /// Uses parallel queries for maximum performance
  Future<DashboardData> fetchDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userRef = _userRef;
    if (userRef == null) {
      throw Exception('User not authenticated');
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

    return DashboardData(
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
}
