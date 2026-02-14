import '../entities/stock_ledger.dart';

/// Repository interface for Stock Ledger operations
abstract class StockLedgerRepository {
  // ==================== CREATE ====================
  
  /// Create a ledger entry
  Future<String> createLedgerEntry(StockLedger entry);
  
  /// Create multiple ledger entries in a batch
  Future<List<String>> createLedgerEntries(List<StockLedger> entries);

  // ==================== READ ====================
  
  /// Get ledger entry by ID
  Future<StockLedger?> getLedgerById(String ledgerId);
  
  /// Get all ledger entries
  Future<List<StockLedger>> getAllLedgerEntries();
  
  /// Get ledger entries by product ID
  Future<List<StockLedger>> getLedgerByProductId(String productId);
  
  /// Get ledger entries by product unique key
  Future<List<StockLedger>> getLedgerByProductUniqueKey(String productUniqueKey);
  
  /// Get ledger entries by batch ID
  Future<List<StockLedger>> getLedgerByBatchId(String batchId);
  
  /// Get ledger entries by reference ID (bill ID, purchase ID, etc.)
  Future<List<StockLedger>> getLedgerByReferenceId(String referenceId);
  
  /// Get ledger entries by type
  Future<List<StockLedger>> getLedgerByType(LedgerType type);
  
  /// Get ledger entries by date range
  Future<List<StockLedger>> getLedgerByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get recent ledger entries
  Future<List<StockLedger>> getRecentLedgerEntries({int limit = 50});

  // ==================== QUERY / AGGREGATIONS ====================
  
  /// Get total COGS (Cost of Goods Sold) for a date range
  Future<double> getTotalCOGS({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get COGS by product for a date range
  Future<Map<String, double>> getCOGSByProduct({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get total profit for a date range
  Future<double> getTotalProfit({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get profit by product for a date range
  Future<Map<String, double>> getProfitByProduct({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get total sales revenue for a date range
  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get total purchase value for a date range
  Future<double> getTotalPurchaseValue({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get current stock balance for a product
  Future<int> getCurrentBalance(String productId);
  
  /// Get current stock value for a product
  Future<double> getCurrentStockValue(String productId);
  
  /// Get stock movement summary for a product
  Future<Map<String, dynamic>> getStockMovementSummary(
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  // ==================== REPORTING ====================
  
  /// Get inventory valuation report
  Future<List<Map<String, dynamic>>> getInventoryValuationReport();
  
  /// Get stock movement report
  Future<List<Map<String, dynamic>>> getStockMovementReport({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
  });
  
  /// Get COGS report
  Future<List<Map<String, dynamic>>> getCOGSReport({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get profit report by product
  Future<List<Map<String, dynamic>>> getProfitReport({
    DateTime? startDate,
    DateTime? endDate,
  });
}
