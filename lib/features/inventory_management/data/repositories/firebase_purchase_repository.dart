import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

class FirebasePurchaseRepository implements PurchaseRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'purchases';

  FirebasePurchaseRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<String> addPurchase(Purchase purchase) async {
    try {
      final docRef = await _firestore.collection(_collection).add(
            purchase.copyWith(id: '').toJson(),
          );
      
      // Update document with its ID
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add purchase: $e');
    }
  }

  @override
  Future<Purchase?> getPurchaseById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Purchase.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get purchase: $e');
    }
  }

  @override
  Future<List<Purchase>> getAllPurchases() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Purchase.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all purchases: $e');
    }
  }

  @override
  Future<List<Purchase>> getPurchasesByProductId(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Purchase.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get purchases by product id: $e');
    }
  }

  @override
  Future<List<Purchase>> getPurchasesByDateRange(
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
          .map((doc) => Purchase.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get purchases by date range: $e');
    }
  }

  @override
  Future<double> getTotalPurchaseAmount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      double total = 0;
      for (var doc in snapshot.docs) {
        final purchase = Purchase.fromJson(doc.data() as Map<String, dynamic>);
        total += purchase.totalAmount;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total purchase amount: $e');
    }
  }

  @override
  Future<int> getTotalPurchaseQuantity({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      int total = 0;
      for (var doc in snapshot.docs) {
        final purchase = Purchase.fromJson(doc.data() as Map<String, dynamic>);
        total += purchase.quantity;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total purchase quantity: $e');
    }
  }
}
