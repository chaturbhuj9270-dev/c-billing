import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_billing/features/customer/domain/entities/customer_transaction.dart';

/// Repository for customer transaction data operations
///
/// Handles all CRUD operations for customer transactions
/// Uses Firebase Firestore for persistence
abstract class CustomerTransactionRepository {
  /// Get all transactions for a customer
  Future<List<CustomerTransaction>> getTransactionsByCustomerId(
    String customerId, {
    int? limit,
  });

  /// Get a transaction by ID
  Future<CustomerTransaction?> getTransactionById(String transactionId);

  /// Get transactions for a specific bill
  Future<List<CustomerTransaction>> getTransactionsByBillId(String billId);

  /// Create a new transaction
  Future<String> createTransaction(CustomerTransaction transaction);

  /// Get recent transactions across all customers
  Future<List<CustomerTransaction>> getRecentTransactions({int limit = 50});

  /// Get total received amount for a date range
  Future<double> getTotalReceivedAmount({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get payment transactions for a customer (received type only)
  Future<List<CustomerTransaction>> getPaymentsByCustomerId(String customerId);
}

/// Firebase implementation of CustomerTransactionRepository
class FirebaseCustomerTransactionRepository
    implements CustomerTransactionRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseCustomerTransactionRepository({required this.firestore});

  /// Get current user ID
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Get reference to customer_transactions collection
  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      firestore
          .collection('users')
          .doc(_userId)
          .collection('customer_transactions');

  @override
  Future<List<CustomerTransaction>> getTransactionsByCustomerId(
    String customerId, {
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _transactionsCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomerTransaction.fromJson(data);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to get transactions by customer ID: $e');
      rethrow;
    }
  }

  @override
  Future<CustomerTransaction?> getTransactionById(String transactionId) async {
    try {
      final doc = await _transactionsCollection.doc(transactionId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return CustomerTransaction.fromJson(data);
    } catch (e) {
      print('[ERROR] Failed to get transaction by ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerTransaction>> getTransactionsByBillId(
    String billId,
  ) async {
    try {
      final snapshot = await _transactionsCollection
          .where('billId', isEqualTo: billId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomerTransaction.fromJson(data);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to get transactions by bill ID: $e');
      rethrow;
    }
  }

  @override
  Future<String> createTransaction(CustomerTransaction transaction) async {
    try {
      final docRef = _transactionsCollection.doc();

      final transactionData = transaction.copyWith(
        id: docRef.id,
        createdBy: _userId,
      );

      await docRef.set(transactionData.toJson());
      return docRef.id;
    } catch (e) {
      print('[ERROR] Failed to create transaction: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerTransaction>> getRecentTransactions({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _transactionsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomerTransaction.fromJson(data);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to get recent transactions: $e');
      rethrow;
    }
  }

  @override
  Future<double> getTotalReceivedAmount({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _transactionsCollection
          .where('transactionType', isEqualTo: 'RECEIVED')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        total += ((doc.data()['amount'] ?? 0) as num).toDouble();
      }
      return total;
    } catch (e) {
      print('[ERROR] Failed to get total received amount: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomerTransaction>> getPaymentsByCustomerId(
    String customerId,
  ) async {
    try {
      final snapshot = await _transactionsCollection
          .where('customerId', isEqualTo: customerId)
          .where('transactionType', isEqualTo: 'RECEIVED')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomerTransaction.fromJson(data);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to get payments by customer ID: $e');
      rethrow;
    }
  }

  /// Create transaction within a Firestore transaction (for atomicity)
  /// This is called by CustomerTransactionService
  Future<void> createTransactionInTransaction({
    required Transaction transaction,
    required CustomerTransaction customerTransaction,
  }) async {
    final docRef = _transactionsCollection.doc();

    final transactionData = customerTransaction.copyWith(
      id: docRef.id,
      createdBy: _userId,
    );

    transaction.set(docRef, transactionData.toJson());
  }
}
