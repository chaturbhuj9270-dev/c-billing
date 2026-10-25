import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/core/access/tenant_context.dart';
import '../../domain/entities/purchase_return.dart';

// Firebase repository for Purchase Return CRUD operations
class FirebasePurchaseReturnRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'purchaseReturns';

  FirebasePurchaseReturnRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _userId => TenantContext.dataOwnerId;

  CollectionReference get _returnsCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(_collection);
  }

  // Create a new purchase return
  Future<String> createReturn(PurchaseReturn purchaseReturn) async {
    try {
      final docRef = await _returnsCollection.add(purchaseReturn.toJson());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create purchase return: $e');
    }
  }

  // Get all purchase returns (sorted by date desc)
  Future<List<PurchaseReturn>> getAllReturns() async {
    try {
      final snapshot = await _returnsCollection
          .orderBy('returnDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              PurchaseReturn.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback without index
      final snapshot = await _returnsCollection.get();
      final list = snapshot.docs
          .map((doc) =>
              PurchaseReturn.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.returnDate.compareTo(a.returnDate));
      return list;
    }
  }

  // Get returns by supplier
  Future<List<PurchaseReturn>> getReturnsBySupplierId(
      String supplierId) async {
    try {
      final snapshot = await _returnsCollection
          .where('supplierId', isEqualTo: supplierId)
          .get();
      final list = snapshot.docs
          .map((doc) =>
              PurchaseReturn.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.returnDate.compareTo(a.returnDate));
      return list;
    } catch (e) {
      throw Exception('Failed to get returns by supplier: $e');
    }
  }

  // Get returns by date range
  Future<List<PurchaseReturn>> getReturnsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _returnsCollection
          .where('returnDate',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('returnDate',
              isLessThanOrEqualTo: endDate.toIso8601String())
          .get();
      final list = snapshot.docs
          .map((doc) =>
              PurchaseReturn.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.returnDate.compareTo(a.returnDate));
      return list;
    } catch (e) {
      // Fallback: get all and filter
      final all = await getAllReturns();
      return all
          .where((r) =>
              !r.returnDate.isBefore(startDate) &&
              !r.returnDate.isAfter(endDate))
          .toList();
    }
  }

  // Get a single return by ID
  Future<PurchaseReturn?> getReturnById(String id) async {
    try {
      final doc = await _returnsCollection.doc(id).get();
      if (doc.exists) {
        return PurchaseReturn.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get purchase return: $e');
    }
  }

  // Delete a purchase return
  Future<void> deleteReturn(String id) async {
    try {
      await _returnsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete purchase return: $e');
    }
  }

  // Get total return amount for a supplier
  Future<double> getTotalReturnAmount({String? supplierId}) async {
    final returns = supplierId != null
        ? await getReturnsBySupplierId(supplierId)
        : await getAllReturns();
    return returns.fold<double>(0.0, (total, r) => total + r.totalAmount);
  }
}
