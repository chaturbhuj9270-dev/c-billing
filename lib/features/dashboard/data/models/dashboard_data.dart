import 'package:equatable/equatable.dart';

/// Model class for dashboard data
class DashboardData extends Equatable {
  final int invoicesCount;
  final int clientsCount;
  final int productsCount;
  final int suppliersCount;
  final int purchasesCount;
  final int companiesCount;
  final int inventoryCount;
  final double totalSales;
  final int totalBillsCount;
  final int totalItemsSold;
  final double totalReturns;
  final int totalReturnedItems;
  final double netSales;
  final double totalPurchases;
  final int purchaseOrders;
  final int purchaseQty;
  final double profit;
  final double profitPercentage;
  final double stockValue;
  final int lowStockCount;
  final double totalPendingAmount;

  const DashboardData({
    this.invoicesCount = 0,
    this.clientsCount = 0,
    this.productsCount = 0,
    this.suppliersCount = 0,
    this.purchasesCount = 0,
    this.companiesCount = 0,
    this.inventoryCount = 0,
    this.totalSales = 0,
    this.totalBillsCount = 0,
    this.totalItemsSold = 0,
    this.totalReturns = 0,
    this.totalReturnedItems = 0,
    this.netSales = 0,
    this.totalPurchases = 0,
    this.purchaseOrders = 0,
    this.purchaseQty = 0,
    this.profit = 0,
    this.profitPercentage = 0,
    this.stockValue = 0,
    this.lowStockCount = 0,
    this.totalPendingAmount = 0,
  });

  /// Empty dashboard data
  static const empty = DashboardData();

  DashboardData copyWith({
    int? invoicesCount,
    int? clientsCount,
    int? productsCount,
    int? suppliersCount,
    int? purchasesCount,
    int? companiesCount,
    int? inventoryCount,
    double? totalSales,
    int? totalBillsCount,
    int? totalItemsSold,
    double? totalReturns,
    int? totalReturnedItems,
    double? netSales,
    double? totalPurchases,
    int? purchaseOrders,
    int? purchaseQty,
    double? profit,
    double? profitPercentage,
    double? stockValue,
    int? lowStockCount,
    double? totalPendingAmount,
  }) {
    return DashboardData(
      invoicesCount: invoicesCount ?? this.invoicesCount,
      clientsCount: clientsCount ?? this.clientsCount,
      productsCount: productsCount ?? this.productsCount,
      suppliersCount: suppliersCount ?? this.suppliersCount,
      purchasesCount: purchasesCount ?? this.purchasesCount,
      companiesCount: companiesCount ?? this.companiesCount,
      inventoryCount: inventoryCount ?? this.inventoryCount,
      totalSales: totalSales ?? this.totalSales,
      totalBillsCount: totalBillsCount ?? this.totalBillsCount,
      totalItemsSold: totalItemsSold ?? this.totalItemsSold,
      totalReturns: totalReturns ?? this.totalReturns,
      totalReturnedItems: totalReturnedItems ?? this.totalReturnedItems,
      netSales: netSales ?? this.netSales,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      purchaseQty: purchaseQty ?? this.purchaseQty,
      profit: profit ?? this.profit,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      stockValue: stockValue ?? this.stockValue,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      totalPendingAmount: totalPendingAmount ?? this.totalPendingAmount,
    );
  }

  @override
  List<Object?> get props => [
    invoicesCount,
    clientsCount,
    productsCount,
    suppliersCount,
    purchasesCount,
    companiesCount,
    inventoryCount,
    totalSales,
    totalBillsCount,
    totalItemsSold,
    totalReturns,
    totalReturnedItems,
    netSales,
    totalPurchases,
    purchaseOrders,
    purchaseQty,
    profit,
    profitPercentage,
    stockValue,
    lowStockCount,
    totalPendingAmount,
  ];
}
