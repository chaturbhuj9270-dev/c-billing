import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../../../../core/services/dashboard_refresh_service.dart';
import '../../../../core/utils/date_time_parser.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../billing/offline/entities/bill_entity.dart';
import '../entities/customer_transaction_entity.dart';
import '../entities/customer_entity.dart';

// Controller for handling customer transaction CRUD operations
class CustomerTransactionOfflineController extends ChangeNotifier {
  static CustomerTransactionOfflineController? _instance;

  final AppDatabase _db;

  CustomerTransactionOfflineController._(this._db);

  // Get the singleton instance
  static CustomerTransactionOfflineController get instance {
    _instance ??= CustomerTransactionOfflineController._(
      LocalDatabase.instance.db,
    );
    return _instance!;
  }

  // Reset instance (for testing)
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  // Add a payment transaction (customer paid money)
  Future<CustomerTransactionEntity> addPaymentTransaction({
    required String customerId,
    required String customerName,
    required double amount,
    String? description,
    String? paymentMethod,
    DateTime? transactionDate,
    bool allocateToBills = false,
    String? billId,
  }) async {
    debugPrint(
      '[TransactionOffline] Adding payment: $amount for customer: $customerId',
    );

    final customer = await _getCustomerByIdOrServerId(customerId);
    final now = DateTime.now();

    // Split into per-bill payments so bill delete can reverse the right credits.
    if (allocateToBills && amount > 0 && billId == null) {
      final last = await _allocatePaymentToBillsAsTransactions(
        customer: customer,
        customerId: customerId,
        customerName: customerName,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        transactionDate: transactionDate ?? now,
      );
      notifyListeners();
      DashboardRefreshService.instance.notifyDataChanged(
        DataChangeType.customer,
      );
      return last;
    }

    final currentPending = customer?.currentPendingAmount ?? 0.0;
    final newPending = currentPending - amount;

    final transaction = CustomerTransactionEntity(
      customerId: customerId,
      customerName: customerName,
      transactionType: TransactionType.payment,
      amount: amount,
      balanceAfter: newPending,
      referenceId: billId,
      referenceType: billId != null ? 'bill' : null,
      description: description,
      paymentMethod: paymentMethod,
      transactionDate: transactionDate ?? now,
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

    debugPrint('[TransactionOffline] Payment saved. New pending: $newPending');
    if (allocateToBills && amount > 0 && billId != null) {
      await _allocatePaymentToBills(customer, customerId, amount);
    }
    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
    return transaction;
  }

  // Add a bill transaction (customer owes money)
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

  Future<List<BillEntity>> _openBillsForCustomer(
    CustomerEntity? customer,
    String customerId,
  ) async {
    final ids = <String>{customerId};
    if (customer != null) {
      final serverId = customer.serverId;
      if (serverId != null && serverId.isNotEmpty) ids.add(serverId);
      ids.add('local_${customer.id}');
      ids.add('${customer.id}');
    }

    final billsController = BillOfflineController.instance;
    final seen = <int>{};
    final bills = <BillEntity>[];
    for (final id in ids) {
      if (id.isEmpty) continue;
      for (final bill in await billsController.getBillsByCustomerId(id)) {
        if (bill.pendingAmount > 0.009 && seen.add(bill.id)) {
          bills.add(bill);
        }
      }
    }
    bills.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return bills;
  }

  // Apply a later payment to the oldest open bills so invoice balances match the ledger.
  Future<void> _allocatePaymentToBills(
    CustomerEntity? customer,
    String customerId,
    double amount,
  ) async {
    final bills = await _openBillsForCustomer(customer, customerId);
    var remaining = amount;
    var appliedAny = false;
    final billsController = BillOfflineController.instance;
    for (final bill in bills) {
      if (remaining <= 0.009) break;
      final applied = remaining > bill.pendingAmount
          ? bill.pendingAmount
          : remaining;
      final pending = bill.pendingAmount - applied;
      await billsController.updateBill(
        id: bill.id,
        paidAmount: bill.paidAmount + applied,
        pendingAmount: pending <= 0.009 ? 0 : pending,
        paymentStatus: pending <= 0.009
            ? BillPaymentStatus.paid
            : BillPaymentStatus.partiallyPaid,
      );
      remaining -= applied;
      appliedAny = true;
    }
    if (appliedAny) {
      DashboardRefreshService.instance.notifyDataChanged(DataChangeType.bill);
    }
  }

  /// Create one payment ledger row per bill (plus remainder as advance).
  Future<CustomerTransactionEntity> _allocatePaymentToBillsAsTransactions({
    required CustomerEntity? customer,
    required String customerId,
    required String customerName,
    required double amount,
    String? description,
    String? paymentMethod,
    required DateTime transactionDate,
  }) async {
    final bills = await _openBillsForCustomer(customer, customerId);
    final billsController = BillOfflineController.instance;
    var remaining = amount;
    var runningPending = customer?.currentPendingAmount ?? 0.0;
    CustomerTransactionEntity? last;

    for (final bill in bills) {
      if (remaining <= 0.009) break;
      final applied = remaining > bill.pendingAmount
          ? bill.pendingAmount
          : remaining;
      runningPending -= applied;
      final billKey = bill.serverId ?? 'local_${bill.id}';
      final tx = CustomerTransactionEntity(
        customerId: customerId,
        customerName: customer?.name ?? customerName,
        transactionType: TransactionType.payment,
        amount: applied,
        balanceAfter: runningPending,
        referenceId: billKey,
        referenceType: 'bill',
        description: description ?? 'Payment for bill $billKey',
        paymentMethod: paymentMethod,
        transactionDate: transactionDate,
        createdAt: transactionDate,
        updatedAt: transactionDate,
      );
      await _db.saveTransaction(tx);
      last = tx;

      final pending = bill.pendingAmount - applied;
      await billsController.updateBill(
        id: bill.id,
        paidAmount: bill.paidAmount + applied,
        pendingAmount: pending <= 0.009 ? 0 : pending,
        paymentStatus: pending <= 0.009
            ? BillPaymentStatus.paid
            : BillPaymentStatus.partiallyPaid,
      );
      remaining -= applied;
    }

    if (remaining > 0.009) {
      runningPending -= remaining;
      last = CustomerTransactionEntity(
        customerId: customerId,
        customerName: customer?.name ?? customerName,
        transactionType: TransactionType.payment,
        amount: remaining,
        balanceAfter: runningPending,
        description: description ?? 'Advance payment',
        paymentMethod: paymentMethod,
        transactionDate: transactionDate,
        createdAt: transactionDate,
        updatedAt: transactionDate,
      );
      await _db.saveTransaction(last);
    }

    if (customer != null) {
      customer.currentPendingAmount = runningPending;
      customer.updatedAt = DateTime.now();
      customer.isSynced = false;
      await _db.saveCustomer(customer);
    }

    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.bill);

    // Fallback if no open bills — single unallocated payment.
    if (last == null) {
      return addPaymentTransaction(
        customerId: customerId,
        customerName: customerName,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        transactionDate: transactionDate,
        allocateToBills: false,
      );
    }
    return last;
  }

  // Reduce what the customer owes after a sale return.
  Future<CustomerTransactionEntity> addReturnTransaction({
    required String customerId,
    required String customerName,
    required double amount,
    required String billId,
    String? description,
  }) async {
    debugPrint(
      '[TransactionOffline] Adding return: $amount for customer: $customerId',
    );

    final customer = await _getCustomerByIdOrServerId(customerId);
    final currentPending = customer?.currentPendingAmount ?? 0.0;
    final newPending = currentPending - amount;
    final now = DateTime.now();
    final transaction = CustomerTransactionEntity(
      customerId: customerId,
      customerName: customer?.name ?? customerName,
      transactionType: TransactionType.billReturn,
      amount: amount,
      balanceAfter: newPending,
      referenceId: billId,
      referenceType: 'bill',
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

    debugPrint('[TransactionOffline] Return saved. New pending: $newPending');
    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
    return transaction;
  }

  // Add manual adjustment transaction
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

  Future<Set<String>> _aliasesForCustomerKey(String customerId) async {
    final customer = await _getCustomerByIdOrServerId(customerId);
    if (customer != null) return customerIdAliases(customer);
    final keys = <String>{customerId};
    if (customerId.startsWith('local_')) {
      keys.add(customerId.substring(6));
    } else {
      keys.add('local_$customerId');
    }
    return keys;
  }

  // Get all transactions for a customer (matches serverId / local_ / numeric)
  Future<List<CustomerTransactionEntity>> getTransactionsByCustomerId(
    String customerId,
  ) async {
    final keys = await _aliasesForCustomerKey(customerId);
    final transactions = (await _db.loadTransactions())
        .where(
          (transaction) =>
              keys.contains(transaction.customerId) &&
              transaction.syncStatus != TransactionSyncStatus.deleted,
        )
        .toList();
    transactions.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );
    return transactions;
  }

  // Get transactions for a customer within date range
  Future<List<CustomerTransactionEntity>> getTransactionsByDateRange({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final keys = await _aliasesForCustomerKey(customerId);
    final transactions = (await _db.loadTransactions()).where((transaction) {
      if (!keys.contains(transaction.customerId)) return false;
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

  // Get transactions for this month
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

  // Get transactions for this year
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

  // Get transactions for last year
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

  // Watch transactions for a customer
  Stream<List<CustomerTransactionEntity>> watchTransactionsByCustomerId(
    String customerId,
  ) async* {
    // Resolve aliases once; fall back to exact id if customer row is missing.
    Set<String> keys;
    try {
      keys = await _aliasesForCustomerKey(customerId);
    } catch (_) {
      keys = {customerId};
    }
    await for (final rows in _db.watchTransactions()) {
      final transactions = rows
          .where(
            (transaction) =>
                keys.contains(transaction.customerId) &&
                transaction.syncStatus != TransactionSyncStatus.deleted,
          )
          .toList();
      transactions.sort(
        (a, b) => b.transactionDate.compareTo(a.transactionDate),
      );
      yield transactions;
    }
  }

  // Get transaction by ID
  Future<CustomerTransactionEntity?> getTransactionById(int id) async {
    for (final transaction in await _db.loadTransactions()) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  // Get total payment received for a customer
  Future<double> getTotalPaymentsReceived(String customerId) async {
    final keys = await _aliasesForCustomerKey(customerId);
    final transactions = (await _db.loadTransactions()).where(
      (transaction) =>
          keys.contains(transaction.customerId) &&
          transaction.transactionType == TransactionType.payment &&
          transaction.syncStatus != TransactionSyncStatus.deleted,
    );

    double total = 0.0;
    for (final t in transactions) {
      total += t.amount;
    }
    return total;
  }

  // Get total pending count (for summary)
  Future<int> getTotalCount() async {
    return (await _db.loadTransactions())
        .where(
          (transaction) =>
              transaction.syncStatus != TransactionSyncStatus.deleted,
        )
        .length;
  }

  // ==================== UPDATE ====================

  // Update transaction description
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

  // Soft delete a transaction
  Future<void> deleteTransaction(int id) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) return;

    // Reverse the effect on customer pending amount
    final customer = await _getCustomerByIdOrServerId(transaction.customerId);

    await _db.transaction(() async {
      transaction.syncStatus = TransactionSyncStatus.deleted;
      transaction.updatedAt = DateTime.now();
      await _db.saveTransaction(transaction);

      // Reverse the original effect:
      // - billCreated / positive adjustment increased pending → subtract
      // - payment / billReturn decreased pending → add back
      // - signed adjustment: reverse by subtracting the signed amount
      if (customer != null) {
        switch (transaction.transactionType) {
          case TransactionType.payment:
          case TransactionType.billReturn:
            customer.currentPendingAmount += transaction.amount;
            break;
          case TransactionType.billCreated:
            customer.currentPendingAmount -= transaction.amount;
            break;
          case TransactionType.adjustment:
            customer.currentPendingAmount -= transaction.amount;
            break;
        }
        customer.updatedAt = DateTime.now();
        customer.isSynced = false;
        await _db.saveCustomer(customer);
      }
    });

    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
  }

  /// Reverse all ledger rows tied to a bill (on bill delete).
  /// Returns the sum of payment amounts that were reversed (for orphan detection).
  Future<double> reverseTransactionsForBill(String billId) async {
    if (billId.isEmpty) return 0;
    final keys = <String>{billId};
    if (billId.startsWith('local_')) {
      keys.add(billId.substring(6));
    } else {
      keys.add('local_$billId');
    }

    final matches = (await _db.loadTransactions()).where((tx) {
      if (tx.syncStatus == TransactionSyncStatus.deleted) return false;
      final ref = tx.referenceId;
      if (ref != null && keys.contains(ref)) return true;
      final desc = tx.description ?? '';
      for (final key in keys) {
        if (desc.contains('Bill #$key') || desc.contains('bill $key')) {
          return true;
        }
      }
      return false;
    }).toList();

    var reversedPayments = 0.0;
    for (final tx in matches) {
      if (tx.transactionType == TransactionType.payment) {
        reversedPayments += tx.amount;
      }
      await deleteTransaction(tx.id);
    }
    return reversedPayments;
  }

  /// After a Firebase write, stamp the local row so sync will not create a duplicate.
  Future<void> markSyncedWithServerId(int localId, String serverId) async {
    final transaction = await getTransactionById(localId);
    if (transaction == null) return;
    transaction.serverId = serverId;
    transaction.syncStatus = TransactionSyncStatus.synced;
    transaction.updatedAt = DateTime.now();
    await _db.saveTransaction(transaction);
  }

  // ==================== HELPERS ====================

  /// All ID forms that may appear on ledger rows for one customer.
  Set<String> customerIdAliases(CustomerEntity customer) {
    final keys = <String>{'local_${customer.id}', '${customer.id}'};
    final serverId = customer.serverId;
    if (serverId != null && serverId.isNotEmpty) keys.add(serverId);
    return keys;
  }

  /// Resolve `serverId`, numeric local id, or `local_<id>` billing keys.
  Future<CustomerEntity?> _getCustomerByIdOrServerId(String customerId) async {
    final raw = customerId.trim();
    if (raw.isEmpty) return null;

    final customers = await _db.loadCustomers();

    for (final customer in customers) {
      if (customer.serverId == raw) return customer;
    }

    var localId = int.tryParse(raw);
    if (localId == null && raw.startsWith('local_')) {
      localId = int.tryParse(raw.substring(6));
    }
    if (localId != null) {
      for (final customer in customers) {
        if (customer.id == localId) return customer;
      }
    }

    return null;
  }

  /// Rebuild receivable from non-deleted ledger rows (source of truth).
  Future<double> recomputeCustomerPending(String customerId) async {
    final customer = await _getCustomerByIdOrServerId(customerId);
    if (customer == null) return 0;

    final keys = customerIdAliases(customer);
    double pending = 0;
    for (final tx in await _db.loadTransactions()) {
      if (tx.syncStatus == TransactionSyncStatus.deleted) continue;
      if (!keys.contains(tx.customerId)) continue;
      switch (tx.transactionType) {
        case TransactionType.billCreated:
          pending += tx.amount;
        case TransactionType.payment:
        case TransactionType.billReturn:
          pending -= tx.amount;
        case TransactionType.adjustment:
          pending += tx.amount; // signed amount
      }
    }

    customer.currentPendingAmount = pending;
    customer.updatedAt = DateTime.now();
    customer.isSynced = false;
    await _db.saveCustomer(customer);
    notifyListeners();
    DashboardRefreshService.instance.notifyDataChanged(DataChangeType.customer);
    return pending;
  }

  // Get unsynced transactions count
  Future<int> getUnsyncedCount() async {
    return (await _db.loadTransactions())
        .where(
          (transaction) => transaction.syncStatus != TransactionSyncStatus.synced,
        )
        .length;
  }

  // ==================== SYNC METHODS ====================

  // Get transactions that need to be pushed to server
  Future<List<CustomerTransactionEntity>> getTransactionsNeedingPush() async {
    return (await _db.loadTransactions()).where((transaction) {
      return transaction.syncStatus == TransactionSyncStatus.newRecord ||
          transaction.syncStatus == TransactionSyncStatus.updated ||
          transaction.syncStatus == TransactionSyncStatus.deleted;
    }).toList();
  }

  // Import transactions from server This will upsert based on serverId
  Future<void> importFromServer(
    List<Map<String, dynamic>> serverTransactions,
  ) async {
    if (serverTransactions.isEmpty) return;

    debugPrint(
      '[TransactionOffline] Importing ${serverTransactions.length} transactions from server',
    );

    // First, build a map of customer IDs to names This needs to be done outside the write transaction
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
          // Link unsynced local twin (same bill + type + amount) instead of duplicating.
          final twin = await _findUnsyncedTwin(data);
          if (twin != null) {
            twin.serverId = serverId;
            twin.syncStatus = TransactionSyncStatus.synced;
            twin.updatedAt = DateTime.now();
            await _db.saveTransaction(twin);
          } else {
            final entity = _createEntityFromServerData(data, null, customerName);
            if (entity.amount.abs() > 0.009) {
              await _db.saveTransaction(entity);
            }
          }
        }
      }
    });

    // Keep receivable balances aligned with imported ledger rows.
    for (final customerId in uniqueCustomerIds) {
      try {
        await recomputeCustomerPending(customerId!);
      } catch (e) {
        debugPrint(
          '[TransactionOffline] Pending recompute failed for $customerId: $e',
        );
      }
    }

    debugPrint('[TransactionOffline] Import completed');
    notifyListeners();
  }

  /// Match an unsynced local row to a server txn to avoid double-counting on pull.
  Future<CustomerTransactionEntity?> _findUnsyncedTwin(
    Map<String, dynamic> data,
  ) async {
    final billId = data['billId'] as String?;
    final customerId = (data['customerId'] as String?) ?? '';
    final amount = (data['amount'] as num?)?.toDouble();
    if (amount == null || customerId.isEmpty) return null;

    final serverType =
        (data['transactionType'] as String?)?.toUpperCase() ?? '';
    final TransactionType? expected = switch (serverType) {
      'RECEIVED' => TransactionType.payment,
      'BILL_GENERATED' => TransactionType.billCreated,
      'REFUND' => TransactionType.billReturn,
      'ADJUSTED' => TransactionType.adjustment,
      _ => null,
    };
    if (expected == null) return null;

    // Firebase ADJUSTED is always a credit; local stores signed amount.
    final matchAmount = expected == TransactionType.adjustment
        ? -amount.abs()
        : amount;

    final aliases = await _aliasesForCustomerKey(customerId);
    for (final tx in await _db.loadTransactions()) {
      if (tx.syncStatus != TransactionSyncStatus.newRecord) continue;
      if (tx.serverId != null) continue;
      if (tx.transactionType != expected) continue;
      if (!aliases.contains(tx.customerId) && tx.customerId != customerId) {
        continue;
      }
      if ((tx.amount - matchAmount).abs() > 0.05) continue;
      if (billId != null && billId.isNotEmpty) {
        final ref = tx.referenceId;
        if (ref != null &&
            ref != billId &&
            ref != 'local_$billId' &&
            billId != 'local_$ref') {
          continue;
        }
      }
      return tx;
    }
    return null;
  }

  // Create entity from server data
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

    final createdAt = parseFlexibleDateTimeOrNow(data['createdAt']);

    // Never fall back to balanceAfter — that corrupts recompute.
    var amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    // Firebase ADJUSTED always reduces pending; offline recompute uses signed +=.
    if (transactionType == TransactionType.adjustment && amount > 0) {
      amount = -amount;
    }

    final entity = CustomerTransactionEntity(
      serverId: data['id'] as String?,
      customerId: (data['customerId'] as String?) ?? '',
      customerName: customerName,
      transactionType: transactionType,
      amount: amount,
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

  // Update local transaction with server response after successful push
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

  // Mark a transaction as synced
  Future<void> markAsSynced(int id) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) return;

    transaction.syncStatus = TransactionSyncStatus.synced;
    transaction.updatedAt = DateTime.now();

    await _db.saveTransaction(transaction);
  }

  // Permanently delete a transaction (after server confirms deletion)
  Future<void> permanentlyDelete(int id) async {
    await _db.deleteTransactionById(id);
    debugPrint('[TransactionOffline] Permanently deleted transaction: $id');
  }

  // Clear all synced deleted records
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
