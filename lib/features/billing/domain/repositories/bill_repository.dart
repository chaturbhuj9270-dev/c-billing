import '../entities/bill.dart';

/// Abstract repository interface for Bill operations
abstract class BillRepository {
  /// Create a new bill
  Future<String> createBill(Bill bill);

  /// Get a bill by ID
  Future<Bill?> getBillById(String id);

  /// Get all bills
  Future<List<Bill>> getAllBills();

  /// Get bills by customer ID
  Future<List<Bill>> getBillsByCustomerId(String customerId);

  /// Get bills by date range
  Future<List<Bill>> getBillsByDateRange(DateTime startDate, DateTime endDate);

  /// Get today's bills
  Future<List<Bill>> getTodaysBills();

  /// Update a bill
  Future<void> updateBill(Bill bill);

  /// Delete a bill
  Future<void> deleteBill(String id);

  /// Get total sales amount for a date range
  Future<double> getTotalSalesAmount({DateTime? startDate, DateTime? endDate});

  /// Get total bills count for a date range
  Future<int> getTotalBillsCount({DateTime? startDate, DateTime? endDate});

  /// Search bills by customer name or contact
  Future<List<Bill>> searchBills(String query);
}
