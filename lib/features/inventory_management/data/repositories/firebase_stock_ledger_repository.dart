import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/stock_ledger.dart';
import '../../domain/repositories/stock_ledger_repository.dart';

/// Firebase implementation of StockLedgerRepository
class FirebaseStockLedgerRepository implements StockLedgerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'stockLedger';

  FirebaseStockLedgerRepository({
    required FirebaseFirestore firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore,
       _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _ledgerCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(_collection);
  }

  @override
  Future<String> createLedgerEntry(StockLedger entry) async {
    try {
      final docRef = await _ledgerCollection.add(entry.toJson());
      await docRef.update({'ledgerId': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ledger entry: $e');
    }
  }

  @override
  Future<List<String>> createLedgerEntries(List<StockLedger> entries) async {
    try {
      final batch = _firestore.batch();
      final ids = <String>[];
      
      for (final entry in entries) {
        final docRef = _ledgerCollection.doc();
        ids.add(docRef.id);
        batch.set(docRef, {
          ...entry.toJson(),
          'ledgerId': docRef.id,
        });
      }
      
      await batch.commit();
      return ids;
    } catch (e) {
      throw Exception('Failed to create ledger entries: $e');
    }
  }

  @override
  Future<StockLedger?> getLedgerById(String ledgerId) async {
    try {
      final doc = await _ledgerCollection.doc(ledgerId).get();
      if (doc.exists) {
        return StockLedger.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ledger entry: $e');
    }
  }

  @override
  Future<List<StockLedger>> getAllLedgerEntries() async {
    try {
      final snapshot = await _ledgerCollection
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection.get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    }
  }

  @override
  Future<List<StockLedger>> getLedgerByProductId(String productId) async {
    try {
      final snapshot = await _ledgerCollection
          .where('productId', isEqualTo: productId)
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection
          .where('productId', isEqualTo: productId)
          .get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    }
  }

  @override
  Future<List<StockLedger>> getLedgerByProductUniqueKey(String productUniqueKey) async {
    try {
      final snapshot = await _ledgerCollection
          .where('productUniqueKey', isEqualTo: productUniqueKey)
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection
          .where('productUniqueKey', isEqualTo: productUniqueKey)
          .get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    }
  }

  @override
  Future<List<StockLedger>> getLedgerByBatchId(String batchId) async {
    try {
      final snapshot = await _ledgerCollection
          .where('batchId', isEqualTo: batchId)
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection
          .where('batchId', isEqualTo: batchId)
          .get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    }
  }

  @override
  Future<List<StockLedger>> getLedgerByReferenceId(String referenceId) async {
    try {
      final snapshot = await _ledgerCollection
          .where('referenceId', isEqualTo: referenceId)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get ledger by reference: $e');
    }
  }

  @override
  Future<List<StockLedger>> getLedgerByType(LedgerType type) async {
    try {
      final snapshot = await _ledgerCollection
          .where('ledgerType', isEqualTo: type.toShortString())
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection
          .where('ledgerType', isEqualTo: type.toShortString())
          .get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    }
  }

  @override
  Future<List<StockLedger>> getLedgerByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _ledgerCollection
          .where('transactionDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('transactionDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('transactionDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection.get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .where((e) => 
              !e.transactionDate.isBefore(startDate) && 
              !e.transactionDate.isAfter(endDate))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    }
  }

  @override
  Future<List<StockLedger>> getRecentLedgerEntries({int limit = 50}) async {
    try {
      final snapshot = await _ledgerCollection
          .orderBy('transactionDate', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _ledgerCollection.get();
      final entries = snapshot.docs
          .map((doc) => StockLedger.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries.take(limit).toList();
    }
  }

  @override
  Future<double> getTotalCOGS({DateTime? startDate, DateTime? endDate}) async {
    final entries = await _getSaleEntries(startDate: startDate, endDate: endDate);
    return entries.fold<double>(0.0, (sum, e) => sum + e.totalCost);
  }

  @override
  Future<Map<String, double>> getCOGSByProduct({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await _getSaleEntries(startDate: startDate, endDate: endDate);
    final cogsMap = <String, double>{};
    
    for (final entry in entries) {
      final current = cogsMap[entry.productId] ?? 0.0;
      cogsMap[entry.productId] = current + entry.totalCost;
    }
    
    return cogsMap;
  }

  @override
  Future<double> getTotalProfit({DateTime? startDate, DateTime? endDate}) async {
    final entries = await _getSaleAndReturnEntries(startDate: startDate, endDate: endDate);
    return entries.fold<double>(0.0, (sum, e) => sum + e.profit);
  }

  @override
  Future<Map<String, double>> getProfitByProduct({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await _getSaleAndReturnEntries(startDate: startDate, endDate: endDate);
    final profitMap = <String, double>{};
    
    for (final entry in entries) {
      final current = profitMap[entry.productId] ?? 0.0;
      profitMap[entry.productId] = current + entry.profit;
    }
    
    return profitMap;
  }

  @override
  Future<double> getTotalRevenue({DateTime? startDate, DateTime? endDate}) async {
    final entries = await _getSaleEntries(startDate: startDate, endDate: endDate);
    return entries.fold<double>(0.0, (sum, e) => sum + e.totalRevenue);
  }

  @override
  Future<double> getTotalPurchaseValue({DateTime? startDate, DateTime? endDate}) async {
    final entries = await getLedgerByType(LedgerType.PURCHASE);
    
    var filtered = entries;
    if (startDate != null && endDate != null) {
      filtered = entries.where((e) =>
          !e.transactionDate.isBefore(startDate) &&
          !e.transactionDate.isAfter(endDate)).toList();
    }
    
    return filtered.fold<double>(0.0, (sum, e) => sum + e.totalCost);
  }

  @override
  Future<int> getCurrentBalance(String productId) async {
    final entries = await getLedgerByProductId(productId);
    if (entries.isEmpty) return 0;
    
    // Get the latest entry for balance
    return entries.first.balanceQuantity;
  }

  @override
  Future<double> getCurrentStockValue(String productId) async {
    final entries = await getLedgerByProductId(productId);
    if (entries.isEmpty) return 0.0;
    
    return entries.first.balanceValue;
  }

  @override
  Future<Map<String, dynamic>> getStockMovementSummary(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var entries = await getLedgerByProductId(productId);
    
    if (startDate != null && endDate != null) {
      entries = entries.where((e) =>
          !e.transactionDate.isBefore(startDate) &&
          !e.transactionDate.isAfter(endDate)).toList();
    }
    
    int totalIn = 0;
    int totalOut = 0;
    double totalCost = 0.0;
    double totalRevenue = 0.0;
    double totalProfit = 0.0;
    
    for (final entry in entries) {
      if (entry.ledgerType.isInbound) {
        totalIn += entry.quantity;
      } else if (entry.ledgerType.isOutbound) {
        totalOut += entry.quantity;
      }
      
      if (entry.ledgerType == LedgerType.SALE) {
        totalCost += entry.totalCost;
        totalRevenue += entry.totalRevenue;
        totalProfit += entry.profit;
      }
    }
    
    return {
      'productId': productId,
      'totalIn': totalIn,
      'totalOut': totalOut,
      'netMovement': totalIn - totalOut,
      'totalCOGS': totalCost,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'transactionCount': entries.length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getInventoryValuationReport() async {
    final entries = await getAllLedgerEntries();
    
    // Group by product and get latest balance
    final productMap = <String, Map<String, dynamic>>{};
    
    for (final entry in entries.reversed) {
      productMap[entry.productId] = {
        'productId': entry.productId,
        'productName': entry.productName,
        'companyName': entry.companyName,
        'currentQuantity': entry.balanceQuantity,
        'currentValue': entry.balanceValue,
      };
    }
    
    return productMap.values.toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getStockMovementReport({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
  }) async {
    List<StockLedger> entries;
    
    if (productId != null) {
      entries = await getLedgerByProductId(productId);
    } else if (startDate != null && endDate != null) {
      entries = await getLedgerByDateRange(startDate, endDate);
    } else {
      entries = await getAllLedgerEntries();
    }
    
    return entries.map((e) => e.toJson()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getCOGSReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cogsMap = await getCOGSByProduct(startDate: startDate, endDate: endDate);
    
    return cogsMap.entries.map((e) => {
      'productId': e.key,
      'totalCOGS': e.value,
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getProfitReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final profitMap = await getProfitByProduct(startDate: startDate, endDate: endDate);
    
    return profitMap.entries.map((e) => {
      'productId': e.key,
      'totalProfit': e.value,
    }).toList();
  }

  // Helper methods
  Future<List<StockLedger>> _getSaleEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var entries = await getLedgerByType(LedgerType.SALE);
    
    if (startDate != null && endDate != null) {
      entries = entries.where((e) =>
          !e.transactionDate.isBefore(startDate) &&
          !e.transactionDate.isAfter(endDate)).toList();
    }
    
    return entries;
  }

  Future<List<StockLedger>> _getSaleAndReturnEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sales = await getLedgerByType(LedgerType.SALE);
    final returns = await getLedgerByType(LedgerType.SALE_RETURN);
    
    var entries = [...sales, ...returns];
    
    if (startDate != null && endDate != null) {
      entries = entries.where((e) =>
          !e.transactionDate.isBefore(startDate) &&
          !e.transactionDate.isAfter(endDate)).toList();
    }
    
    return entries;
  }
}
