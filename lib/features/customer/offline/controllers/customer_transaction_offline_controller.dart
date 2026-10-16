import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../entities/customer_transaction_entity.dart';
import '../entities/customer_entity.dart';

/// Controller for handling customer transaction CRUD operations
class CustomerTransactionOfflineController extends ChangeNotifier {
  static CustomerTransactionOfflineController? _instance;

  final AppDatabase _db;

  CustomerTransactionOfflineController._(this._db);

  /// Get the singleton instance
  static CustomerTransactionOfflineController get instance {
    _instance ??= CustomerTransactionOfflineController._(
      LocalDatabase.instance.db,
    );
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

    await _db.transaction(() async {
      await _db.saveTransaction(transaction);

      // Update customer pending amount
      if (customer != null) {
        customer.currentPendingAmount = newPending;
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _db.saveCustomer(customer);
      }
    });

    debugPrint('[TransactionOffline] Payment saved. New pending: $newPending');
    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
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

    await _db.transaction(() async {
      await _db.saveTransaction(transaction);

      // Update customer pending amount
      if (customer != null) {
        customer.currentPendingAmount = newPending;
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _db.saveCustomer(customer);
      }
    });

    debugPrint(
      '[TransactionOffline] Bill transaction saved. New pending: $newPending',
    );
    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
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

    await _db.transaction(() async {
      await _db.saveTransaction(transaction);

      if (customer != null) {
        customer.currentPendingAmount = newPending;
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _db.saveCustomer(customer);
      }
    });

    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
    return transaction;
  }

  // ==================== READ ====================

  /// Get all transactions for a customer
  Future<List<CustomerTransactionEntity>> getTransactionsByCustomerId(
    String customerId,
  ) async {
    final transactions = (await _db.loadTransactions())
        .where(
          (transaction) =>
              transaction.customerId == customerId &&
              transaction.syncStatus != TransactionSyncStatus.deleted,
        )
        .toList();
    transactions.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );
    return transactions;
  }

  /// Get transactions for a customer within date range
  Future<List<CustomerTransactionEntity>> getTransactionsByDateRange({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = (await _db.loadTransactions()).where((transaction) {
      if (transaction.customerId != customerId) return false;
      if (transaction.syncStatus == TransactionSyncStatus.deleted) {
        return false;
      }
      final date = transaction.transactionDate;
      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList();
    transactions.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );
    return transactions;
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
    return _db.watchTransactions().map((rows) {
      final transactions = rows
          .where(
            (transaction) =>
                transaction.customerId == customerId &&
                transaction.syncStatus != TransactionSyncStatus.deleted,
          )
          .toList();
      transactions.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );
      return transactions;
    });
  }

  /// Get transaction by ID
  Future<CustomerTransactionEntity?> getTransactionById(int id) async {
    for (final transaction in await _db.loadTransactions()) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  /// Get total payment received for a customer
  Future<double> getTotalPaymentsReceived(String customerId) async {
    final transactions = (await _db.loadTransactions()).where(
      (transaction) =>
          transaction.customerId == customerId &&
          transaction.transactionType == TransactionType.payment &&
          transaction.syncStatus != TransactionSyncStatus.deleted,
    );

    double total = 0.0;
    for (final t in transactions) {
      total += t.amount;
    }
    return total;
  }

  /// Get total pending count (for summary)
  Future<int> getTotalCount() async {
    return (await _db.loadTransactions())
        .where(
          (transaction) =>
              transaction.syncStatus != TransactionSyncStatus.deleted,
        )
        .length;
  }

  // ==================== UPDATE ====================

  /// Update transaction description
  Future<void> updateTransactionDescription(int id, String description) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) return;

    transaction.description = description;
    transaction.updatedAt = DateTime.now();
    transaction.syncStatus = TransactionSyncStatus.updated;

    await _db.saveTransaction(transaction);

    notifyListeners();
  }

  // ==================== DELETE ====================

  /// Soft delete a transaction
  Future<void> deleteTransaction(int id) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) return;

    // Reverse the effect on customer pending amount
    final customer = await _getCustomerByIdOrServerId(transaction.customerId);

    await _db.transaction(() async {
      transaction.syncStatus = TransactionSyncStatus.deleted;
      transaction.updatedAt = DateTime.now();
      await _db.saveTransaction(transaction);

      // Reverse the transaction effect
      if (customer != null) {
        if (transaction.transactionType == TransactionType.payment) {
          customer.currentPendingAmount += transaction.amount;
        } else {
          customer.currentPendingAmount -= transaction.amount;
        }
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _db.saveCustomer(customer);
      }
    });

    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
  }

  // ==================== HELPERS ====================

  Future<CustomerEntity?> _getCustomerByIdOrServerId(String customerId) async {
    // Try to find by serverId first
    for (final customer in await _db.loadCustomers()) {
      if (customer.serverId == customerId) return customer;
    }

    // If not found, try by local ID
    final localId = int.tryParse(customerId);
    if (localId != null) {
      for (final customer in await _db.loadCustomers()) {
        if (customer.id == localId) return customer;
      }
    }

    return null;
  }

  /// Get unsynced transactions count
  Future<int> getUnsyncedCount() async {
    return (await _db.loadTransactions())
        .where(
          (transaction) => transaction.syncStatus != TransactionSyncStatus.synced,
        )
        .length;
  }

  // ==================== SYNC METHODS ====================

  /// Get transactions that need to be pushed to server
  Future<List<CustomerTransactionEntity>> getTransactionsNeedingPush() async {
    return (await _db.loadTransactions()).where((transaction) {
      return transaction.syncStatus == TransactionSyncStatus.newRecord ||
          transaction.syncStatus == TransactionSyncStatus.updated ||
          transaction.syncStatus == TransactionSyncStatus.deleted;
    }).toList();
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

    await _db.transaction(() async {
      for (final data in serverTransactions) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        // Check if we already have this transaction locally
        CustomerTransactionEntity? existingTransaction;
        for (final transaction in await _db.loadTransactions()) {
          if (transaction.serverId == serverId) {
            existingTransaction = transaction;
            break;
          }
        }

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
            await _db.saveTransaction(updated);
          }
        } else {
          // New transaction from server
          final entity = _createEntityFromServerData(data, null, customerName);
          await _db.saveTransaction(entity);
        }
      }
    });

    debugPrint('[TransactionOffline] Import completed');
    notifyListeners();
  }

  /// Create entity from server data
  CustomerTransactionEntity _createEntityFromServerData(
    Map<String, dynamic> data,
    int? existingId,
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
    int localId,
    Map<String, dynamic> serverResponse,
  ) async {
    final transaction = await getTransactionById(localId);
    if (transaction == null) return;

    transaction.serverId = serverResponse['id'] as String?;
    transaction.syncStatus = TransactionSyncStatus.synced;
    transaction.updatedAt = DateTime.now();

    await _db.saveTransaction(transaction);

    debugPrint(
      '[TransactionOffline] Updated transaction $localId with server ID: ${transaction.serverId}',
    );
  }

  /// Mark a transaction as synced
  Future<void> markAsSynced(int id) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) return;

    transaction.syncStatus = TransactionSyncStatus.synced;
    transaction.updatedAt = DateTime.now();

    await _db.saveTransaction(transaction);
  }

  /// Permanently delete a transaction (after server confirms deletion)
  Future<void> permanentlyDelete(int id) async {
    await _db.deleteTransactionById(id);
    debugPrint('[TransactionOffline] Permanently deleted transaction: $id');
  }

  /// Clear all synced deleted records
  Future<void> clearSyncedDeletedRecords() async {
    final deletedRecords = (await _db.loadTransactions())
        .where(
          (record) =>
              record.syncStatus == TransactionSyncStatus.deleted &&
              record.serverId != null,
        )
        .toList();

    if (deletedRecords.isEmpty) return;

    await _db.transaction(() async {
      for (final record in deletedRecords) {
        await _db.deleteTransactionById(record.id);
      }
    });

    debugPrint(
      '[TransactionOffline] Cleared ${deletedRecords.length} synced deleted records',
    );
  }
}
