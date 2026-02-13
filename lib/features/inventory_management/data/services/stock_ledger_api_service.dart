import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API service for Stock Ledger Firebase operations
/// Handles all server-side CRUD for ledger sync
class StockLedgerApiService {
  static StockLedgerApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StockLedgerApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static StockLedgerApiService get instance {
    _instance ??= StockLedgerApiService._();
    return _instance!;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get stock ledger collection reference
  CollectionReference<Map<String, dynamic>> get _ledgerRef {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('stockLedger');
  }

  /// Create a new ledger entry on server
  /// Returns the server-generated document ID
  Future<String> createEntry(Map<String, dynamic> data) async {
    final docRef = await _ledgerRef.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[LedgerAPI] Created entry: ${docRef.id}');
    return docRef.id;
  }

  /// Delete a ledger entry from server
  Future<void> deleteEntry(String serverId) async {
    await _ledgerRef.doc(serverId).delete();
    debugPrint('[LedgerAPI] Deleted entry: $serverId');
  }

  /// Get all ledger entries from server
  Future<List<Map<String, dynamic>>> getEntries() async {
    final snapshot = await _ledgerRef
        .orderBy('transactionDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get entries updated since a specific time (for delta sync)
  Future<List<Map<String, dynamic>>> getEntriesSince(DateTime since) async {
    final snapshot = await _ledgerRef
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get ledger entries by product ID
  Future<List<Map<String, dynamic>>> getEntriesByProductId(String productId) async {
    final snapshot = await _ledgerRef
        .where('productId', isEqualTo: productId)
        .orderBy('transactionDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Get ledger entries by batch ID
  Future<List<Map<String, dynamic>>> getEntriesByBatchId(String batchId) async {
    final snapshot = await _ledgerRef
        .where('batchId', isEqualTo: batchId)
        .orderBy('transactionDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;
}
