import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/services/local_database.dart';
import '../entities/stock_ledger_entity.dart';

// Offline-first controller for Stock Ledger CRUD operations Tracks all inventory movements for COGS calculation and audit trail
class StockLedgerOfflineController extends ChangeNotifier {
  static StockLedgerOfflineController? _instance;

  final AppDatabase _db;

  StockLedgerOfflineController._(this._db);

  // Get the singleton instance
  static StockLedgerOfflineController get instance {
    _instance ??= StockLedgerOfflineController._(LocalDatabase.instance.db);
    return _instance!;
  }

  // Reset instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // ==================== CREATE ====================

  // Record a purchase transaction
  Future<StockLedgerEntity> recordPurchase({
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required String purchaseReferenceId,
    required int quantity,
    required double costPrice,
    required int balanceQuantity,
    required double balanceValue,
    String? notes,
  }) async {
    final entry = StockLedgerEntity.forPurchase(
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      batchId: batchId,
      localBatchId: localBatchId,
      purchaseReferenceId: purchaseReferenceId,
      quantity: quantity,
      costPrice: costPrice,
      balanceQuantity: balanceQuantity,
      balanceValue: balanceValue,
      notes: notes,
    );

    await _db.saveLedger(entry);

    debugPrint(
      '[LedgerOffline] Purchase recorded: ${entry.id}, product: ${entry.productName}, qty: $quantity',
    );
    notifyListeners();
    return entry;
  }

  // Record a sale transaction
  Future<StockLedgerEntity> recordSale({
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required String billId,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
    required int balanceQuantity,
    required double balanceValue,
    String? notes,
  }) async {
    final entry = StockLedgerEntity.forSale(
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      batchId: batchId,
      localBatchId: localBatchId,
      billId: billId,
      quantity: quantity,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      balanceQuantity: balanceQuantity,
      balanceValue: balanceValue,
      notes: notes,
    );

    await _db.saveLedger(entry);

    debugPrint(
      '[LedgerOffline] Sale recorded: ${entry.id}, product: ${entry.productName}, qty: $quantity, profit: ${entry.profit}',
    );
    notifyListeners();
    return entry;
  }

  // Record a sale return transaction
  Future<StockLedgerEntity> recordSaleReturn({
    required String productId,
    required String productName,
    String companyName = '',
    String modelName = '',
    required String batchId,
    int? localBatchId,
    required String returnReferenceId,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
    required int balanceQuantity,
    required double balanceValue,
    String? notes,
  }) async {
    final entry = StockLedgerEntity.forSaleReturn(
      productId: productId,
      productName: productName,
      companyName: companyName,
      modelName: modelName,
      batchId: batchId,
      localBatchId: localBatchId,
      returnReferenceId: returnReferenceId,
      quantity: quantity,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      balanceQuantity: balanceQuantity,
      balanceValue: balanceValue,
      notes: notes,
    );

    await _db.saveLedger(entry);

    debugPrint(
      '[LedgerOffline] Sale return recorded: ${entry.id}, product: ${entry.productName}, qty: $quantity',
    );
    notifyListeners();
    return entry;
  }

  // Record multiple ledger entries in a single transaction
  Future<List<StockLedgerEntity>> recordMultipleEntries(
    List<StockLedgerEntity> entries,
  ) async {
    await _db.transaction(() async {
      for (final entry in entries) {
        await _db.saveLedger(entry);
      }
    });

    debugPrint('[LedgerOffline] Recorded ${entries.length} ledger entries');
    notifyListeners();
    return entries;
  }

  // ==================== READ ====================

  // Get all ledger entries (excluding deleted)
  Future<List<StockLedgerEntity>> getAllLedgerEntries() async {
    final entries = (await _db.loadLedger())
        .where((entry) => entry.syncStatus != LedgerSyncStatus.deleted)
        .toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Watch all ledger entries for real-time updates
  Stream<List<StockLedgerEntity>> watchAllLedgerEntries() {
    return _db.watchLedger().map((rows) {
      final entries = rows
          .where((entry) => entry.syncStatus != LedgerSyncStatus.deleted)
          .toList();
      entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return entries;
    });
  }

  Future<StockLedgerEntity?> getLedgerById(int id) async {
    for (final entry in await _db.loadLedger()) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  // Get ledger entry by server ID
  Future<StockLedgerEntity?> getLedgerByServerId(String serverId) async {
    for (final entry in await _db.loadLedger()) {
      if (entry.serverId == serverId) return entry;
    }
    return null;
  }

  // Get ledger entries by product ID
  Future<List<StockLedgerEntity>> getLedgerByProductId(String productId) async {
    final entries = (await _db.loadLedger()).where((entry) {
      return entry.productId == productId &&
          entry.syncStatus != LedgerSyncStatus.deleted;
    }).toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Get ledger entries by product unique key
  Future<List<StockLedgerEntity>> getLedgerByProductUniqueKey(
    String productUniqueKey,
  ) async {
    final entries = (await _db.loadLedger()).where((entry) {
      return entry.productUniqueKey == productUniqueKey &&
          entry.syncStatus != LedgerSyncStatus.deleted;
    }).toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Get ledger entries by batch ID
  Future<List<StockLedgerEntity>> getLedgerByBatchId(String batchId) async {
    final entries = (await _db.loadLedger()).where((entry) {
      return entry.batchId == batchId &&
          entry.syncStatus != LedgerSyncStatus.deleted;
    }).toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Get ledger entries by reference ID (bill ID, purchase ID, etc.)
  Future<List<StockLedgerEntity>> getLedgerByReferenceId(
    String referenceId,
  ) async {
    final entries = (await _db.loadLedger()).where((entry) {
      return entry.referenceId == referenceId &&
          entry.syncStatus != LedgerSyncStatus.deleted;
    }).toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Get ledger entries by type
  Future<List<StockLedgerEntity>> getLedgerByType(
    LedgerTransactionType type,
  ) async {
    final entries = (await _db.loadLedger()).where((entry) {
      return entry.ledgerType == type &&
          entry.syncStatus != LedgerSyncStatus.deleted;
    }).toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Get ledger entries by date range
  Future<List<StockLedgerEntity>> getLedgerByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = (await _db.loadLedger()).where((entry) {
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      return !entry.transactionDate.isBefore(startDate) &&
          !entry.transactionDate.isAfter(endDate);
    }).toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries;
  }

  // Get recent ledger entries
  Future<List<StockLedgerEntity>> getRecentLedgerEntries({
    int limit = 50,
  }) async {
    final entries = (await _db.loadLedger())
        .where((entry) => entry.syncStatus != LedgerSyncStatus.deleted)
        .toList();
    entries.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return entries.take(limit).toList();
  }

  // ==================== QUERY / AGGREGATIONS ====================

  // Get total COGS (Cost of Goods Sold) for a date range
  Future<double> getTotalCOGS({DateTime? startDate, DateTime? endDate}) async {
    final entries = (await _db.loadLedger()).where((entry) {
      if (entry.ledgerType != LedgerTransactionType.SALE) return false;
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !entry.transactionDate.isBefore(startDate) &&
            !entry.transactionDate.isAfter(endDate);
      }
      return true;
    });

    return entries.fold<double>(0.0, (total, e) => total + e.totalCost);
  }

  // Get COGS by product for a date range
  Future<Map<String, double>> getCOGSByProduct({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = (await _db.loadLedger()).where((entry) {
      if (entry.ledgerType != LedgerTransactionType.SALE) return false;
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !entry.transactionDate.isBefore(startDate) &&
            !entry.transactionDate.isAfter(endDate);
      }
      return true;
    });

    final cogsMap = <String, double>{};

    for (final entry in entries) {
      final current = cogsMap[entry.productId] ?? 0.0;
      cogsMap[entry.productId] = current + entry.totalCost;
    }

    return cogsMap;
  }

  // Get total profit for a date range
  Future<double> getTotalProfit({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = (await _db.loadLedger()).where((entry) {
      final isSaleOrReturn =
          entry.ledgerType == LedgerTransactionType.SALE ||
          entry.ledgerType == LedgerTransactionType.SALE_RETURN;
      if (!isSaleOrReturn) return false;
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !entry.transactionDate.isBefore(startDate) &&
            !entry.transactionDate.isAfter(endDate);
      }
      return true;
    });

    return entries.fold<double>(0.0, (total, e) => total + e.profit);
  }

  // Get profit by product for a date range
  Future<Map<String, double>> getProfitByProduct({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = (await _db.loadLedger()).where((entry) {
      final isSaleOrReturn =
          entry.ledgerType == LedgerTransactionType.SALE ||
          entry.ledgerType == LedgerTransactionType.SALE_RETURN;
      if (!isSaleOrReturn) return false;
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !entry.transactionDate.isBefore(startDate) &&
            !entry.transactionDate.isAfter(endDate);
      }
      return true;
    });

    final profitMap = <String, double>{};

    for (final entry in entries) {
      final current = profitMap[entry.productId] ?? 0.0;
      profitMap[entry.productId] = current + entry.profit;
    }

    return profitMap;
  }

  // Get total sales revenue for a date range
  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = (await _db.loadLedger()).where((entry) {
      if (entry.ledgerType != LedgerTransactionType.SALE) return false;
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !entry.transactionDate.isBefore(startDate) &&
            !entry.transactionDate.isAfter(endDate);
      }
      return true;
    });

    return entries.fold<double>(0.0, (total, e) => total + e.totalRevenue);
  }

  // Get total purchase value for a date range
  Future<double> getTotalPurchaseValue({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = (await _db.loadLedger()).where((entry) {
      if (entry.ledgerType != LedgerTransactionType.PURCHASE) return false;
      if (entry.syncStatus == LedgerSyncStatus.deleted) return false;
      if (startDate != null && endDate != null) {
        return !entry.transactionDate.isBefore(startDate) &&
            !entry.transactionDate.isAfter(endDate);
      }
      return true;
    });

    return entries.fold<double>(0.0, (total, e) => total + e.totalCost);
  }

  // Get stock movement summary for a product
  Future<Map<String, dynamic>> getStockMovementSummary(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await getLedgerByProductId(productId);

    final filteredEntries = entries.where((e) {
      if (startDate != null && e.transactionDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && e.transactionDate.isAfter(endDate)) return false;
      return true;
    }).toList();

    int totalIn = 0;
    int totalOut = 0;
    double totalPurchaseValue = 0.0;
    double totalSalesValue = 0.0;
    double totalCOGS = 0.0;
    double totalProfit = 0.0;

    for (final entry in filteredEntries) {
      if (entry.isInbound) {
        totalIn += entry.quantity;
        if (entry.ledgerType == LedgerTransactionType.PURCHASE) {
          totalPurchaseValue += entry.totalCost;
        }
      } else if (entry.isOutbound) {
        totalOut += entry.quantity;
        if (entry.ledgerType == LedgerTransactionType.SALE) {
          totalSalesValue += entry.totalRevenue;
          totalCOGS += entry.totalCost;
          totalProfit += entry.profit;
        }
      }
    }

    return {
      'productId': productId,
      'totalIn': totalIn,
      'totalOut': totalOut,
      'netMovement': totalIn - totalOut,
      'totalPurchaseValue': totalPurchaseValue,
      'totalSalesValue': totalSalesValue,
      'totalCOGS': totalCOGS,
      'totalProfit': totalProfit,
      'transactionCount': filteredEntries.length,
    };
  }

  // ==================== SYNC HELPERS ====================

  // Get ledger entries that need to be synced
  Future<List<StockLedgerEntity>> getLedgerNeedingSync() async {
    return (await _db.loadLedger())
        .where((entry) => entry.syncStatus != LedgerSyncStatus.synced)
        .toList();
  }

  // Mark ledger entry as synced
  Future<void> markAsSynced(int id, String serverId) async {
    final existing = await getLedgerById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId,
      syncStatus: LedgerSyncStatus.synced,
    );

    await _db.saveLedger(updated);

    debugPrint('[LedgerOffline] Entry marked as synced: $id -> $serverId');
  }

  // Import ledger entries from server
  Future<void> importFromServer(
    List<Map<String, dynamic>> serverEntries,
  ) async {
    await _db.transaction(() async {
      for (final data in serverEntries) {
        final entity = StockLedgerEntity.fromServer(data);

        // Check if entry already exists locally
        final all = await _db.loadLedger();
        StockLedgerEntity? existing;
        for (final entry in all) {
          if (entry.serverId == entity.serverId) {
            existing = entry;
            break;
          }
        }

        if (existing != null) {
          // Update existing if server version is newer
          if (entity.createdAt.isAfter(existing.createdAt)) {
            entity.id = existing.id;
            await _db.saveLedger(entity);
          }
        } else {
          await _db.saveLedger(entity);
        }
      }
    });

    debugPrint(
      '[LedgerOffline] Imported ${serverEntries.length} ledger entries from server',
    );
    notifyListeners();
  }

  // Clear all local ledger entries (for testing or logout)
  Future<void> clearAll() async {
    await _db.clearLedger();
    debugPrint('[LedgerOffline] All ledger entries cleared');
    notifyListeners();
  }
}
