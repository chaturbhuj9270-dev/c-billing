import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/stock_ledger_entity.dart';

/// Offline-first controller for Stock Ledger operations
/// Records every stock movement for complete audit trail
class StockLedgerOfflineController extends ChangeNotifier {
  static StockLedgerOfflineController? _instance;

  final Isar _isar;

  StockLedgerOfflineController._(this._isar);

  /// Get the singleton instance
  static StockLedgerOfflineController get instance {
    if (_instance == null) {
      final isar = IsarService.instance.isar;
      _instance = StockLedgerOfflineController._(isar);
    }
    return _instance!;
  }

  /// Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  /// Record a new stock transaction in the ledger
  Future<StockLedgerEntity> recordTransaction({
    required String productId,
    required String productName,
    required String batchId,
    required String batchNumber,
    required TransactionType transactionType,
    required double quantity,
    required double balanceAfter,
    String? purchaseId,
    String? billId,
    required double pricePerUnit,
    String? reference,
    String? notes,
  }) async {
    final entry = StockLedgerEntity.create(
      productId: productId,
      productName: productName,
      batchId: batchId,
      batchNumber: batchNumber,
      transactionType: transactionType,
      quantity: quantity,
      balanceAfter: balanceAfter,
      purchaseId: purchaseId,
      billId: billId,
      pricePerUnit: pricePerUnit,
      reference: reference,
      notes: notes,
      syncStatus: LedgerSyncStatus.newRecord,
    );

    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.put(entry);
    });

    debugPrint('[LedgerOffline] Transaction recorded: ${entry.id}, '
        'type: ${entry.transactionType.name}, product: ${entry.productName}, '
        'batch: ${entry.batchNumber}, qty: ${entry.quantity}, '
        'balance: ${entry.balanceAfter}');
    notifyListeners();
    return entry;
  }

  // ==================== READ ====================

  /// Get all transactions (excluding deleted)
  Future<List<StockLedgerEntity>> getAllTransactions() async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Watch all transactions for real-time updates
  Stream<List<StockLedgerEntity>> watchAllTransactions() {
    return _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .watch(fireImmediately: true);
  }

  /// Get transactions by product ID
  Future<List<StockLedgerEntity>> getTransactionsByProduct(String productId) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Watch transactions by product ID (real-time stream)
  Stream<List<StockLedgerEntity>> watchTransactionsByProduct(String productId) {
    return _isar.stockLedgerEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .watch(fireImmediately: true);
  }

  /// Get transactions by batch ID
  Future<List<StockLedgerEntity>> getTransactionsByBatch(String batchId) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .batchIdEqualTo(batchId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get transactions by date range
  Future<List<StockLedgerEntity>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .transactionDateBetween(startDate, endDate)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get transactions by type
  Future<List<StockLedgerEntity>> getTransactionsByType(TransactionType type) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .transactionTypeEqualTo(type)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get recent transactions (last N)
  Future<List<StockLedgerEntity>> getRecentTransactions({int limit = 50}) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .limit(limit)
        .findAll();
  }

  /// Get ledger entry by local Isar ID
  Future<StockLedgerEntity?> getEntryById(Id id) async {
    return await _isar.stockLedgerEntitys.get(id);
  }

  // ==================== SYNC HELPERS ====================

  /// Get all ledger entries that need to be synced to server
  Future<List<StockLedgerEntity>> getLedgerNeedingSync() async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.synced)
        .findAll();
  }

  /// Get count of unsynced ledger entries
  Future<int> getUnsyncedCount() async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.synced)
        .count();
  }

  /// Mark a ledger entry as synced (after successful server sync)
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.stockLedgerEntitys.get(id);
    if (existing == null) return;

    await _isar.writeTxn(() async {
      existing.serverId = serverId;
      existing.syncStatus = LedgerSyncStatus.synced;
      await _isar.stockLedgerEntitys.put(existing);
    });

    debugPrint('[LedgerOffline] Entry marked as synced: $id -> $serverId');
  }

  /// Import ledger entries from server (initial load or refresh)
  Future<void> importFromServer(List<Map<String, dynamic>> serverEntries) async {
    await _isar.writeTxn(() async {
      for (final data in serverEntries) {
        final serverId = data['id'] as String?;
        if (serverId == null) continue;

        // Check if we already have this entry
        final existing = await _isar.stockLedgerEntitys
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();

        if (existing == null) {
          // New entry from server
          final entry = StockLedgerEntity.fromServer(data);
          await _isar.stockLedgerEntitys.put(entry);
        } else if (existing.syncStatus == LedgerSyncStatus.synced) {
          // Only update if local is synced (no local changes)
          final updated = StockLedgerEntity.fromServer(data);
          updated.id = existing.id;
          await _isar.stockLedgerEntitys.put(updated);
        }
        // If local has changes (NEW, DELETED), don't overwrite
      }
    });

    debugPrint('[LedgerOffline] Imported ${serverEntries.length} ledger entries from server');
    notifyListeners();
  }

  /// Hard delete a ledger entry (after server confirms deletion)
  Future<void> permanentlyDelete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.delete(id);
    });
    debugPrint('[LedgerOffline] Entry permanently deleted: $id');
    notifyListeners();
  }

  // ==================== STATISTICS ====================

  /// Get total transaction count
  Future<int> getTotalCount() async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .count();
  }

  /// Get total inflow quantity for a product
  Future<double> getTotalInflowForProduct(String productId) async {
    final entries = await _isar.stockLedgerEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .findAll();

    return entries
        .where((e) => e.isInflow)
        .fold<double>(0.0, (sum, e) => sum + e.quantity.abs());
  }

  /// Get total outflow quantity for a product
  Future<double> getTotalOutflowForProduct(String productId) async {
    final entries = await _isar.stockLedgerEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .findAll();

    return entries
        .where((e) => e.isOutflow)
        .fold<double>(0.0, (sum, e) => sum + e.quantity.abs());
  }

  /// Clear all local ledger entries (use with caution)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.clear();
    });
    debugPrint('[LedgerOffline] All ledger entries cleared');
    notifyListeners();
  }
}
