import '../entities/purchase.dart';

abstract class PurchaseRepository {
  // Create
  Future<String> addPurchase(Purchase purchase);

  // Read
  Future<Purchase?> getPurchaseById(String id);
  Future<List<Purchase>> getAllPurchases();
  Future<List<Purchase>> getPurchasesByProductId(String productId);

  // Query
  Future<List<Purchase>> getPurchasesByDateRange(DateTime startDate, DateTime endDate);
  Future<double> getTotalPurchaseAmount({DateTime? startDate, DateTime? endDate});
  Future<int> getTotalPurchaseQuantity({DateTime? startDate, DateTime? endDate});
}
