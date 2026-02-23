import 'package:equatable/equatable.dart';

/// Domain entity representing dashboard summary data
/// This is the core business model for dashboard metrics
/// 
/// Key formulas:
///   Net Sales = Total Sales (finalAmount) - Total Returns
///   Profit = Net Sales - Purchase Cost of sold (non-returned) items
///   Stock Value = Sum of (batch.quantityRemaining × batch.purchasePrice) for all unconsumed batches
class DashboardSummary extends Equatable {
  final int invoicesCount;
  final int clientsCount;
  final int productsCount;
  final int suppliersCount;
  final int purchasesCount;
  final int companiesCount;
  
  /// Gross sales amount (sum of finalAmount from all bills in period)
  final double totalSales;
  final int totalBillsCount;
  final int totalItemsSold;
  
  /// Total returned amount (returnedQty × sellingPrice, proportional discount applied)
  final double totalReturns;
  
  /// Total returned item count
  final int totalReturnedItems;
  
  /// Net Sales = totalSales - totalReturns
  final double netSales;
  
  final double totalPurchases;
  final int purchaseOrders;
  final int purchaseQty;
  
  /// Profit = Net Sales - Purchase Cost of sold (non-returned) items
  final double profit;
  final double profitPercentage;
  
  /// Stock value computed from batch quantityRemaining × purchasePrice
  final double stockValue;
  final int lowStockCount;
  
  /// Total pending amount across all bills (unpaid / partially paid)
  final double totalPendingAmount;
  
  // Event/Order tracking fields
  /// Total count of all events and orders
  final int totalEventOrders;
  /// Count of upcoming events (event date in future)
  final int upcomingEvents;
  /// Count of pending orders (not delivered/cancelled)
  final int pendingOrders;
  /// Total amount from all events/orders
  final double eventOrdersAmount;
  /// Total advance collected
  final double eventOrdersAdvance;
  /// Total pending/remaining amount
  final double eventOrdersPending;
  
  final DateTime lastUpdated;
  final bool isFromCache;

  const DashboardSummary({
    this.invoicesCount = 0,
    this.clientsCount = 0,
    this.productsCount = 0,
    this.suppliersCount = 0,
    this.purchasesCount = 0,
    this.companiesCount = 0,
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
    this.totalEventOrders = 0,
    this.upcomingEvents = 0,
    this.pendingOrders = 0,
    this.eventOrdersAmount = 0,
    this.eventOrdersAdvance = 0,
    this.eventOrdersPending = 0,
    required this.lastUpdated,
    this.isFromCache = false,
  });

  /// Empty dashboard summary for initial state
  static DashboardSummary get empty => DashboardSummary(
        lastUpdated: DateTime.now(),
        isFromCache: false,
      );

  /// Check if data is stale (older than threshold)
  bool isStale({Duration threshold = const Duration(minutes: 5)}) {
    return DateTime.now().difference(lastUpdated) > threshold;
  }

  DashboardSummary copyWith({
    int? invoicesCount,
    int? clientsCount,
    int? productsCount,
    int? suppliersCount,
    int? purchasesCount,
    int? companiesCount,
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
    int? totalEventOrders,
    int? upcomingEvents,
    int? pendingOrders,
    double? eventOrdersAmount,
    double? eventOrdersAdvance,
    double? eventOrdersPending,
    DateTime? lastUpdated,
    bool? isFromCache,
  }) {
    return DashboardSummary(
      invoicesCount: invoicesCount ?? this.invoicesCount,
      clientsCount: clientsCount ?? this.clientsCount,
      productsCount: productsCount ?? this.productsCount,
      suppliersCount: suppliersCount ?? this.suppliersCount,
      purchasesCount: purchasesCount ?? this.purchasesCount,
      companiesCount: companiesCount ?? this.companiesCount,
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
      totalEventOrders: totalEventOrders ?? this.totalEventOrders,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      eventOrdersAmount: eventOrdersAmount ?? this.eventOrdersAmount,
      eventOrdersAdvance: eventOrdersAdvance ?? this.eventOrdersAdvance,
      eventOrdersPending: eventOrdersPending ?? this.eventOrdersPending,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'invoicesCount': invoicesCount,
      'clientsCount': clientsCount,
      'productsCount': productsCount,
      'suppliersCount': suppliersCount,
      'purchasesCount': purchasesCount,
      'companiesCount': companiesCount,
      'totalSales': totalSales,
      'totalBillsCount': totalBillsCount,
      'totalItemsSold': totalItemsSold,
      'totalReturns': totalReturns,
      'totalReturnedItems': totalReturnedItems,
      'netSales': netSales,
      'totalPurchases': totalPurchases,
      'purchaseOrders': purchaseOrders,
      'purchaseQty': purchaseQty,
      'profit': profit,
      'profitPercentage': profitPercentage,
      'stockValue': stockValue,
      'lowStockCount': lowStockCount,
      'totalPendingAmount': totalPendingAmount,
      'totalEventOrders': totalEventOrders,
      'upcomingEvents': upcomingEvents,
      'pendingOrders': pendingOrders,
      'eventOrdersAmount': eventOrdersAmount,
      'eventOrdersAdvance': eventOrdersAdvance,
      'eventOrdersPending': eventOrdersPending,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      invoicesCount: json['invoicesCount'] as int? ?? 0,
      clientsCount: json['clientsCount'] as int? ?? 0,
      productsCount: json['productsCount'] as int? ?? 0,
      suppliersCount: json['suppliersCount'] as int? ?? 0,
      purchasesCount: json['purchasesCount'] as int? ?? 0,
      companiesCount: json['companiesCount'] as int? ?? 0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalBillsCount: json['totalBillsCount'] as int? ?? 0,
      totalItemsSold: json['totalItemsSold'] as int? ?? 0,
      totalReturns: (json['totalReturns'] as num?)?.toDouble() ?? 0,
      totalReturnedItems: json['totalReturnedItems'] as int? ?? 0,
      netSales: (json['netSales'] as num?)?.toDouble() ?? 0,
      totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0,
      purchaseOrders: json['purchaseOrders'] as int? ?? 0,
      purchaseQty: json['purchaseQty'] as int? ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      profitPercentage: (json['profitPercentage'] as num?)?.toDouble() ?? 0,
      stockValue: (json['stockValue'] as num?)?.toDouble() ?? 0,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
      totalPendingAmount: (json['totalPendingAmount'] as num?)?.toDouble() ?? 0,
      totalEventOrders: json['totalEventOrders'] as int? ?? 0,
      upcomingEvents: json['upcomingEvents'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      eventOrdersAmount: (json['eventOrdersAmount'] as num?)?.toDouble() ?? 0,
      eventOrdersAdvance: (json['eventOrdersAdvance'] as num?)?.toDouble() ?? 0,
      eventOrdersPending: (json['eventOrdersPending'] as num?)?.toDouble() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      isFromCache: true,
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
        totalEventOrders,
        upcomingEvents,
        pendingOrders,
        eventOrdersAmount,
        eventOrdersAdvance,
        eventOrdersPending,
        lastUpdated,
        isFromCache,
      ];
}
