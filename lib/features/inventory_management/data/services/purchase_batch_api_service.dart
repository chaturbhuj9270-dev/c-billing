import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API service for Purchase Batch Firebase operations
/// Handles all server-side CRUD for sync
class PurchaseBatchApiService {
  static PurchaseBatchApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PurchaseBatchApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static PurchaseBatchApiService get instance {
    _instance ??= PurchaseBatchApiService._();
    return _instance!;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get purchase batches collection reference
  CollectionReference<Map<String, dynamic>> get _batchesRef {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('purchaseBatches');
  }

  /// Create a new purchase batch on server
  /// Returns the server-generated document ID
  Future<String> createBatch(Map<String, dynamic> data) async {
    final docRef = await _batchesRef.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Also update the document with its own ID as batchId
    await docRef.update({'batchId': docRef.id});
    
    debugPrint('[PurchaseBatchAPI] Created batch: ${docRef.id}');
    return docRef.id;
  }

  /// Update an existing purchase batch on server
  Future<void> updateBatch(String serverId, Map<String, dynamic> data) async {
    await _batchesRef.doc(serverId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[PurchaseBatchAPI] Updated batch: $serverId');
  }

  /// Delete a purchase batch from server
  Future<void> deleteBatch(String serverId) async {
    await _batchesRef.doc(serverId).delete();
    debugPrint('[PurchaseBatchAPI] Deleted batch: $serverId');
  }

  /// Get all purchase batches from server
  Future<List<Map<String, dynamic>>> getBatches() async {
    final snapshot = await _batchesRef
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'batchId': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get batches updated since a specific time
  /// Used for delta sync
  Future<List<Map<String, dynamic>>> getBatchesSince(DateTime since) async {
    final snapshot = await _batchesRef
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'batchId': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get batches by product ID
  Future<List<Map<String, dynamic>>> getBatchesByProductId(String productId) async {
    final snapshot = await _batchesRef
        .where('productId', isEqualTo: productId)
        .orderBy('purchaseDate')
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'batchId': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get batches by supplier ID
  Future<List<Map<String, dynamic>>> getBatchesBySupplierId(String supplierId) async {
    final snapshot = await _batchesRef
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'batchId': doc.id,
      ...doc.data(),
    }).toList();
  }
}
