import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../entities/stock_ledger_entity.dart';

/// Offline-first controller for Stock Ledger CRUD operations
/// Tracks all inventory movements for COGS calculation and audit trail
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

  /// Record a purchase transaction
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

    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.put(entry);
    });

    debugPrint('[LedgerOffline] Purchase recorded: ${entry.id}, product: ${entry.productName}, qty: $quantity');
    notifyListeners();
    return entry;
  }

  /// Record a sale transaction
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

    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.put(entry);
    });

    debugPrint('[LedgerOffline] Sale recorded: ${entry.id}, product: ${entry.productName}, qty: $quantity, profit: ${entry.profit}');
    notifyListeners();
    return entry;
  }

  /// Record a sale return transaction
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

    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.put(entry);
    });

    debugPrint('[LedgerOffline] Sale return recorded: ${entry.id}, product: ${entry.productName}, qty: $quantity');
    notifyListeners();
    return entry;
  }

  /// Record multiple ledger entries in a single transaction
  Future<List<StockLedgerEntity>> recordMultipleEntries(List<StockLedgerEntity> entries) async {
    await _isar.writeTxn(() async {
      for (final entry in entries) {
        await _isar.stockLedgerEntitys.put(entry);
      }
    });

    debugPrint('[LedgerOffline] Recorded ${entries.length} ledger entries');
    notifyListeners();
    return entries;
  }

  // ==================== READ ====================

  /// Get all ledger entries (excluding deleted)
  Future<List<StockLedgerEntity>> getAllLedgerEntries() async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Watch all ledger entries for real-time updates
  Stream<List<StockLedgerEntity>> watchAllLedgerEntries() {
    return _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .watch(fireImmediately: true);
  }

  /// Get ledger entry by local Isar ID
  Future<StockLedgerEntity?> getLedgerById(Id id) async {
    return await _isar.stockLedgerEntitys.get(id);
  }

  /// Get ledger entry by server ID
  Future<StockLedgerEntity?> getLedgerByServerId(String serverId) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }

  /// Get ledger entries by product ID
  Future<List<StockLedgerEntity>> getLedgerByProductId(String productId) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .productIdEqualTo(productId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get ledger entries by product unique key
  Future<List<StockLedgerEntity>> getLedgerByProductUniqueKey(String productUniqueKey) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .productUniqueKeyEqualTo(productUniqueKey)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get ledger entries by batch ID
  Future<List<StockLedgerEntity>> getLedgerByBatchId(String batchId) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .batchIdEqualTo(batchId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get ledger entries by reference ID (bill ID, purchase ID, etc.)
  Future<List<StockLedgerEntity>> getLedgerByReferenceId(String referenceId) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .referenceIdEqualTo(referenceId)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get ledger entries by type
  Future<List<StockLedgerEntity>> getLedgerByType(LedgerTransactionType type) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .ledgerTypeEqualTo(type)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get ledger entries by date range
  Future<List<StockLedgerEntity>> getLedgerByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .transactionDateBetween(startDate, endDate)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get recent ledger entries
  Future<List<StockLedgerEntity>> getRecentLedgerEntries({int limit = 50}) async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted)
        .sortByTransactionDateDesc()
        .limit(limit)
        .findAll();
  }

  // ==================== QUERY / AGGREGATIONS ====================

  /// Get total COGS (Cost of Goods Sold) for a date range
  Future<double> getTotalCOGS({DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .ledgerTypeEqualTo(LedgerTransactionType.SALE)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.transactionDateBetween(startDate, endDate);
    }
    
    final entries = await query.findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + e.totalCost);
  }

  /// Get COGS by product for a date range
  Future<Map<String, double>> getCOGSByProduct({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .ledgerTypeEqualTo(LedgerTransactionType.SALE)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.transactionDateBetween(startDate, endDate);
    }
    
    final entries = await query.findAll();
    final cogsMap = <String, double>{};
    
    for (final entry in entries) {
      final current = cogsMap[entry.productId] ?? 0.0;
      cogsMap[entry.productId] = current + entry.totalCost;
    }
    
    return cogsMap;
  }

  /// Get total profit for a date range
  Future<double> getTotalProfit({DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .group((q) => q
            .ledgerTypeEqualTo(LedgerTransactionType.SALE)
            .or()
            .ledgerTypeEqualTo(LedgerTransactionType.SALE_RETURN))
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.transactionDateBetween(startDate, endDate);
    }
    
    final entries = await query.findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + e.profit);
  }

  /// Get profit by product for a date range
  Future<Map<String, double>> getProfitByProduct({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .group((q) => q
            .ledgerTypeEqualTo(LedgerTransactionType.SALE)
            .or()
            .ledgerTypeEqualTo(LedgerTransactionType.SALE_RETURN))
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.transactionDateBetween(startDate, endDate);
    }
    
    final entries = await query.findAll();
    final profitMap = <String, double>{};
    
    for (final entry in entries) {
      final current = profitMap[entry.productId] ?? 0.0;
      profitMap[entry.productId] = current + entry.profit;
    }
    
    return profitMap;
  }

  /// Get total sales revenue for a date range
  Future<double> getTotalRevenue({DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .ledgerTypeEqualTo(LedgerTransactionType.SALE)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.transactionDateBetween(startDate, endDate);
    }
    
    final entries = await query.findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + e.totalRevenue);
  }

  /// Get total purchase value for a date range
  Future<double> getTotalPurchaseValue({DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.stockLedgerEntitys
        .filter()
        .ledgerTypeEqualTo(LedgerTransactionType.PURCHASE)
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.deleted);
    
    if (startDate != null && endDate != null) {
      query = query.transactionDateBetween(startDate, endDate);
    }
    
    final entries = await query.findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + e.totalCost);
  }

  /// Get stock movement summary for a product
  Future<Map<String, dynamic>> getStockMovementSummary(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await getLedgerByProductId(productId);
    
    final filteredEntries = entries.where((e) {
      if (startDate != null && e.transactionDate.isBefore(startDate)) return false;
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

  /// Get ledger entries that need to be synced
  Future<List<StockLedgerEntity>> getLedgerNeedingSync() async {
    return await _isar.stockLedgerEntitys
        .filter()
        .not()
        .syncStatusEqualTo(LedgerSyncStatus.synced)
        .findAll();
  }

  /// Mark ledger entry as synced
  Future<void> markAsSynced(Id id, String serverId) async {
    final existing = await _isar.stockLedgerEntitys.get(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      serverId: serverId,
      syncStatus: LedgerSyncStatus.synced,
    );

    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.put(updated);
    });
    
    debugPrint('[LedgerOffline] Entry marked as synced: $id -> $serverId');
  }

  /// Import ledger entries from server
  Future<void> importFromServer(List<Map<String, dynamic>> serverEntries) async {
    await _isar.writeTxn(() async {
      for (final data in serverEntries) {
        final entity = StockLedgerEntity.fromServer(data);
        
        // Check if entry already exists locally
        final existing = await _isar.stockLedgerEntitys
            .filter()
            .serverIdEqualTo(entity.serverId)
            .findFirst();
        
        if (existing != null) {
          // Update existing if server version is newer
          if (entity.createdAt.isAfter(existing.createdAt)) {
            entity.id = existing.id;
            await _isar.stockLedgerEntitys.put(entity);
          }
        } else {
          await _isar.stockLedgerEntitys.put(entity);
        }
      }
    });
    
    debugPrint('[LedgerOffline] Imported ${serverEntries.length} ledger entries from server');
    notifyListeners();
  }

  /// Clear all local ledger entries (for testing or logout)
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.stockLedgerEntitys.clear();
    });
    debugPrint('[LedgerOffline] All ledger entries cleared');
    notifyListeners();
  }
}
