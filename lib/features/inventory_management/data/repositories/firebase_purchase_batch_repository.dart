import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/purchase_batch.dart';
import '../../domain/repositories/purchase_batch_repository.dart';

/// Firebase implementation of PurchaseBatchRepository
class FirebasePurchaseBatchRepository implements PurchaseBatchRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collection = 'purchaseBatches';

  FirebasePurchaseBatchRepository({
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

  CollectionReference get _batchesCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(_collection);
  }

  @override
  Future<String> addBatch(PurchaseBatch batch) async {
    try {
      final docRef = await _batchesCollection.add(batch.toJson());
      await docRef.update({'batchId': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add batch: $e');
    }
  }

  @override
  Future<PurchaseBatch?> getBatchById(String batchId) async {
    try {
      final doc = await _batchesCollection.doc(batchId).get();
      if (doc.exists) {
        return PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get batch: $e');
    }
  }

  @override
  Future<List<PurchaseBatch>> getAllBatches({bool includeConsumed = false}) async {
    try {
      Query query = _batchesCollection;
      
      if (!includeConsumed) {
        query = query.where('isConsumed', isEqualTo: false);
      }
      
      final snapshot = await query.orderBy('purchaseDate').get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback if index doesn't exist
      final snapshot = await _batchesCollection.get();
      var batches = snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      if (!includeConsumed) {
        batches = batches.where((b) => !b.isConsumed).toList();
      }
      
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
  }

  @override
  Future<List<PurchaseBatch>> getBatchesByProductId(
    String productId, {
    bool onlyWithStock = true,
  }) async {
    try {
      Query query = _batchesCollection.where('productId', isEqualTo: productId);
      
      if (onlyWithStock) {
        query = query.where('quantityRemaining', isGreaterThan: 0);
      }
      
      final snapshot = await query.orderBy('purchaseDate').get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback
      final snapshot = await _batchesCollection
          .where('productId', isEqualTo: productId)
          .get();
      
      var batches = snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      if (onlyWithStock) {
        batches = batches.where((b) => b.quantityRemaining > 0).toList();
      }
      
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
  }

  @override
  Future<List<PurchaseBatch>> getBatchesByProductUniqueKey(
    String productUniqueKey, {
    bool onlyWithStock = true,
  }) async {
    try {
      Query query = _batchesCollection.where('productUniqueKey', isEqualTo: productUniqueKey);
      
      if (onlyWithStock) {
        query = query.where('quantityRemaining', isGreaterThan: 0);
      }
      
      final snapshot = await query.orderBy('purchaseDate').get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback
      final snapshot = await _batchesCollection
          .where('productUniqueKey', isEqualTo: productUniqueKey)
          .get();
      
      var batches = snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      if (onlyWithStock) {
        batches = batches.where((b) => b.quantityRemaining > 0).toList();
      }
      
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
  }

  @override
  Future<List<PurchaseBatch>> getAvailableBatchesForProduct(String productId) async {
    return getBatchesByProductId(productId, onlyWithStock: true);
  }

  @override
  Future<List<PurchaseBatch>> getBatchesBySupplierId(String supplierId) async {
    try {
      final snapshot = await _batchesCollection
          .where('supplierId', isEqualTo: supplierId)
          .orderBy('purchaseDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _batchesCollection
          .where('supplierId', isEqualTo: supplierId)
          .get();
      final batches = snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      batches.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      return batches;
    }
  }

  @override
  Future<List<PurchaseBatch>> getBatchesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _batchesCollection
          .where('purchaseDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('purchaseDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('purchaseDate')
          .get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _batchesCollection.get();
      final batches = snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .where((b) => 
              !b.purchaseDate.isBefore(startDate) && 
              !b.purchaseDate.isAfter(endDate))
          .toList();
      batches.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return batches;
    }
  }

  @override
  Future<List<PurchaseBatch>> getBatchesExpiringSoon({int withinDays = 30}) async {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: withinDays));
    
    try {
      final snapshot = await _batchesCollection
          .where('expiryDate', isGreaterThanOrEqualTo: now.toIso8601String())
          .where('expiryDate', isLessThanOrEqualTo: deadline.toIso8601String())
          .where('quantityRemaining', isGreaterThan: 0)
          .get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _batchesCollection.get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .where((b) => 
              b.expiryDate != null &&
              b.expiryDate!.isAfter(now) &&
              b.expiryDate!.isBefore(deadline) &&
              b.quantityRemaining > 0)
          .toList();
    }
  }

  @override
  Future<List<PurchaseBatch>> getExpiredBatches() async {
    final now = DateTime.now();
    
    try {
      final snapshot = await _batchesCollection
          .where('expiryDate', isLessThan: now.toIso8601String())
          .where('quantityRemaining', isGreaterThan: 0)
          .get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final snapshot = await _batchesCollection.get();
      return snapshot.docs
          .map((doc) => PurchaseBatch.fromJson(doc.data() as Map<String, dynamic>))
          .where((b) => 
              b.expiryDate != null &&
              b.expiryDate!.isBefore(now) &&
              b.quantityRemaining > 0)
          .toList();
    }
  }

  @override
  Future<void> updateBatch(PurchaseBatch batch) async {
    try {
      await _batchesCollection.doc(batch.batchId).update(batch.toJson());
    } catch (e) {
      throw Exception('Failed to update batch: $e');
    }
  }

  @override
  Future<PurchaseBatch> deductFromBatch(String batchId, int quantity) async {
    try {
      final batch = await getBatchById(batchId);
      if (batch == null) {
        throw Exception('Batch not found: $batchId');
      }
      
      if (batch.quantityRemaining < quantity) {
        throw Exception(
          'Insufficient stock in batch. Available: ${batch.quantityRemaining}, Requested: $quantity'
        );
      }
      
      final newRemaining = batch.quantityRemaining - quantity;
      final updatedBatch = batch.copyWith(
        quantityRemaining: newRemaining,
        isConsumed: newRemaining <= 0,
        updatedAt: DateTime.now(),
      );
      
      await updateBatch(updatedBatch);
      return updatedBatch;
    } catch (e) {
      throw Exception('Failed to deduct from batch: $e');
    }
  }

  @override
  Future<PurchaseBatch> addToBatch(String batchId, int quantity) async {
    try {
      final batch = await getBatchById(batchId);
      if (batch == null) {
        throw Exception('Batch not found: $batchId');
      }
      
      final newRemaining = batch.quantityRemaining + quantity;
      final updatedBatch = batch.copyWith(
        quantityRemaining: newRemaining,
        isConsumed: false,
        updatedAt: DateTime.now(),
      );
      
      await updateBatch(updatedBatch);
      return updatedBatch;
    } catch (e) {
      throw Exception('Failed to add to batch: $e');
    }
  }

  @override
  Future<void> markBatchAsConsumed(String batchId) async {
    try {
      await _batchesCollection.doc(batchId).update({
        'quantityRemaining': 0,
        'isConsumed': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark batch as consumed: $e');
    }
  }

  @override
  Future<void> deleteBatch(String batchId) async {
    try {
      await _batchesCollection.doc(batchId).delete();
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }

  @override
  Future<int> getTotalStockByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    return batches.fold<int>(0, (sum, b) => sum + b.quantityRemaining);
  }

  @override
  Future<int> getTotalStockByProductUniqueKey(String productUniqueKey) async {
    final batches = await getBatchesByProductUniqueKey(productUniqueKey, onlyWithStock: true);
    return batches.fold<int>(0, (sum, b) => sum + b.quantityRemaining);
  }

  @override
  Future<double> getTotalStockValueByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    return batches.fold<double>(0.0, (sum, b) => sum + (b.quantityRemaining * b.purchasePrice));
  }

  @override
  Future<double> getWeightedAverageCost(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: true);
    if (batches.isEmpty) return 0.0;
    
    final totalValue = batches.fold<double>(0.0, (sum, b) => sum + (b.quantityRemaining * b.purchasePrice));
    final totalQty = batches.fold<int>(0, (sum, b) => sum + b.quantityRemaining);
    
    return totalQty > 0 ? totalValue / totalQty : 0.0;
  }

  @override
  Future<Map<String, int>> getAllProductsWithStock() async {
    final batches = await getAllBatches(includeConsumed: false);
    final stockMap = <String, int>{};
    
    for (final batch in batches) {
      final current = stockMap[batch.productId] ?? 0;
      stockMap[batch.productId] = current + batch.quantityRemaining;
    }
    
    return stockMap;
  }

  @override
  Future<int> getBatchCountByProductId(String productId) async {
    final batches = await getBatchesByProductId(productId, onlyWithStock: false);
    return batches.length;
  }
}
