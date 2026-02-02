import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repositories/stock_repository.dart';

class FirebaseStockRepository implements StockRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'stock';

  FirebaseStockRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<String> createStockEntry(Stock stock) async {
    try {
      final docRef = await _firestore.collection(_collection).add(
            stock.copyWith(id: '').toJson(),
          );
      
      // Update document with its ID
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create stock entry: $e');
    }
  }

  @override
  Future<Stock?> getStockById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Stock.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get stock entry: $e');
    }
  }

  @override
  Future<List<Stock>> getStockByProductId(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Stock.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stock by product id: $e');
    }
  }

  @override
  Future<List<Stock>> getAllStockEntries() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Stock.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all stock entries: $e');
    }
  }

  @override
  Future<int> getCurrentBalance(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return 0;
      }
      
      final latestStock = Stock.fromJson(snapshot.docs.first.data());
      return latestStock.balanceQuantity;
    } catch (e) {
      throw Exception('Failed to get current balance: $e');
    }
  }

  @override
  Future<List<Stock>> getStockByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Stock.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stock by date range: $e');
    }
  }

  @override
  Future<List<Stock>> getStockByReferenceType(String referenceType) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('referenceType', isEqualTo: referenceType)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Stock.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stock by reference type: $e');
    }
  }
}
