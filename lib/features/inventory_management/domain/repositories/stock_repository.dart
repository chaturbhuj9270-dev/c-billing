import '../entities/stock.dart';

abstract class StockRepository {
  // Create
  Future<String> createStockEntry(Stock stock);

  // Read
  Future<Stock?> getStockById(String id);
  Future<List<Stock>> getStockByProductId(String productId);
  Future<List<Stock>> getAllStockEntries();

  // Query
  Future<int> getCurrentBalance(String productId);
  Future<List<Stock>> getStockByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Stock>> getStockByReferenceType(String referenceType);
}
