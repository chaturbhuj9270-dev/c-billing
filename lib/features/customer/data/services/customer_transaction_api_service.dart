import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// API Service for Customer Transaction data operations with Firebase
/// This handles all remote server communication for transactions
class CustomerTransactionApiService {
  static CustomerTransactionApiService? _instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CustomerTransactionApiService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Get the singleton instance
  static CustomerTransactionApiService get instance {
    _instance ??= CustomerTransactionApiService._();
    return _instance!;
  }

  /// Reset instance (for testing)
  static void resetInstance() {
    _instance = null;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  /// Get transactions collection reference for current user
  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
    final userId = _userId;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customer_transactions');
  }

  /// Ensure user is authenticated
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Fetch all transactions from server
  /// If [updatedSince] is provided, only fetch transactions updated after that time
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? updatedSince,
  }) async {
    _ensureAuthenticated();

    try {
      Query<Map<String, dynamic>> query = _transactionsRef!;

      // Filter by updatedSince for incremental sync
      // Note: When updatedSince is provided, we need a composite index
      if (updatedSince != null) {
        query = query
            .where('createdAt', isGreaterThan: updatedSince.toIso8601String())
            .orderBy('createdAt', descending: true);
      }
      // For initial sync (no updatedSince), don't order to avoid index requirements
      // Just fetch all documents

      final snapshot = await query.get();

      debugPrint(
        '[CustomerTransactionAPI] Fetched ${snapshot.docs.length} transactions from server',
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[CustomerTransactionAPI] Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Fetch transactions for a specific customer
  Future<List<Map<String, dynamic>>> getTransactionsByCustomerId(
    String customerId, {
    DateTime? updatedSince,
  }) async {
    _ensureAuthenticated();

    try {
      Query<Map<String, dynamic>> query = _transactionsRef!.where(
        'customerId',
        isEqualTo: customerId,
      );

      // Filter by updatedSince for incremental sync
      if (updatedSince != null) {
        query = query.where(
          'createdAt',
          isGreaterThan: updatedSince.toIso8601String(),
        );
      }

      // Order by createdAt for consistent results
      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint(
        '[CustomerTransactionAPI] Error fetching customer transactions: $e',
      );
      rethrow;
    }
  }

  /// Get a single transaction by ID
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    _ensureAuthenticated();

    try {
      final doc = await _transactionsRef!.doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('[CustomerTransactionAPI] Error fetching transaction $id: $e');
      rethrow;
    }
  }

  /// Create a new transaction on the server
  /// Returns the server response with the new document ID
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    _ensureAuthenticated();

    try {
      // Remove local-only fields
      final payload = Map<String, dynamic>.from(transactionData);
      payload.remove('localId');
      payload.remove('isSynced');
      payload.remove('syncStatus');

      // Ensure server timestamps if not present
      payload['createdAt'] ??= FieldValue.serverTimestamp();

      final docRef = await _transactionsRef!.add(payload);

      debugPrint(
        '[CustomerTransactionAPI] Transaction created with ID: ${docRef.id}',
      );

      // Fetch the created document to return complete data
      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;

      return data;
    } catch (e) {
      debugPrint('[CustomerTransactionAPI] Error creating transaction: $e');
      rethrow;
    }
  }

  /// Delete a transaction from the server
  Future<void> deleteTransaction(String id) async {
    _ensureAuthenticated();

    try {
      await _transactionsRef!.doc(id).delete();
      debugPrint('[CustomerTransactionAPI] Transaction deleted: $id');
    } catch (e) {
      debugPrint('[CustomerTransactionAPI] Error deleting transaction $id: $e');
      rethrow;
    }
  }
}
