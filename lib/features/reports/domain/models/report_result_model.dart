/// Result model for a single product row in the report
class ReportProductRow {
  final String productId;
  final String productName;
  final String companyName;
  final String supplierName;
  final int purchaseQty;
  final int soldQty;
  final int returnedQty; // sale returns + purchase returns combined
  final int saleReturnQty;
  final int purchaseReturnQty;
  final int currentStock;
  final double purchasePrice;
  final double sellingPrice;
  final double totalPurchaseAmount;
  final double totalSalesAmount;
  final double profitOrLoss;
  final DateTime? expiryDate;
  final bool isExpired;
  final bool isExpiringThisWeek;
  final bool isLowStock;

  const ReportProductRow({
    required this.productId,
    required this.productName,
    required this.companyName,
    required this.supplierName,
    required this.purchaseQty,
    required this.soldQty,
    required this.returnedQty,
    this.saleReturnQty = 0,
    this.purchaseReturnQty = 0,
    required this.currentStock,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.totalPurchaseAmount,
    required this.totalSalesAmount,
    required this.profitOrLoss,
    this.expiryDate,
    this.isExpired = false,
    this.isExpiringThisWeek = false,
    this.isLowStock = false,
  });
}

/// Complete report result with rows and summary
class ReportResultModel {
  final List<ReportProductRow> rows;

  /// Summary totals
  final double totalPurchaseAmount;
  final double totalSalesAmount;
  final double totalProfit;
  final double totalLoss;
  final double expiredStockValue;
  final double returnedStockValue;

  /// Counts
  final int totalProducts;
  final int expiredCount;
  final int expiringThisWeekCount;
  final int lowStockCount;
  final int returnedCount;

  /// Generation metadata
  final DateTime generatedAt;
  final String filterSummary;

  const ReportResultModel({
    required this.rows,
    required this.totalPurchaseAmount,
    required this.totalSalesAmount,
    required this.totalProfit,
    required this.totalLoss,
    required this.expiredStockValue,
    required this.returnedStockValue,
    required this.totalProducts,
    this.expiredCount = 0,
    this.expiringThisWeekCount = 0,
    this.lowStockCount = 0,
    this.returnedCount = 0,
    required this.generatedAt,
    required this.filterSummary,
  });

  /// Whether report has data
  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;

  /// Net profit (total profit - total loss)
  double get netProfit => totalProfit - totalLoss;
}
