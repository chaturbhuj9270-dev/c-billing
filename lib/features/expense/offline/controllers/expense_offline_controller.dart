import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/expense_entity.dart';

/// Offline-first controller for Expense CRUD operations.
/// All operations go to the local database first, then sync in the background.
class ExpenseOfflineController extends ChangeNotifier {
  static ExpenseOfflineController? _instance;

  final AppDatabase _db;

  ExpenseOfflineController._(this._db);

  /// Get the singleton instance
  static ExpenseOfflineController get instance {
    _instance ??= ExpenseOfflineController._(LocalDatabase.instance.db);
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

    await _db.saveExpense(expense);

    debugPrint('[ExpenseOffline] Expense saved with id: ${expense.id}');
    notifyListeners();
    return expense;
  }

  /// Import expense from server (for sync)
  Future<ExpenseEntity> importFromServer(ExpenseEntity expense) async {
    // Check if already exists by serverId
    for (final row in await _db.loadExpenses()) {
      if (row.serverId == expense.serverId) {
        expense.id = row.id;
        break;
      }
    }
    await _db.saveExpense(expense);

    notifyListeners();
    return expense;
  }

  // ==================== READ ====================

  /// Get all active expenses (not deleted)
  Future<List<ExpenseEntity>> getAllExpenses() async {
    final expenses = (await _db.loadExpenses())
        .where((expense) => expense.syncStatus != ExpenseSyncStatus.deleted)
        .toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  /// Get expense by local ID
  Future<ExpenseEntity?> getExpenseById(int id) async {
    for (final expense in await _db.loadExpenses()) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  /// Get expense by server ID
  Future<ExpenseEntity?> getExpenseByServerId(String serverId) async {
    for (final expense in await _db.loadExpenses()) {
      if (expense.serverId == serverId) return expense;
    }
    return null;
  }

  /// Get expenses by category
  Future<List<ExpenseEntity>> getExpensesByCategory(
    ExpenseCategory category,
  ) async {
    final expenses = (await _db.loadExpenses()).where((expense) {
      return expense.category == category &&
          expense.syncStatus != ExpenseSyncStatus.deleted;
    }).toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  /// Get expenses for this month
  Future<List<ExpenseEntity>> getThisMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _expensesBetween(startOfMonth, endOfMonth);
  }

  /// Get expenses for this year
  Future<List<ExpenseEntity>> getThisYearExpenses() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return _expensesBetween(startOfYear, endOfYear);
  }

  /// Get expenses for last year
  Future<List<ExpenseEntity>> getLastYearExpenses() async {
    final now = DateTime.now();
    final startOfLastYear = DateTime(now.year - 1, 1, 1);
    final endOfLastYear = DateTime(now.year - 1, 12, 31, 23, 59, 59);

    return _expensesBetween(startOfLastYear, endOfLastYear);
  }

  /// Get expenses by date range
  Future<List<ExpenseEntity>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _expensesBetween(startDate, endDate);
  }

  /// Get expenses by category and date range
  Future<List<ExpenseEntity>> getExpensesByCategoryAndDateRange({
    required ExpenseCategory category,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final expenses = (await _db.loadExpenses()).where((expense) {
      if (expense.category != category) return false;
      if (expense.syncStatus == ExpenseSyncStatus.deleted) return false;
      return !expense.expenseDate.isBefore(startDate) &&
          !expense.expenseDate.isAfter(endDate);
    }).toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  /// Get recent expenses (last N)
  Future<List<ExpenseEntity>> getRecentExpenses({int limit = 50}) async {
    final expenses = (await _db.loadExpenses())
        .where((expense) => expense.syncStatus != ExpenseSyncStatus.deleted)
        .toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses.take(limit).toList();
  }

  /// Watch all expenses (reactive stream)
  Stream<List<ExpenseEntity>> watchAllExpenses() {
    return _db.watchExpenses().map((rows) {
      final expenses = rows
          .where((expense) => expense.syncStatus != ExpenseSyncStatus.deleted)
          .toList();
      expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return expenses;
    });
  }

  /// Get total expense amount for a period
  Future<double> getTotalExpenseAmount({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
  }) async {
    final expenses = (await _db.loadExpenses()).where((expense) {
      if (expense.syncStatus == ExpenseSyncStatus.deleted) return false;
      if (category != null && expense.category != category) return false;
      if (startDate != null && endDate != null) {
        return !expense.expenseDate.isBefore(startDate) &&
            !expense.expenseDate.isAfter(endDate);
      }
      return true;
    });

    double total = 0.0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }

  /// Get expense count
  Future<int> getExpenseCount() async {
    return (await _db.loadExpenses())
        .where((expense) => expense.syncStatus != ExpenseSyncStatus.deleted)
        .length;
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
    required int id,
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
    final existing = await getExpenseById(id);
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

    await _db.saveExpense(updated);

    debugPrint('[ExpenseOffline] Expense updated: $id');
    notifyListeners();
    return updated;
  }

  /// Mark expense as synced (after successful server sync)
  Future<void> markAsSynced(int id, String serverId) async {
    final expense = await getExpenseById(id);
    if (expense == null) return;

    expense.serverId = serverId;
    expense.syncStatus = ExpenseSyncStatus.synced;
    expense.updatedAt = DateTime.now();

    await _db.saveExpense(expense);

    notifyListeners();
  }

  // ==================== DELETE ====================

  /// Soft delete an expense (marks for deletion)
  Future<void> deleteExpense(int id) async {
    final expense = await getExpenseById(id);
    if (expense == null) {
      debugPrint('[ExpenseOffline] Expense not found for deletion: $id');
      return;
    }

    // If never synced (NEW), just hard delete
    if (expense.syncStatus == ExpenseSyncStatus.newRecord) {
      await _db.deleteExpenseById(id);
      debugPrint(
        '[ExpenseOffline] Expense hard deleted (was never synced): $id',
      );
    } else {
      // Mark for deletion (sync will handle server delete)
      expense.syncStatus = ExpenseSyncStatus.deleted;
      expense.updatedAt = DateTime.now();

      await _db.saveExpense(expense);
      debugPrint('[ExpenseOffline] Expense marked for deletion: $id');
    }

    notifyListeners();
  }

  /// Hard delete after server confirms deletion
  Future<void> hardDelete(int id) async {
    await _db.deleteExpenseById(id);
    notifyListeners();
  }

  // ==================== SYNC HELPERS ====================

  /// Get all expenses pending sync (NEW, UPDATED, or DELETED)
  Future<List<ExpenseEntity>> getPendingSyncExpenses() async {
    return (await _db.loadExpenses())
        .where((expense) => expense.syncStatus != ExpenseSyncStatus.synced)
        .toList();
  }

  /// Get count of expenses pending sync
  Future<int> getPendingSyncCount() async {
    return (await _db.loadExpenses())
        .where((expense) => expense.syncStatus != ExpenseSyncStatus.synced)
        .length;
  }

  /// Check if there are any pending syncs
  Future<bool> hasPendingSyncs() async {
    return (await getPendingSyncCount()) > 0;
  }

  Future<List<ExpenseEntity>> _expensesBetween(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final expenses = (await _db.loadExpenses()).where((expense) {
      if (expense.syncStatus == ExpenseSyncStatus.deleted) return false;
      return !expense.expenseDate.isBefore(startDate) &&
          !expense.expenseDate.isAfter(endDate);
    }).toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }
}
