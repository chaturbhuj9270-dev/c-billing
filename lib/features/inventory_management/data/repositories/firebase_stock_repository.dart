import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repositories/stock_repository.dart';

class FirebaseStockRepository implements StockRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'stock';

  FirebaseStockRepository({
    required FirebaseFirestore firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _stockCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(_collection);
  }

  @override
  Future<String> createStockEntry(Stock stock) async {
    try {
      final docRef = await _stockCollection.add(
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
      final doc = await _stockCollection.doc(id).get();
      if (doc.exists) {
        return Stock.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get stock entry: $e');
    }
  }

  @override
  Future<List<Stock>> getStockByProductId(String productId) async {
    try {
      try {
        final snapshot = await _stockCollection
            .where('productId', isEqualTo: productId)
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _stockCollection
              .where('productId', isEqualTo: productId)
              .get();
          final stocks = snapshot.docs
              .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stocks;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get stock by product id: $e');
    }
  }

  @override
  Future<List<Stock>> getAllStockEntries() async {
    try {
      try {
        final snapshot = await _stockCollection
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _stockCollection.get();
          final stocks = snapshot.docs
              .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stocks;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get all stock entries: $e');
    }
  }

  @override
  Future<int> getCurrentBalance(String productId) async {
    try {
      try {
        final snapshot = await _stockCollection
            .where('productId', isEqualTo: productId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        if (snapshot.docs.isEmpty) {
          return 0;
        }
        
        final latestStock = Stock.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
        return latestStock.balanceQuantity;
      } catch (e) {
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _stockCollection
              .where('productId', isEqualTo: productId)
              .get();
          
          if (snapshot.docs.isEmpty) {
            return 0;
          }
          
          final stocks = snapshot.docs
              .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stocks.first.balanceQuantity;
        }
        throw e;
      }
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
      try {
        final snapshot = await _stockCollection
            .where('createdAt',
                isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _stockCollection
              .where('createdAt',
                  isGreaterThanOrEqualTo: startDate.toIso8601String())
              .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
              .get();
          final stocks = snapshot.docs
              .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stocks;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get stock by date range: $e');
    }
  }

  @override
  Future<List<Stock>> getStockByReferenceType(String referenceType) async {
    try {
      try {
        final snapshot = await _stockCollection
            .where('referenceType', isEqualTo: referenceType)
            .orderBy('createdAt', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          final snapshot = await _stockCollection
              .where('referenceType', isEqualTo: referenceType)
              .get();
          final stocks = snapshot.docs
              .map((doc) => Stock.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stocks;
        }
        throw e;
      }
    } catch (e) {
      throw Exception('Failed to get stock by reference type: $e');
    }
  }
}
