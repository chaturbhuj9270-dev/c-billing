import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/customer_transaction_entity.dart';
import '../entities/customer_entity.dart';

/// Controller for handling customer transaction CRUD operations
class CustomerTransactionOfflineController extends ChangeNotifier {
  static CustomerTransactionOfflineController? _instance;

  Isar get _isar => IsarService.instance.isar;

  CustomerTransactionOfflineController._();

  /// Get the singleton instance
  static CustomerTransactionOfflineController get instance {
    _instance ??= CustomerTransactionOfflineController._();
    return _instance!;
  }

  /// Reset instance (for testing)
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Add a payment transaction (customer paid money)
  Future<CustomerTransactionEntity> addPaymentTransaction({
    required String customerId,
    required String customerName,
    required double amount,
    String? description,
    String? paymentMethod,
    DateTime? transactionDate,
  }) async {
    debugPrint(
      '[TransactionOffline] Adding payment: $amount for customer: $customerId',
    );

    // Get current pending amount
    final customer = await _getCustomerByIdOrServerId(customerId);
    final currentPending = customer?.currentPendingAmount ?? 0.0;
    final newPending = currentPending - amount;

    final transaction = CustomerTransactionEntity.payment(
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      balanceAfter: newPending,
      description: description,
      paymentMethod: paymentMethod,
      transactionDate: transactionDate,
    );

    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.put(transaction);

      // Update customer pending amount
      if (customer != null) {
        customer.currentPendingAmount = newPending;
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _isar.customerEntitys.put(customer);
      }
    });

    debugPrint('[TransactionOffline] Payment saved. New pending: $newPending');
    notifyListeners();
    return transaction;
  }

  /// Add a bill transaction (customer owes money)
  Future<CustomerTransactionEntity> addBillTransaction({
    required String customerId,
    required String customerName,
    required double amount,
    required String billId,
    String? description,
  }) async {
    debugPrint(
      '[TransactionOffline] Adding bill transaction: $amount for customer: $customerId',
    );

    // Get current pending amount
    final customer = await _getCustomerByIdOrServerId(customerId);
    final currentPending = customer?.currentPendingAmount ?? 0.0;
    final newPending = currentPending + amount;

    final transaction = CustomerTransactionEntity.bill(
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      balanceAfter: newPending,
      billId: billId,
      description: description,
    );

    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.put(transaction);

      // Update customer pending amount
      if (customer != null) {
        customer.currentPendingAmount = newPending;
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _isar.customerEntitys.put(customer);
      }
    });

    debugPrint(
      '[TransactionOffline] Bill transaction saved. New pending: $newPending',
    );
    notifyListeners();
    return transaction;
  }

  /// Add manual adjustment transaction
  Future<CustomerTransactionEntity> addAdjustmentTransaction({
    required String customerId,
    required String customerName,
    required double amount,
    String? description,
  }) async {
    debugPrint(
      '[TransactionOffline] Adding adjustment: $amount for customer: $customerId',
    );

    final customer = await _getCustomerByIdOrServerId(customerId);
    final currentPending = customer?.currentPendingAmount ?? 0.0;
    final newPending = currentPending + amount; // Can be positive or negative

    final now = DateTime.now();
    final transaction = CustomerTransactionEntity(
      customerId: customerId,
      customerName: customerName,
      transactionType: TransactionType.adjustment,
      amount: amount,
      balanceAfter: newPending,
      description: description,
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );

    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.put(transaction);

      if (customer != null) {
        customer.currentPendingAmount = newPending;
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _isar.customerEntitys.put(customer);
      }
    });

    notifyListeners();
    return transaction;
  }

  // ==================== READ ====================

  /// Get all transactions for a customer
  Future<List<CustomerTransactionEntity>> getTransactionsByCustomerId(
    String customerId,
  ) async {
    return await _isar.customerTransactionEntitys
        .filter()
        .customerIdEqualTo(customerId)
        .not()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get transactions for a customer within date range
  Future<List<CustomerTransactionEntity>> getTransactionsByDateRange({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _isar.customerTransactionEntitys
        .filter()
        .customerIdEqualTo(customerId)
        .transactionDateBetween(startDate, endDate)
        .not()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get transactions for this month
  Future<List<CustomerTransactionEntity>> getThisMonthTransactions(
    String customerId,
  ) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    return getTransactionsByDateRange(
      customerId: customerId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Get transactions for this year
  Future<List<CustomerTransactionEntity>> getThisYearTransactions(
    String customerId,
  ) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(
      now.year + 1,
      1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    return getTransactionsByDateRange(
      customerId: customerId,
      startDate: startOfYear,
      endDate: endOfYear,
    );
  }

  /// Get transactions for last year
  Future<List<CustomerTransactionEntity>> getLastYearTransactions(
    String customerId,
  ) async {
    final now = DateTime.now();
    final startOfLastYear = DateTime(now.year - 1, 1, 1);
    final endOfLastYear = DateTime(
      now.year,
      1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    return getTransactionsByDateRange(
      customerId: customerId,
      startDate: startOfLastYear,
      endDate: endOfLastYear,
    );
  }

  /// Watch transactions for a customer
  Stream<List<CustomerTransactionEntity>> watchTransactionsByCustomerId(
    String customerId,
  ) {
    return _isar.customerTransactionEntitys
        .filter()
        .customerIdEqualTo(customerId)
        .not()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .watch(fireImmediately: true);
  }

  /// Get transaction by ID
  Future<CustomerTransactionEntity?> getTransactionById(Id id) async {
    return await _isar.customerTransactionEntitys.get(id);
  }

  /// Get total payment received for a customer
  Future<double> getTotalPaymentsReceived(String customerId) async {
    final transactions = await _isar.customerTransactionEntitys
        .filter()
        .customerIdEqualTo(customerId)
        .transactionTypeEqualTo(TransactionType.payment)
        .not()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .findAll();

    double total = 0.0;
    for (final t in transactions) {
      total += t.amount;
    }
    return total;
  }

  /// Get total pending count (for summary)
  Future<int> getTotalCount() async {
    return await _isar.customerTransactionEntitys
        .filter()
        .not()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .count();
  }

  // ==================== UPDATE ====================

  /// Update transaction description
  Future<void> updateTransactionDescription(Id id, String description) async {
    final transaction = await _isar.customerTransactionEntitys.get(id);
    if (transaction == null) return;

    transaction.description = description;
    transaction.updatedAt = DateTime.now();
    transaction.syncStatus = TransactionSyncStatus.updated;

    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.put(transaction);
    });

    notifyListeners();
  }

  // ==================== DELETE ====================

  /// Soft delete a transaction
  Future<void> deleteTransaction(Id id) async {
    final transaction = await _isar.customerTransactionEntitys.get(id);
    if (transaction == null) return;

    // Reverse the effect on customer pending amount
    final customer = await _getCustomerByIdOrServerId(transaction.customerId);

    await _isar.writeTxn(() async {
      transaction.syncStatus = TransactionSyncStatus.deleted;
      transaction.updatedAt = DateTime.now();
      await _isar.customerTransactionEntitys.put(transaction);

      // Reverse the transaction effect
      if (customer != null) {
        if (transaction.transactionType == TransactionType.payment) {
          customer.currentPendingAmount += transaction.amount;
        } else {
          customer.currentPendingAmount -= transaction.amount;
        }
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _isar.customerEntitys.put(customer);
      }
    });

    notifyListeners();
  }

  // ==================== HELPERS ====================

  Future<CustomerEntity?> _getCustomerByIdOrServerId(String customerId) async {
    // Try to find by serverId first
    var customer = await _isar.customerEntitys
        .filter()
        .serverIdEqualTo(customerId)
        .findFirst();

    // If not found, try by local ID
    if (customer == null) {
      final localId = int.tryParse(customerId);
      if (localId != null) {
        customer = await _isar.customerEntitys.get(localId);
      }
    }

    return customer;
  }

  /// Get unsynced transactions count
  Future<int> getUnsyncedCount() async {
    return await _isar.customerTransactionEntitys
        .filter()
        .not()
        .syncStatusEqualTo(TransactionSyncStatus.synced)
        .count();
  }

  // ==================== SYNC METHODS ====================

  /// Get transactions that need to be pushed to server
  Future<List<CustomerTransactionEntity>> getTransactionsNeedingPush() async {
    return await _isar.customerTransactionEntitys
        .filter()
        .syncStatusEqualTo(TransactionSyncStatus.newRecord)
        .or()
        .syncStatusEqualTo(TransactionSyncStatus.updated)
        .or()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .findAll();
  }

  /// Import transactions from server
  /// This will upsert based on serverId
  Future<void> importFromServer(
    List<Map<String, dynamic>> serverTransactions,
  ) async {
    if (serverTransactions.isEmpty) return;

    debugPrint(
      '[TransactionOffline] Importing ${serverTransactions.length} transactions from server',
    );

    // First, build a map of customer IDs to names
    // This needs to be done outside the write transaction
    final customerNames = <String, String>{};
    final uniqueCustomerIds = serverTransactions
        .map((t) => t['customerId'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    for (final customerId in uniqueCustomerIds) {
      final customer = await _getCustomerByIdOrServerId(customerId!);
      if (customer != null) {
        customerNames[customerId] = customer.name;
      }
    }

    await _isar.writeTxn(() async {
      for (final data in serverTransactions) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        // Check if we already have this transaction locally
        final existingTransaction = await _isar.customerTransactionEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        // Get customer name from our lookup map or from the data itself
        final customerId = data['customerId'] as String? ?? '';
        final customerName =
            customerNames[customerId] ??
            (data['customerName'] as String?) ??
            'Unknown Customer';

        if (existingTransaction != null) {
          // If local is modified, don't overwrite (local changes take priority)
          if (existingTransaction.syncStatus == TransactionSyncStatus.synced) {
            // Update with server data
            final updated = _createEntityFromServerData(
              data,
              existingTransaction.id,
              customerName,
            );
            await _isar.customerTransactionEntitys.put(updated);
          }
        } else {
          // New transaction from server
          final entity = _createEntityFromServerData(data, null, customerName);
          await _isar.customerTransactionEntitys.put(entity);
        }
      }
    });

    debugPrint('[TransactionOffline] Import completed');
    notifyListeners();
  }

  /// Create entity from server data
  CustomerTransactionEntity _createEntityFromServerData(
    Map<String, dynamic> data,
    Id? existingId,
    String customerName,
  ) {
    // Map server transaction type to local enum
    TransactionType transactionType;
    final serverType =
        (data['transactionType'] as String?)?.toUpperCase() ?? 'RECEIVED';
    switch (serverType) {
      case 'RECEIVED':
        transactionType = TransactionType.payment;
        break;
      case 'BILL_GENERATED':
        transactionType = TransactionType.billCreated;
        break;
      case 'REFUND':
        transactionType = TransactionType.billReturn;
        break;
      case 'ADJUSTED':
        transactionType = TransactionType.adjustment;
        break;
      default:
        transactionType = TransactionType.payment;
    }

    // Parse dates
    DateTime createdAt;
    if (data['createdAt'] != null) {
      createdAt = data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.parse(data['createdAt'].toString());
    } else {
      createdAt = DateTime.now();
    }

    final entity = CustomerTransactionEntity(
      serverId: data['id'] as String?,
      customerId: (data['customerId'] as String?) ?? '',
      customerName: customerName,
      transactionType: transactionType,
      amount: ((data['amount'] ?? data['balanceAfterTransaction'] ?? 0) as num)
          .toDouble(),
      balanceAfter: ((data['balanceAfterTransaction'] ?? 0) as num).toDouble(),
      referenceId: data['billId'] as String?,
      referenceType: data['billId'] != null ? 'bill' : null,
      description: data['notes'] as String?,
      paymentMethod: data['paymentMode'] as String?,
      transactionDate: createdAt,
      syncStatus: TransactionSyncStatus.synced,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    // Preserve local ID if updating existing record
    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }

  /// Update local transaction with server response after successful push
  Future<void> updateWithServerResponse(
    Id localId,
    Map<String, dynamic> serverResponse,
  ) async {
    final transaction = await _isar.customerTransactionEntitys.get(localId);
    if (transaction == null) return;

    transaction.serverId = serverResponse['id'] as String?;
    transaction.syncStatus = TransactionSyncStatus.synced;
    transaction.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.put(transaction);
    });

    debugPrint(
      '[TransactionOffline] Updated transaction $localId with server ID: ${transaction.serverId}',
    );
  }

  /// Mark a transaction as synced
  Future<void> markAsSynced(Id id) async {
    final transaction = await _isar.customerTransactionEntitys.get(id);
    if (transaction == null) return;

    transaction.syncStatus = TransactionSyncStatus.synced;
    transaction.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.put(transaction);
    });
  }

  /// Permanently delete a transaction (after server confirms deletion)
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.customerTransactionEntitys.delete(id);
    });
    debugPrint('[TransactionOffline] Permanently deleted transaction: $id');
  }

  /// Clear all synced deleted records
  Future<void> clearSyncedDeletedRecords() async {
    final deletedRecords = await _isar.customerTransactionEntitys
        .filter()
        .syncStatusEqualTo(TransactionSyncStatus.deleted)
        .serverIdIsNotNull()
        .findAll();

    if (deletedRecords.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final record in deletedRecords) {
        await _isar.customerTransactionEntitys.delete(record.id);
      }
    });

    debugPrint(
      '[TransactionOffline] Cleared ${deletedRecords.length} synced deleted records',
    );
  }
}
