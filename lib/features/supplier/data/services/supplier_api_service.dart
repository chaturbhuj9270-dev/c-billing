import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API Service for Supplier data operations with Firebase
/// Handles all remote server communication for suppliers
class SupplierApiService {
  static SupplierApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SupplierApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static SupplierApiService get instance {
    _instance ??= SupplierApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get suppliers collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _suppliersRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('suppliers');
  }

  /// Ensure user is authenticated
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Fetch all suppliers from server
  Future<List<Map<String, dynamic>>> getSuppliers({
    DateTime? updatedSince,
  }) async {
    _ensureAuthenticated();
    
    try {
      Query<Map<String, dynamic>> query = _suppliersRef!;

      // Filter by updatedSince for incremental sync
      if (updatedSince != null) {
        query = query.where(
          'updatedAt',
          isGreaterThan: updatedSince.toIso8601String(),
        );
      }

      // Order by updatedAt for consistent results
      query = query.orderBy('updatedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[SupplierAPI] Error fetching suppliers: $e');
      rethrow;
    }
  }

  /// Get a single supplier by ID
  Future<Map<String, dynamic>?> getSupplier(String id) async {
    _ensureAuthenticated();
    
    try {
      final doc = await _suppliersRef!.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[SupplierAPI] Error fetching supplier $id: $e');
      rethrow;
    }
  }

  /// Create a new supplier on the server
  /// Returns the server response with the new document ID
  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> supplierData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(supplierData);
      payload.remove('id');
      payload.remove('localId');
      payload.remove('syncStatus');
      payload.remove('isSynced');
      
      // Ensure server timestamps
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _suppliersRef!.add(payload);
      
      debugPrint('[SupplierAPI] Supplier created with ID: ${docRef.id}');
      
      // Fetch the created document to return complete data
      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[SupplierAPI] Error creating supplier: $e');
      rethrow;
    }
  }

  /// Update an existing supplier on the server
  Future<Map<String, dynamic>> updateSupplier(String id, Map<String, dynamic> supplierData) async {
    _ensureAuthenticated();
    
    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(supplierData);
      payload.remove('id');
      payload.remove('localId');
      payload.remove('syncStatus');
      payload.remove('isSynced');
      
      // Update timestamp
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await _suppliersRef!.doc(id).update(payload);
      
      debugPrint('[SupplierAPI] Supplier updated: $id');
      
      // Fetch the updated document
      final doc = await _suppliersRef!.doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
    } catch (e) {
      debugPrint('[SupplierAPI] Error updating supplier $id: $e');
      rethrow;
    }
  }

  /// Delete a supplier from the server
  Future<void> deleteSupplier(String id) async {
    _ensureAuthenticated();
    
    try {
      await _suppliersRef!.doc(id).delete();
      debugPrint('[SupplierAPI] Supplier deleted: $id');
    } catch (e) {
      debugPrint('[SupplierAPI] Error deleting supplier $id: $e');
      rethrow;
    }
  }

  /// Check if supplier with contact exists
  Future<bool> contactExists(String contact, {String? excludeId}) async {
    _ensureAuthenticated();
    
    try {
      final query = await _suppliersRef!
          .where('contact', isEqualTo: contact)
          .limit(2)
          .get();
      
      if (query.docs.isEmpty) return false;
      if (excludeId == null) return true;
      
      // Check if the only match is the excluded one
      return query.docs.any((doc) => doc.id != excludeId);
    } catch (e) {
      debugPrint('[SupplierAPI] Error checking contact: $e');
      return false;
    }
  }
}
