import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API service for Product Batch Firebase operations
/// Handles all server-side CRUD for batch sync
class ProductBatchApiService {
  static ProductBatchApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProductBatchApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static ProductBatchApiService get instance {
    _instance ??= ProductBatchApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get product batches collection reference
  CollectionReference<Map<String, dynamic>> get _batchesRef {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('productBatches');
  }

  /// Create a new batch on server
  /// Returns the server-generated document ID
  Future<String> createBatch(Map<String, dynamic> data) async {
    final docRef = await _batchesRef.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[BatchAPI] Created batch: ${docRef.id}');
    return docRef.id;
  }

  /// Update an existing batch on server
  Future<void> updateBatch(String serverId, Map<String, dynamic> data) async {
    await _batchesRef.doc(serverId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[BatchAPI] Updated batch: $serverId');
  }

  /// Delete a batch from server
  Future<void> deleteBatch(String serverId) async {
    await _batchesRef.doc(serverId).delete();
    debugPrint('[BatchAPI] Deleted batch: $serverId');
  }

  /// Get all batches from server
  Future<List<Map<String, dynamic>>> getBatches() async {
    final snapshot = await _batchesRef
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get batches updated since a specific time (for delta sync)
  Future<List<Map<String, dynamic>>> getBatchesSince(DateTime since) async {
    final snapshot = await _batchesRef
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get batches by product ID
  Future<List<Map<String, dynamic>>> getBatchesByProductId(String productId) async {
    final snapshot = await _batchesRef
        .where('productId', isEqualTo: productId)
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get batches by company ID
  Future<List<Map<String, dynamic>>> getBatchesByCompanyId(String companyId) async {
    final snapshot = await _batchesRef
        .where('companyId', isEqualTo: companyId)
        .orderBy('purchaseDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;
}
