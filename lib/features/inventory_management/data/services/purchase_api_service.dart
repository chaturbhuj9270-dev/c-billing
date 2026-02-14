import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API service for Purchase Firebase operations
/// Handles all server-side CRUD for sync
class PurchaseApiService {
  static PurchaseApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PurchaseApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static PurchaseApiService get instance {
    _instance ??= PurchaseApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get purchases collection reference
  CollectionReference<Map<String, dynamic>> get _purchasesRef {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('purchases');
  }

  /// Create a new purchase on server
  /// Returns the server-generated document ID
  Future<String> createPurchase(Map<String, dynamic> data) async {
    final docRef = await _purchasesRef.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[PurchaseAPI] Created purchase: ${docRef.id}');
    return docRef.id;
  }

  /// Update an existing purchase on server
  Future<void> updatePurchase(String serverId, Map<String, dynamic> data) async {
    await _purchasesRef.doc(serverId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[PurchaseAPI] Updated purchase: $serverId');
  }

  /// Delete a purchase from server
  Future<void> deletePurchase(String serverId) async {
    await _purchasesRef.doc(serverId).delete();
    debugPrint('[PurchaseAPI] Deleted purchase: $serverId');
  }

  /// Get all purchases from server
  Future<List<Map<String, dynamic>>> getPurchases() async {
    final snapshot = await _purchasesRef
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get purchases updated since a specific time
  /// Used for delta sync
  Future<List<Map<String, dynamic>>> getPurchasesSince(DateTime since) async {
    final snapshot = await _purchasesRef
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get purchases by product ID
  Future<List<Map<String, dynamic>>> getPurchasesByProductId(String productId) async {
    final snapshot = await _purchasesRef
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;
}
