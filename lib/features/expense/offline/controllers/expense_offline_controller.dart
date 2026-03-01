import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/expense_entity.dart';

/// Offline-first controller for Expense CRUD operations
/// All operations go to local Isar first, then sync in background
class ExpenseOfflineController extends ChangeNotifier {
  static ExpenseOfflineController? _instance;

  final Isar _isar;

  ExpenseOfflineController._(this._isar);

  /// Get the singleton instance
  static ExpenseOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = ExpenseOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Add a new expense locally
  Future<ExpenseEntity> addExpense({
    required String title,
    String? description,
    required ExpenseCategory category,
    required double amount,
    String? paymentMethod,
    String? vendorName,
    String? receiptNumber,
    bool isRecurring = false,
    DateTime? expenseDate,
    String? notes,
  }) async {
    debugPrint('[ExpenseOffline] Adding expense: $title, amount: $amount');

    final expense = ExpenseEntity.create(
      title: title,
      description: description,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      vendorName: vendorName,
      receiptNumber: receiptNumber,
      isRecurring: isRecurring,
      expenseDate: expenseDate,
      notes: notes,
    );

    await _isar.writeTxn(() async {
      await _isar.expenseEntitys.put(expense);
    });

    debugPrint('[ExpenseOffline] Expense saved with id: ${expense.id}');
    notifyListeners();
    return expense;
  }

  /// Import expense from server (for sync)
  Future<ExpenseEntity> importFromServer(ExpenseEntity expense) async {
    await _isar.writeTxn(() async {
      // Check if already exists by serverId
      final existing = await _isar.expenseEntitys
          .filter()
          .serverIdEqualTo(expense.serverId)
          .findFirst();

      if (existing != null) {
        expense.id = existing.id;
      }
      await _isar.expenseEntitys.put(expense);
    });

    notifyListeners();
    return expense;
  }

  // ==================== READ ====================

  /// Get all active expenses (not deleted)
  Future<List<ExpenseEntity>> getAllExpenses() async {
    return await _isar.expenseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expense by local ID
  Future<ExpenseEntity?> getExpenseById(Id id) async {
    return await _isar.expenseEntitys.get(id);
  }

  /// Get expense by server ID
  Future<ExpenseEntity?> getExpenseByServerId(String serverId) async {
    return await _isar.expenseEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get expenses by category
  Future<List<ExpenseEntity>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    return await _isar.expenseEntitys
        .filter()
        .categoryEqualTo(category)
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expenses for this month
  Future<List<ExpenseEntity>> getThisMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return await _isar.expenseEntitys
        .filter()
        .expenseDateBetween(startOfMonth, endOfMonth)
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expenses for this year
  Future<List<ExpenseEntity>> getThisYearExpenses() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return await _isar.expenseEntitys
        .filter()
        .expenseDateBetween(startOfYear, endOfYear)
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expenses for last year
  Future<List<ExpenseEntity>> getLastYearExpenses() async {
    final now = DateTime.now();
    final startOfLastYear = DateTime(now.year - 1, 1, 1);
    final endOfLastYear = DateTime(now.year - 1, 12, 31, 23, 59, 59);

    return await _isar.expenseEntitys
        .filter()
        .expenseDateBetween(startOfLastYear, endOfLastYear)
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expenses by date range
  Future<List<ExpenseEntity>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _isar.expenseEntitys
        .filter()
        .expenseDateBetween(startDate, endDate)
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expenses by category and date range
  Future<List<ExpenseEntity>> getExpensesByCategoryAndDateRange({
    required ExpenseCategory category,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _isar.expenseEntitys
        .filter()
        .categoryEqualTo(category)
        .expenseDateBetween(startDate, endDate)
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get recent expenses (last N)
  Future<List<ExpenseEntity>> getRecentExpenses({int limit = 50}) async {
    return await _isar.expenseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .limit(limit)
        .findAll();
  }

  /// Watch all expenses (reactive stream)
  Stream<List<ExpenseEntity>> watchAllExpenses() {
    return _isar.expenseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .sortByExpenseDateDesc()
        .watch(fireImmediately: true);
  }

  /// Get total expense amount for a period
  Future<double> getTotalExpenseAmount({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
  }) async {
    var query = _isar.expenseEntitys.filter().not().syncStatusEqualTo(
      ExpenseSyncStatus.deleted,
    );

    if (category != null) {
      query = query.categoryEqualTo(category);
    }

    if (startDate != null && endDate != null) {
      query = query.expenseDateBetween(startDate, endDate);
    }

    final expenses = await query.findAll();
    double total = 0.0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }

  /// Get expense count
  Future<int> getExpenseCount() async {
    return await _isar.expenseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.deleted)
        .count();
  }

  /// Get expenses grouped by category with totals
  Future<Map<ExpenseCategory, double>> getExpenseTotalsByCategory() async {
    final expenses = await getAllExpenses();
    final Map<ExpenseCategory, double> categoryTotals = {};

    for (final category in ExpenseCategory.values) {
      categoryTotals[category] = 0.0;
    }

    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    return categoryTotals;
  }

  // ==================== UPDATE ====================

  /// Update an existing expense
  Future<ExpenseEntity?> updateExpense({
    required Id id,
    String? title,
    String? description,
    ExpenseCategory? category,
    double? amount,
    String? paymentMethod,
    String? vendorName,
    String? receiptNumber,
    bool? isRecurring,
    DateTime? expenseDate,
    String? notes,
  }) async {
    final existing = await _isar.expenseEntitys.get(id);
    if (existing == null) {
      debugPrint('[ExpenseOffline] Expense not found: $id');
      return null;
    }

    // Determine new syncStatus
    ExpenseSyncStatus newSyncStatus;
    switch (existing.syncStatus) {
      case ExpenseSyncStatus.newRecord:
        newSyncStatus = ExpenseSyncStatus.newRecord;
        break;
      case ExpenseSyncStatus.synced:
        newSyncStatus = ExpenseSyncStatus.updated;
        break;
      case ExpenseSyncStatus.updated:
        newSyncStatus = ExpenseSyncStatus.updated;
        break;
      case ExpenseSyncStatus.deleted:
        newSyncStatus = ExpenseSyncStatus.deleted;
        break;
    }

    final updated = existing.copyWith(
      title: title,
      description: description,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      vendorName: vendorName,
      receiptNumber: receiptNumber,
      isRecurring: isRecurring,
      expenseDate: expenseDate,
      notes: notes,
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.expenseEntitys.put(updated);
    });

    debugPrint('[ExpenseOffline] Expense updated: $id');
    notifyListeners();
    return updated;
  }

  /// Mark expense as synced (after successful server sync)
  Future<void> markAsSynced(Id id, String serverId) async {
    final expense = await _isar.expenseEntitys.get(id);
    if (expense == null) return;

    expense.serverId = serverId;
    expense.syncStatus = ExpenseSyncStatus.synced;
    expense.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.expenseEntitys.put(expense);
    });

    notifyListeners();
  }

  // ==================== DELETE ====================

  /// Soft delete an expense (marks for deletion)
  Future<void> deleteExpense(Id id) async {
    final expense = await _isar.expenseEntitys.get(id);
    if (expense == null) {
      debugPrint('[ExpenseOffline] Expense not found for deletion: $id');
      return;
    }

    // If never synced (NEW), just hard delete
    if (expense.syncStatus == ExpenseSyncStatus.newRecord) {
      await _isar.writeTxn(() async {
        await _isar.expenseEntitys.delete(id);
      });
      debugPrint(
        '[ExpenseOffline] Expense hard deleted (was never synced): $id',
      );
    } else {
      // Mark for deletion (sync will handle server delete)
      expense.syncStatus = ExpenseSyncStatus.deleted;
      expense.updatedAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.expenseEntitys.put(expense);
      });
      debugPrint('[ExpenseOffline] Expense marked for deletion: $id');
    }

    notifyListeners();
  }

  /// Hard delete after server confirms deletion
  Future<void> hardDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.expenseEntitys.delete(id);
    });
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all expenses pending sync (NEW, UPDATED, or DELETED)
  Future<List<ExpenseEntity>> getPendingSyncExpenses() async {
    return await _isar.expenseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.synced)
        .findAll();
  }

  /// Get count of expenses pending sync
  Future<int> getPendingSyncCount() async {
    return await _isar.expenseEntitys
        .filter()
        .not()
        .syncStatusEqualTo(ExpenseSyncStatus.synced)
        .count();
  }

  /// Check if there are any pending syncs
  Future<bool> hasPendingSyncs() async {
    return (await getPendingSyncCount()) > 0;
  }
}
