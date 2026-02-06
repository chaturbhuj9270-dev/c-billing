import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:c_billing/features/customer/domain/entities/customer.dart';
import 'package:c_billing/features/customer/domain/entities/customer_transaction.dart';
import 'package:c_billing/features/customer/data/repositories/customer_repository.dart';
import 'package:c_billing/features/customer/data/repositories/customer_transaction_repository.dart';

/// Result class for transaction operations
class TransactionResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final double? newBalance;

  TransactionResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.newBalance,
  });

  factory TransactionResult.success({
    required String transactionId,
    required double newBalance,
  }) {
    return TransactionResult(
      success: true,
      transactionId: transactionId,
      newBalance: newBalance,
    );
  }

  factory TransactionResult.failure(String message) {
    return TransactionResult(success: false, errorMessage: message);
  }
}

/// Service for managing customer transactions and pending balances
///
/// This service implements all business logic for:
/// - Recording payments received from customers
/// - Recording bill generation (adding to pending balance)
/// - Validating transactions
/// - Maintaining atomicity using Firestore transactions
class CustomerTransactionService {
  final FirebaseFirestore firestore;
  final FirebaseCustomerRepository customerRepository;
  final FirebaseCustomerTransactionRepository transactionRepository;

  CustomerTransactionService({
    required this.firestore,
    required this.customerRepository,
    required this.transactionRepository,
  });

  /// Record a payment received from a customer
  ///
  /// Business Rules:
  /// - Amount must be positive
  /// - Amount cannot exceed current pending balance
  /// - Customer must exist
  /// - Uses atomic transaction to update balance and create record
  Future<TransactionResult> receivePayment({
    required String customerId,
    required double amount,
    required PaymentMode paymentMode,
    String? billId,
    String? billNumber,
    String? notes,
    String? referenceNumber,
  }) async {
    // Validation
    if (amount <= 0) {
      return TransactionResult.failure('Amount must be greater than zero');
    }

    try {
      // Use Firestore transaction for atomicity
      final result = await firestore.runTransaction<TransactionResult>((
        transaction,
      ) async {
        // Step 1: Get customer and validate
        final customerDoc = await transaction.get(
          firestore
              .collection('users')
              .doc(customerRepository.userId)
              .collection('customers')
              .doc(customerId),
        );

        if (!customerDoc.exists) {
          throw Exception('Customer not found');
        }

        final customerData = customerDoc.data()!;
        customerData['id'] = customerDoc.id;
        final customer = Customer.fromJson(customerData);

        // Step 2: Validate amount against pending balance
        if (amount > customer.currentPendingAmount) {
          throw Exception(
            'Amount (₹${amount.toStringAsFixed(2)}) exceeds pending balance '
            '(₹${customer.currentPendingAmount.toStringAsFixed(2)})',
          );
        }

        // Step 3: Calculate new balance
        final newBalance = customer.currentPendingAmount - amount;

        // Step 4: Create transaction record
        final now = DateTime.now();
        final transactionRef = firestore
            .collection('users')
            .doc(customerRepository.userId)
            .collection('customer_transactions')
            .doc();

        final customerTransaction = CustomerTransaction(
          id: transactionRef.id,
          customerId: customerId,
          billId: billId,
          billNumber: billNumber,
          amount: amount,
          transactionType: TransactionType.received,
          paymentMode: paymentMode,
          balanceAfterTransaction: newBalance,
          notes: notes,
          referenceNumber: referenceNumber,
          createdAt: now,
        );

        transaction.set(transactionRef, customerTransaction.toJson());

        // Step 5: Update customer balance
        transaction.update(customerDoc.reference, {
          'currentPendingAmount': newBalance,
          'totalPaidAmount': FieldValue.increment(amount),
          'updatedAt': now.toIso8601String(),
        });

        return TransactionResult.success(
          transactionId: transactionRef.id,
          newBalance: newBalance,
        );
      });

      return result;
    } catch (e) {
      print('[ERROR] Failed to receive payment: $e');
      return TransactionResult.failure(e.toString());
    }
  }

  /// Record a bill generated for a customer (adds to pending balance)
  ///
  /// Business Rules:
  /// - Bill amount must be positive
  /// - Customer must exist
  /// - Creates transaction record for audit trail
  Future<TransactionResult> recordBillGenerated({
    required String customerId,
    required String billId,
    required String billNumber,
    required double billAmount,
  }) async {
    if (billAmount <= 0) {
      return TransactionResult.failure('Bill amount must be greater than zero');
    }

    try {
      final result = await firestore.runTransaction<TransactionResult>((
        transaction,
      ) async {
        // Step 1: Get customer
        final customerDoc = await transaction.get(
          firestore
              .collection('users')
              .doc(customerRepository.userId)
              .collection('customers')
              .doc(customerId),
        );

        if (!customerDoc.exists) {
          throw Exception('Customer not found');
        }

        final customerData = customerDoc.data()!;
        final currentPending =
            ((customerData['currentPendingAmount'] ?? 0) as num).toDouble();

        // Step 2: Calculate new balance
        final newBalance = currentPending + billAmount;

        // Step 3: Create transaction record
        final now = DateTime.now();
        final transactionRef = firestore
            .collection('users')
            .doc(customerRepository.userId)
            .collection('customer_transactions')
            .doc();

        final customerTransaction = CustomerTransaction(
          id: transactionRef.id,
          customerId: customerId,
          billId: billId,
          billNumber: billNumber,
          amount: billAmount,
          transactionType: TransactionType.billGenerated,
          paymentMode: null,
          balanceAfterTransaction: newBalance,
          notes: 'Bill generated',
          createdAt: now,
        );

        transaction.set(transactionRef, customerTransaction.toJson());

        // Step 4: Update customer balance
        transaction.update(customerDoc.reference, {
          'currentPendingAmount': newBalance,
          'totalPurchaseAmount': FieldValue.increment(billAmount),
          'updatedAt': now.toIso8601String(),
        });

        return TransactionResult.success(
          transactionId: transactionRef.id,
          newBalance: newBalance,
        );
      });

      return result;
    } catch (e) {
      print('[ERROR] Failed to record bill generated: $e');
      return TransactionResult.failure(e.toString());
    }
  }

  /// Record an adjustment to customer balance
  ///
  /// Used for:
  /// - Write-offs
  /// - Corrections
  /// - Discounts applied after billing
  Future<TransactionResult> recordAdjustment({
    required String customerId,
    required double amount,
    required String notes,
    String? billId,
    String? billNumber,
  }) async {
    if (amount <= 0) {
      return TransactionResult.failure(
        'Adjustment amount must be greater than zero',
      );
    }

    try {
      final result = await firestore.runTransaction<TransactionResult>((
        transaction,
      ) async {
        // Get customer
        final customerDoc = await transaction.get(
          firestore
              .collection('users')
              .doc(customerRepository.userId)
              .collection('customers')
              .doc(customerId),
        );

        if (!customerDoc.exists) {
          throw Exception('Customer not found');
        }

        final customerData = customerDoc.data()!;
        final currentPending =
            ((customerData['currentPendingAmount'] ?? 0) as num).toDouble();

        if (amount > currentPending) {
          throw Exception('Adjustment amount cannot exceed pending balance');
        }

        final newBalance = currentPending - amount;
        final now = DateTime.now();

        // Create transaction record
        final transactionRef = firestore
            .collection('users')
            .doc(customerRepository.userId)
            .collection('customer_transactions')
            .doc();

        final customerTransaction = CustomerTransaction(
          id: transactionRef.id,
          customerId: customerId,
          billId: billId,
          billNumber: billNumber,
          amount: amount,
          transactionType: TransactionType.adjusted,
          paymentMode: null,
          balanceAfterTransaction: newBalance,
          notes: notes,
          createdAt: now,
        );

        transaction.set(transactionRef, customerTransaction.toJson());

        // Update customer balance
        transaction.update(customerDoc.reference, {
          'currentPendingAmount': newBalance,
          'updatedAt': now.toIso8601String(),
        });

        return TransactionResult.success(
          transactionId: transactionRef.id,
          newBalance: newBalance,
        );
      });

      return result;
    } catch (e) {
      print('[ERROR] Failed to record adjustment: $e');
      return TransactionResult.failure(e.toString());
    }
  }

  /// Record a refund given to customer (for returns)
  ///
  /// Used when a bill is returned and refund is issued
  Future<TransactionResult> recordRefund({
    required String customerId,
    required String billId,
    required String billNumber,
    required double refundAmount,
    String? notes,
  }) async {
    if (refundAmount <= 0) {
      return TransactionResult.failure(
        'Refund amount must be greater than zero',
      );
    }

    try {
      final result = await firestore.runTransaction<TransactionResult>((
        transaction,
      ) async {
        // Get customer
        final customerDoc = await transaction.get(
          firestore
              .collection('users')
              .doc(customerRepository.userId)
              .collection('customers')
              .doc(customerId),
        );

        if (!customerDoc.exists) {
          throw Exception('Customer not found');
        }

        final customerData = customerDoc.data()!;
        final currentPending =
            ((customerData['currentPendingAmount'] ?? 0) as num).toDouble();

        // Refund reduces pending (if customer had pending balance)
        // or creates a credit (negative balance not allowed, so just set to 0)
        final newBalance = (currentPending - refundAmount).clamp(
          0.0,
          double.infinity,
        );

        final now = DateTime.now();

        // Create transaction record
        final transactionRef = firestore
            .collection('users')
            .doc(customerRepository.userId)
            .collection('customer_transactions')
            .doc();

        final customerTransaction = CustomerTransaction(
          id: transactionRef.id,
          customerId: customerId,
          billId: billId,
          billNumber: billNumber,
          amount: refundAmount,
          transactionType: TransactionType.refund,
          paymentMode: null,
          balanceAfterTransaction: newBalance,
          notes: notes ?? 'Bill returned - refund processed',
          createdAt: now,
        );

        transaction.set(transactionRef, customerTransaction.toJson());

        // Update customer balance
        transaction.update(customerDoc.reference, {
          'currentPendingAmount': newBalance,
          'totalPurchaseAmount': FieldValue.increment(-refundAmount),
          'updatedAt': now.toIso8601String(),
        });

        return TransactionResult.success(
          transactionId: transactionRef.id,
          newBalance: newBalance,
        );
      });

      return result;
    } catch (e) {
      print('[ERROR] Failed to record refund: $e');
      return TransactionResult.failure(e.toString());
    }
  }

  /// Get customer with full transaction history
  Future<CustomerWithTransactions?> getCustomerWithTransactions(
    String customerId, {
    int transactionLimit = 50,
  }) async {
    try {
      final customer = await customerRepository.getCustomerById(customerId);
      if (customer == null) return null;

      final transactions = await transactionRepository
          .getTransactionsByCustomerId(customerId, limit: transactionLimit);

      return CustomerWithTransactions(
        customer: customer,
        transactions: transactions,
      );
    } catch (e) {
      print('[ERROR] Failed to get customer with transactions: $e');
      rethrow;
    }
  }

  /// Get summary of all pending balances
  Future<PendingBalanceSummary> getPendingBalanceSummary() async {
    try {
      final customersWithPending = await customerRepository
          .getCustomersWithPendingBalance();

      double totalPending = 0;
      for (final customer in customersWithPending) {
        totalPending += customer.currentPendingAmount;
      }

      return PendingBalanceSummary(
        totalPendingAmount: totalPending,
        customersWithPending: customersWithPending.length,
        customers: customersWithPending,
      );
    } catch (e) {
      print('[ERROR] Failed to get pending balance summary: $e');
      rethrow;
    }
  }
}

/// Helper class to hold customer with their transactions
class CustomerWithTransactions {
  final Customer customer;
  final List<CustomerTransaction> transactions;

  const CustomerWithTransactions({
    required this.customer,
    required this.transactions,
  });
}

/// Helper class for pending balance summary
class PendingBalanceSummary {
  final double totalPendingAmount;
  final int customersWithPending;
  final List<Customer> customers;

  const PendingBalanceSummary({
    required this.totalPendingAmount,
    required this.customersWithPending,
    required this.customers,
  });
}
