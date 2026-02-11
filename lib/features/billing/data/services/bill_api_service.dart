import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API service for Bill Firebase operations
/// Used by BillSyncService for server communication
class BillApiService {
  static BillApiService? _instance;
  
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BillApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static BillApiService get instance {
    _instance ??= BillApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get bills collection reference
  CollectionReference<Map<String, dynamic>> get _billsCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('bills');
  }

  // ==================== CREATE ====================

  /// Create a new bill on server
  /// Also updates product stock on server (decrements stock for each item)
  /// Returns the server-generated ID
  Future<String> createBill(Map<String, dynamic> data) async {
    try {
      final docRef = _billsCollection.doc();
      final billId = docRef.id;
      
      // Use batch write to create bill and update product stock atomically
      final batch = _firestore.batch();
      
      // Add bill document with ID
      final billData = Map<String, dynamic>.from(data);
      billData['id'] = billId;
      batch.set(docRef, billData);
      
      // Decrement stock for each product in the bill items
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        final productsCollection = _firestore
            .collection('users')
            .doc(_userId)
            .collection('products');
            
        for (final item in items) {
          final productId = item['productId'] as String?;
          final quantity = item['quantity'] as int? ?? 0;
          
          if (productId != null && productId.isNotEmpty && quantity > 0) {
            final productRef = productsCollection.doc(productId);
            batch.update(productRef, {
              'currentStock': FieldValue.increment(-quantity),
              'updatedAt': DateTime.now().toIso8601String(),
            });
            debugPrint('[BillApi] Will decrement stock for product $productId by $quantity');
          }
        }
      }
      
      // Commit batch
      await batch.commit();
      
      debugPrint('[BillApi] Created bill: $billId with stock updates');
      return billId;
    } catch (e) {
      debugPrint('[BillApi] Failed to create bill: $e');
      rethrow;
    }
  }

  // ==================== READ ====================

  /// Get all bills from server
  Future<List<Map<String, dynamic>>> getBills({DateTime? updatedSince}) async {
    try {
      Query<Map<String, dynamic>> query = _billsCollection;
      
      if (updatedSince != null) {
        query = query.where(
          'updatedAt',
          isGreaterThan: updatedSince.toIso8601String(),
        );
      }
      
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // If ordering fails, try without ordering
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint('[BillApi] Index not available, fetching without order');
        final snapshot = await _billsCollection.get();
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }
      debugPrint('[BillApi] Failed to get bills: $e');
      rethrow;
    }
  }

  /// Get a single bill by ID
  Future<Map<String, dynamic>?> getBillById(String id) async {
    try {
      final doc = await _billsCollection.doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[BillApi] Failed to get bill $id: $e');
      rethrow;
    }
  }

  /// Get bills by customer ID
  Future<List<Map<String, dynamic>>> getBillsByCustomerId(String customerId) async {
    try {
      final snapshot = await _billsCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[BillApi] Failed to get bills for customer $customerId: $e');
      rethrow;
    }
  }

  // ==================== UPDATE ====================

  /// Update an existing bill on server
  Future<void> updateBill(String id, Map<String, dynamic> data) async {
    try {
      await _billsCollection.doc(id).update(data);
      debugPrint('[BillApi] Updated bill: $id');
    } catch (e) {
      debugPrint('[BillApi] Failed to update bill $id: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// Delete a bill from server
  Future<void> deleteBill(String id) async {
    try {
      await _billsCollection.doc(id).delete();
      debugPrint('[BillApi] Deleted bill: $id');
    } catch (e) {
      debugPrint('[BillApi] Failed to delete bill $id: $e');
      rethrow;
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Get bills updated since a specific time (for delta sync)
  Future<List<Map<String, dynamic>>> getBillsSince(DateTime since) async {
    try {
      final snapshot = await _billsCollection
          .where('updatedAt', isGreaterThan: since.toIso8601String())
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[BillApi] Failed to get bills since $since: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;
}
