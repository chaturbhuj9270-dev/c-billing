import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_billing/features/customer/domain/entities/customer.dart';

/// Repository for customer data operations
///
/// Handles all CRUD operations and balance management for customers
/// Uses Firebase Firestore for persistence
abstract class CustomerRepository {
  /// Get all customers for current user
  Future<List<Customer>> getAllCustomers();

  /// Get a customer by ID
  Future<Customer?> getCustomerById(String customerId);

  /// Get a customer by contact number
  Future<Customer?> getCustomerByContact(String contact);

  /// Create a new customer
  Future<String> createCustomer(Customer customer);

  /// Update an existing customer
  Future<void> updateCustomer(Customer customer);

  /// Delete a customer (soft delete - sets isActive to false)
  Future<void> deleteCustomer(String customerId);

  /// Update customer's pending balance
  /// Used by transaction service for atomic updates
  Future<void> updatePendingBalance({
    required String customerId,
    required double newPendingAmount,
    required double purchaseAmountDelta,
    required double paidAmountDelta,
  });

  /// Search customers by name or contact
  Future<List<Customer>> searchCustomers(String query);

  /// Get customers with pending balance
  Future<List<Customer>> getCustomersWithPendingBalance();
}

/// Firebase implementation of CustomerRepository
class FirebaseCustomerRepository implements CustomerRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseCustomerRepository({required this.firestore});

  /// Get current user ID (public for use by services)
  String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Get reference to customers collection
  CollectionReference<Map<String, dynamic>> get _customersCollection =>
      firestore.collection('users').doc(userId).collection('customers');

  @override
  Future<List<Customer>> getAllCustomers() async {
    try {
      final snapshot = await _customersCollection
          .where('isActive', isEqualTo: true)
          .orderBy('firstName')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Customer.fromJson(data);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to get all customers: $e');
      rethrow;
    }
  }

  @override
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc = await _customersCollection.doc(customerId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return Customer.fromJson(data);
    } catch (e) {
      print('[ERROR] Failed to get customer by ID: $e');
      rethrow;
    }
  }

  @override
  Future<Customer?> getCustomerByContact(String contact) async {
    try {
      final snapshot = await _customersCollection
          .where('contact', isEqualTo: contact)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return Customer.fromJson(data);
    } catch (e) {
      print('[ERROR] Failed to get customer by contact: $e');
      rethrow;
    }
  }

  @override
  Future<String> createCustomer(Customer customer) async {
    try {
      final now = DateTime.now();
      final docRef = _customersCollection.doc();

      final customerData = customer.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await docRef.set(customerData.toJson());
      return docRef.id;
    } catch (e) {
      print('[ERROR] Failed to create customer: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());

      await _customersCollection
          .doc(customer.id)
          .update(updatedCustomer.toJson());
    } catch (e) {
      print('[ERROR] Failed to update customer: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    try {
      // Soft delete - just mark as inactive
      await _customersCollection.doc(customerId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[ERROR] Failed to delete customer: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePendingBalance({
    required String customerId,
    required double newPendingAmount,
    required double purchaseAmountDelta,
    required double paidAmountDelta,
  }) async {
    try {
      await _customersCollection.doc(customerId).update({
        'currentPendingAmount': newPendingAmount,
        'totalPurchaseAmount': FieldValue.increment(purchaseAmountDelta),
        'totalPaidAmount': FieldValue.increment(paidAmountDelta),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[ERROR] Failed to update pending balance: $e');
      rethrow;
    }
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      // Firestore doesn't support full-text search, so we fetch all and filter
      // For production, consider using Algolia or similar
      final customers = await getAllCustomers();
      final lowerQuery = query.toLowerCase();

      return customers.where((customer) {
        return customer.fullName.toLowerCase().contains(lowerQuery) ||
            customer.contact.contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to search customers: $e');
      rethrow;
    }
  }

  @override
  Future<List<Customer>> getCustomersWithPendingBalance() async {
    try {
      final snapshot = await _customersCollection
          .where('isActive', isEqualTo: true)
          .where('currentPendingAmount', isGreaterThan: 0)
          .orderBy('currentPendingAmount', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Customer.fromJson(data);
      }).toList();
    } catch (e) {
      print('[ERROR] Failed to get customers with pending balance: $e');
      rethrow;
    }
  }

  /// Update customer balance using Firestore transaction (for atomicity)
  /// This should be called from CustomerTransactionService
  Future<void> updateBalanceInTransaction({
    required Transaction transaction,
    required String customerId,
    required double balanceDelta,
    required double purchaseAmountDelta,
    required double paidAmountDelta,
  }) async {
    final docRef = _customersCollection.doc(customerId);
    final doc = await transaction.get(docRef);

    if (!doc.exists) {
      throw Exception('Customer not found: $customerId');
    }

    final currentData = doc.data()!;
    final currentPending = ((currentData['currentPendingAmount'] ?? 0) as num)
        .toDouble();
    final newPending = currentPending + balanceDelta;

    if (newPending < 0) {
      throw Exception(
        'Invalid operation: pending balance cannot be negative. '
        'Current: $currentPending, Delta: $balanceDelta',
      );
    }

    transaction.update(docRef, {
      'currentPendingAmount': newPending,
      'totalPurchaseAmount': FieldValue.increment(purchaseAmountDelta),
      'totalPaidAmount': FieldValue.increment(paidAmountDelta),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
