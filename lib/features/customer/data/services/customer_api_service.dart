import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API Service for Customer data operations with Firebase
/// This handles all remote server communication
class CustomerApiService {
  static CustomerApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CustomerApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static CustomerApiService get instance {
    _instance ??= CustomerApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get customers collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _customersRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customers');
  }

  /// Ensure user is authenticated
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Fetch all customers from server
  /// If [updatedSince] is provided, only fetch customers updated after that time
  Future<List<Map<String, dynamic>>> getCustomers({
    DateTime? updatedSince,
  }) async {
    _ensureAuthenticated();
    
    try {
      Query<Map<String, dynamic>> query = _customersRef!;

      // Filter by updatedSince for incremental sync
      if (updatedSince != null) {
        query = query.where('updatedAt', isGreaterThan: updatedSince.toIso8601String());
      }

      // Order by updatedAt for consistent results
      query = query.orderBy('updatedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[CustomerAPI] Error fetching customers: $e');
      rethrow;
    }
  }

  /// Get a single customer by ID
  Future<Map<String, dynamic>?> getCustomer(String id) async {
    _ensureAuthenticated();
    
    try {
      final doc = await _customersRef!.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[CustomerAPI] Error fetching customer $id: $e');
      rethrow;
    }
  }

  /// Create a new customer on the server
  /// Returns the server response with the new document ID
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(customerData);
      payload.remove('id'); // Remove if empty or local
      payload.remove('localId');
      payload.remove('isSynced');
      
      // Ensure server timestamps
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _customersRef!.add(payload);
      
      debugPrint('[CustomerAPI] Customer created with ID: ${docRef.id}');
      
      // Fetch the created document to return complete data
      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[CustomerAPI] Error creating customer: $e');
      rethrow;
    }
  }

  /// Update an existing customer on the server
  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> customerData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(customerData);
      payload.remove('id');
      payload.remove('localId');
      payload.remove('isSynced');
      
      // Update timestamp
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await _customersRef!.doc(id).update(payload);
      
      debugPrint('[CustomerAPI] Customer updated: $id');
      
      // Fetch the updated document
      final doc = await _customersRef!.doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[CustomerAPI] Error updating customer $id: $e');
      rethrow;
    }
  }

  /// Delete a customer from the server
  Future<void> deleteCustomer(String id) async {
    _ensureAuthenticated();
    
    try {
      await _customersRef!.doc(id).delete();
      debugPrint('[CustomerAPI] Customer deleted: $id');
    } catch (e) {
      debugPrint('[CustomerAPI] Error deleting customer $id: $e');
      rethrow;
    }
  }

  /// Check if a customer with the given mobile exists on server
  Future<bool> mobileExists(String mobile, {String? excludeId}) async {
    _ensureAuthenticated();
    
    try {
      final query = _customersRef!.where('mobile', isEqualTo: mobile);
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) return false;
      if (excludeId == null) return true;
      
      // Check if any doc has different ID
      return snapshot.docs.any((doc) => doc.id != excludeId);
    } catch (e) {
      debugPrint('[CustomerAPI] Error checking mobile exists: $e');
      return false;
    }
  }

  /// Get customers count on server
  Future<int> getCustomersCount() async {
    _ensureAuthenticated();
    
    try {
      final snapshot = await _customersRef!.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[CustomerAPI] Error getting customers count: $e');
      return 0;
    }
  }

  /// Search customers by name or mobile (server-side)
  /// Note: Firebase has limited text search - consider using Algolia for production
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    _ensureAuthenticated();
    
    try {
      // Firebase doesn't support full-text search well
      // This searches by exact prefix match on firstName
      final snapshot = await _customersRef!
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[CustomerAPI] Error searching customers: $e');
      rethrow;
    }
  }

  /// Batch create customers (for bulk import)
  Future<List<String>> batchCreateCustomers(List<Map<String, dynamic>> customers) async {
    _ensureAuthenticated();
    
    try {
      final batch = _firestore.batch();
      final docRefs = <DocumentReference>[];

      for (final customer in customers) {
        final payload = Map<String, dynamic>.from(customer);
        payload.remove('id');
        payload.remove('localId');
        payload.remove('isSynced');
        payload['createdAt'] = FieldValue.serverTimestamp();
        payload['updatedAt'] = FieldValue.serverTimestamp();

        final docRef = _customersRef!.doc();
        docRefs.add(docRef);
        batch.set(docRef, payload);
      }

      await batch.commit();
      return docRefs.map((ref) => ref.id).toList();
    } catch (e) {
      debugPrint('Error batch creating customers: $e');
      rethrow;
    }
  }

  /// Batch update customers
  Future<void> batchUpdateCustomers(Map<String, Map<String, dynamic>> updates) async {
    _ensureAuthenticated();
    
    try {
      final batch = _firestore.batch();

      for (final entry in updates.entries) {
        final payload = Map<String, dynamic>.from(entry.value);
        payload.remove('id');
        payload.remove('localId');
        payload.remove('isSynced');
        payload['updatedAt'] = FieldValue.serverTimestamp();

        batch.update(_customersRef!.doc(entry.key), payload);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error batch updating customers: $e');
      rethrow;
    }
  }

  /// Batch delete customers
  Future<void> batchDeleteCustomers(List<String> ids) async {
    _ensureAuthenticated();
    
    try {
      final batch = _firestore.batch();

      for (final id in ids) {
        batch.delete(_customersRef!.doc(id));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error batch deleting customers: $e');
      rethrow;
    }
  }
}
